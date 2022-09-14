import std/[algorithm, random, strformat, threadpool, times]
import coloringState
import ../graph


randomize()


func bestMoves(state: ColoringState): seq[Move] {.inline.} =
  # Returns the best available moves for the state.
  var
    newCost: int
    bestMoveCost = high(int)

  for u in state.graph.vertices:
    # If u is already a different color than each of its neighbors, don't change u.
    if state.numAdjacent[u][state.color[u]] == 0:
      continue

    # Otherwise, determine the cost of changing u to each possible color.
    for newColor in 0..<state.k:
      newCost = state.colorCost(u, newColor)

      # Only consider this new color if the move is not tabu, or if the new
      # assignment cost is the best seen so far.
      if state.tabu[u][newColor] <= state.iteration or newCost < state.bestCost:
        if newCost < bestMoveCost:
          bestMoveCost = newCost
          result = @[(u, newColor)]
        elif newCost == bestMoveCost:
          result.add((u, newColor))


proc applyBestMove(state: ColoringState) {.inline.} =
  # Applies a randomly chosen best greedy move to the state, mutating state.
  var moves = state.bestMoves()
  if moves.len > 0:
    let (u, newColor) = sample(moves)
    state.setColor(u, newColor, markTabu = true)
  state.iteration += 1


proc tabuImprove*(state: ColoringState, threshold: int, verbose: bool = false): ColoringState =
  var
    current = state.copy()
    bestSoFar = current.cost
    lastImprovement = 0
    then = epochTime()
    blockSize = 10000
    now, rate: float

  while current.cost > 0 and current.iteration - lastImprovement < threshold:
    current.applyBestMove()
    if verbose and current.iteration > 0 and current.iteration mod blockSize == 0:
      now = epochTime()
      rate = float(blockSize) / (now - then)
      then = now
      echo fmt"Iteration: {current.iteration}  Current: {current.cost}  Best: {current.bestCost}  Rate: {rate:.3f} it/sec"

    if current.cost < bestSoFar:
      lastImprovement = current.iteration
      bestSoFar = current.cost
    
  current.loadBest()
  return current


iterator batchImprove*(states: seq[ColoringState], tabuThreshold: int): ColoringState =
  var jobs: seq[FlowVarBase]

  for state in states:
    jobs.add(spawn state.tabuImprove(tabuThreshold))
  
  for job in jobs:
    yield ^FlowVar[ColoringState](job)


proc buildPopulation*(graph: DenseGraph,
                      k: int,
                      populationSize: int,
                      tabuThreshold: int): seq[ColoringState] =
  # Builds a population of tabu-improved coloring assignments for the given graph.
  var initial, improved: seq[ColoringState]

  echo fmt"Building population of size {populationSize}"
  # Begin with random assignment states.
  for i in 0..<populationSize:
    initial.add(newColoringState(graph, k))
  
  # Tabu-improve each, terminating early if a valid coloring is found.
  for e in initial.batchImprove(tabuThreshold):
    echo fmt"Population element {e.cost}"
    improved.add(e)
    if e.cost == 0:
      break

  improved.sort(costCompare)
  return improved
