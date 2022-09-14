import std/[algorithm, random, strformat]

import ../graph
import coloringState, tabu 


randomize()


proc relinkPath(A, B: ColoringState): seq[ColoringState] =
  # Returns a sample of the assignment states between A and B.
  doAssert A.k == B.k

  var
    bestMoves: seq[int]
    bestMoveCost: int
    moves: seq[(int, int)]

  var current = A.copy()

  # Record all moves (u, color) to transform A into B
  for u in current.graph.vertices:
    if current.color[u] != B.color[u]:
      moves.add((u, B.color[u]))
    
  let pathLen = moves.len

  while moves.len > 0:
    bestMoves = @[]
    bestMoveCost = high(int)

    for mi in 0..<moves.len:
      var (u, newColor) = moves[mi]
      var newCost = current.colorCost(u, newColor)

      if newCost < bestMoveCost:
        bestMoves = @[mi]
        bestMoveCost = newCost
      elif newCost == bestMoveCost:
        bestMoves.add(mi)

    let ri = sample(bestMoves)
    let (u, newColor) = moves[ri]
    current.setColor(u, newColor)
    moves.del(ri)

    if float(pathLen)*rand(1.0) <= 10.0:
      result.add(current.copy())


proc replaceMostSimilar*(population: var seq[ColoringState], entry: ColoringState) =
  # Replaces the population element with cost <= entry.cost that is most similar
  # to the entry.
  var
    distance, minIndex: int
    minDistance = entry.graph.numVertices

  for i, other in population:
    if entry.cost <= other.cost:
      distance = entry.distance(other)
      if distance < minDistance:
        minDistance = distance
        minIndex = i
  
  # Don't change the population if adding the entry isn't an improvement.
  if minDistance < entry.graph.numVertices:
    # echo fmt"Replacing entry {population[minIndex].cost} with {entry.cost} (distance: {minDistance})"
    population[minIndex] = entry


proc relinkPairs*(states: seq[ColoringState], tabuThreshold: int): seq[ColoringState] =
  for i in 0..<states.len:
    for j in 0..<i:
      # Sample the relink path between the two states, improving each.
      for entry in relinkPath(states[i], states[j]).batchImprove(tabuThreshold):
        # Keep any of these improved states are better than both parents.
        # echo fmt"Relink pair {states[i].cost} - {states[j].cost} -> {entry.cost}"
        if entry.cost < min(states[i].cost, states[j].cost):
          # echo fmt"Relink pair {states[i].cost} - {states[j].cost} -> {entry.cost}"
          result.add(entry)
          if entry.cost == 0:
            return result


proc populationDetails(states: seq[ColoringState]) =
  var costs: seq[int]
  for state in states:
    costs.add(state.cost)
  echo fmt"Population: {costs}"


proc scatterSearch*(graph: DenseGraph,
                    k: int,
                    populationSize: int,
                    iterations: int,
                    threshold: int): ColoringState =
  # Performs scatter search to find a valid k-coloring of the graph.
  var
    population: seq[ColoringState]
    improvements: seq[ColoringState]
    currentThreshold = threshold

  # Begin by building a population of tabu refined assignment states.
  echo fmt"Building initial population"
  population = buildPopulation(graph, k, populationSize, currentThreshold)
  if population[0].cost == 0:
    return population[0]

  # On each iteration, we attempt to improve the population.
  for iter in 0..<iterations:
    improvements = population.relinkPairs(currentThreshold)
      
    # Update the population if improvements are found.
    # Otherwise we increase the tabu depth.
    if improvements.len > 0:
      # Each improvement replaces the pool element it is most similar to.
      for e in improvements:
        population.replaceMostSimilar(e)
        if e.cost == 0:
          echo fmt"Found {e.cost}"
          return e
    else:
      currentThreshold += currentThreshold div 10
      echo fmt"Increased threshold to {currentThreshold}"

    population.sort(costCompare)
    populationDetails(population)

  result = population[0]
  echo fmt"Found {result.cost}"
