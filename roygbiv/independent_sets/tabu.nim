import std/[algorithm, random, strformat, threadpool, times]
import independentSetState
import ../graph


randomize()

type Move = (Vertex, Vertex)


proc bestMoves(state: IndependentSetState): seq[Move] {.inline.} =
  # Returns the best available moves for the state.
  var
    newCost: int
    bestMoveCost = high(int)

  for u in state.graph.vertices:
    if not state.used[u]:
      continue
    for v in state.graph.vertices:
      if state.used[v]:
        continue
      newCost = state.swapCost(u, v)

      if state.tabu[v] <= state.iteration or newCost < state.bestCost:
        if newCost < bestMoveCost:
          bestMoveCost = newCost
          result = @[(u, v)]
        elif newCost == bestMoveCost:
          result.add((u, v))


proc applyBestMove(state: IndependentSetState) {.inline.} =
  # Applies a randomly chosen best greedy move to the state, mutating state.
  var moves = state.bestMoves()
  if moves.len > 0:
    let (u, v) = sample(moves)
    # echo fmt"Swapping {u} {v}"
    state.swap(u, v, markTabu = true)
  state.iteration += 1


proc tabuImprove*(state: IndependentSetState, threshold: int, verbose: bool = false): IndependentSetState =
  var
    current = state.copy()
    bestSoFar = current.cost
    lastImprovement = 0
    then = epochTime()
    start = then
    blockSize = 10000
    now, rate: float

  while current.cost > 0 and current.iteration - lastImprovement < threshold:
    current.applyBestMove()
    if verbose and current.iteration > 0 and current.iteration mod blockSize == 0:
      now = epochTime()
      rate = float(blockSize) / (now - then)
      then = now
      echo fmt"Iteration: {current.iteration}  Current: {current.cost}  Best: {current.bestCost}  Rate: {rate:.3f} moves/sec"

    if current.cost < bestSoFar:
      lastImprovement = current.iteration
      bestSoFar = current.cost
    
  current.loadBest()
  now = epochTime()
  rate = float(current.iteration) / (now - start)
  echo fmt"Completed on iteration: {current.iteration}  Current: {current.cost}  Best: {current.bestCost}  Rate: {rate:.3f} moves/sec"
  return current
