import std/[random, strformat, times]
import graph
import graphState


randomize()


proc bestMoves*(state: var GraphState): seq[Move] {.inline.} =
  var
    oldColor: int
    newCost: int
    bestMoveCost = 1000000

  for u in state.graph.vertices:
    oldColor = state.color[u]

    # if u has no conflicting neighbors, don't change its color
    if state.numAdjacent[u][oldColor] == 0:
      continue

    for newColor in 0..<state.k:
      newCost = state.colorCost(u, newColor)

      if state.tabu[u][newColor] <= state.iteration or newCost < state.bestCost:
        if newCost < bestMoveCost:
          bestMoveCost = newCost
          result = @[(u, newColor)]
        elif newCost == bestMoveCost:
          result.add((u, newColor))


proc applyBestMove*(state: var GraphState) {.inline.} =
  var moves = state.bestMoves()

  if moves.len > 0:
    let (u, newColor) = sample(moves)
    state.setColor(u, newColor, mark = true)


proc tabuImprove*(state: GraphState, threshold: int): GraphState =
  var
    current = state.copy()
    lastImprovement = 0
    then = epochTime()
    start = then
    now, rate: float
    blockSize = 100000

  result = current.copy()

  while current.iteration - lastImprovement < threshold:
    current.applyBestMove()

    if current.iteration > 0 and current.iteration mod blockSize == 0:
      now = epochTime()
      rate = float(blockSize) / (now - then)
      then = now
      echo fmt"Iteration: {current.iteration}  Current: {current.cost}  Best: {current.bestCost}  Rate: {rate:.3f} it/sec"

    if current.cost < current.bestCost:
      if current.cost == 0:
        echo fmt"Solution found on iteration: {current.iteration}  Time Elapsed: {epochTime() - start:.3f}"
        return current

      lastImprovement = current.iteration
      current.bestCost = current.cost
      result = current.copy()
    
    current.iteration += 1


when isMainModule:
  proc squareGraph(): Graph =
    result = initGraph(4)
    result.addEdge(0, 1)
    result.addEdge(1, 2)
    result.addEdge(2, 3)
    result.addEdge(3, 0)

  block: # random coloring of square 
    var graph = squareGraph()
    var state = initGraphState(graph, 2)
    var improved = state.tabuImprove(100)
    assert improved.cost == 0

  block: # coloring of petersen graph
    var graph = petersenGraph()

    # Can color Petersen graph with 3 colors
    var state3 = initGraphState(graph, 3)
    var improved3 = state3.tabuImprove(100)
    assert improved3.cost == 0

    # Cannot color Petersen graph with 2 colors
    var state2 = initGraphState(graph, 2)
    var improved2 = state2.tabuImprove(100)
    assert improved2.cost > 0