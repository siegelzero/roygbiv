import std/random

import graph
import graphState
import tabu


randomize()


proc relinkPath(A, B: GraphState): seq[GraphState] =
  doAssert A.k == B.k

  var
    bestMoves: seq[int]
    bestMoveCost: int
    moves: seq[(int, int)]
    current = A.copy()

  # current.alignColors(B)

  for u in A.graph.vertices:
    if A.color[u] != B.color[u]:
      moves.add((u, B.color[u]))

  while moves.len > 0:
    bestMoves = @[]
    bestMoveCost = high(int)

    for mi in 0..<moves.len:
      var (u, newColor) = moves[mi]
      var newCost = A.colorCost(u, newColor)

      if newCost < bestMoveCost:
        bestMoves = @[mi]
        bestMoveCost = newCost
      elif newCost == bestMoveCost:
        bestMoves.add(mi)

    let ri = sample(bestMoves)
    let (u, newColor) = moves[ri]
    current.setColor(u, newColor)
    moves.del(ri)

    if rand(1.0) <= 0.2:
      result.add(current.copy())


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
