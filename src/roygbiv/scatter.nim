import std/[algorithm, random, strformat]

import graph
import graphState
import tabu


randomize()

proc relinkPath(A, B: GraphState): seq[GraphState] =
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
  echo fmt"Relinking path length {pathLen}"

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
    
    if current.cost < min(A.cost, B.cost):
      echo "Keeping better offspring"
      result.add(current.copy())


proc replaceMostSimilar*(population: var seq[GraphState], entry: GraphState) =
  # Replaces the population element with cost <= entry.cost that is most similar
  # to the entry.
  var
    distance, minIndex: int
    minDistance = entry.graph.n

  for i, other in population:
    if entry.cost <= other.cost:
      distance = entry.distance(other)
      if distance < minDistance:
        minDistance = distance
        minIndex = i
  
  # Don't change the population if adding the entry isn't an improvement.
  if minDistance < entry.graph.n:
    echo fmt"Replacing entry {population[minIndex].cost} with {entry.cost} (distance: {minDistance})"
    population[minIndex] = entry


proc scatterSearch*(graph: Graph,
                    k: int,
                    populationSize: int,
                    iterations: int,
                    threshold: int): GraphState =
  # Performs scatter search to find a valid k-coloring of the graph.
  var
    population: seq[GraphState]
    improvements: seq[GraphState]
    currentThreshold = threshold

  # Begin by building a population of tabu refined assignment states.
  echo fmt"Building initial population"
  population = buildPopulation(graph, k, populationSize, currentThreshold)
  if population[0].cost == 0:
    return population[0]

  # On each iteration, we attempt to improve the population.
  for iter in 0..<iterations:
    improvements = @[]
    echo ""
    echo fmt"Scatter Search iteration {iter + 1} of {iterations}"
    # Visit each pair of candidate
    for i in 0..<population.len:
      for j in 0..<i:
        # The population are sorted by cost so that candidates[j].cost <= candidates[i].cost since j < i
        echo fmt"Relinking states of cost {population[i].cost} -> {population[j].cost}"
        # Sample the relink path between the two states, improving each.
        for entry in relinkPath(population[i], population[j]).batchImprove(currentThreshold):
          # Keep any of these improved states are better than both parents.
          if entry.cost < population[j].cost:
            if entry.cost == 0:
              echo "Found Solution"
              return entry
            echo fmt"Adding {entry.cost} to candidate pool"
            improvements.add(entry)
      
    # Update the population if improvements are found.
    # Otherwise we increase the tabu depth.
    if improvements.len > 0:
      # Each improvement replaces the pool element it is most similar to.
      for e in improvements:
        population.replaceMostSimilar(e)
    else:
      currentThreshold = (currentThreshold * 15) div 10
      echo fmt"Increased threshold to {currentThreshold}"

    population.sort(costCompare)

  result = population[0]
  echo fmt"Found {result.cost}"


when isMainModule:
  block: # random coloring of square 
    var graph = loadDIMACS("data/dimacs/dsjc125.1.col")

    var state1 = initGraphState(graph, 5)
    var improved1 = state1.tabuImprove(10)

    assert improved1.cost != 0

    var state2 = initGraphState(graph, 5)
    var improved2 = state2.tabuImprove(10)

    assert improved2.cost != 0

    discard improved1.relinkPath(improved2)
