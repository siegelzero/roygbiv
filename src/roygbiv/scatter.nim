import std/random

import graph
import graphState


randomize()


proc relinkPath(A, B: GraphState): seq[GraphState] =
  var
    bestMoves: seq[int]
    bestMoveCost: int
    moves: seq[(int, int)]
    current = A.copy()

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

    result.add(current.copy())
