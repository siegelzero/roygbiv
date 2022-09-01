import std/[algorithm, random, strformat, threadpool]
import graph
import graphState


randomize()


func bestMoves*(state: GraphState): seq[Move] {.inline.} =
  # Returns the best available moves for the state.
  var
    newCost: int
    bestMoveCost = high(int)

  for u in state.graph.vertices:
    # If u is already a different color than each of its neighbor, don't change u.
    if state.numAdjacent[u][state.color[u]] == 0:
      continue

    # Otherwise, determine the cost of changing u to each possible color.
    for newColor in 0..<state.k:
      newCost = state.colorCost(u, newColor)

      # Only consider this new color if the move is not tabu, or if the new
      # assignment cost is the best seen so far.
      if state.tabu[u][newColor] <= state.iteration or newCost < state.bestCost:
        # Either keep this new move or add it to the best moves
        if newCost < bestMoveCost:
          bestMoveCost = newCost
          result = @[(u, newColor)]
        elif newCost == bestMoveCost:
          result.add((u, newColor))


proc applyBestMove*(state: GraphState) {.inline.} =
  # Applies a randomly chosen best greedy move to the state, mutating state.
  var moves = state.bestMoves()
  if moves.len > 0:
    let (u, newColor) = sample(moves)
    state.setColor(u, newColor, mark = true)
  state.iteration += 1


proc tabuImprove*(state: GraphState, threshold: int): GraphState =
  var
    current = state.copy()
    bestSoFar = current.cost
    lastImprovement = 0

  while current.cost > 0 and current.iteration - lastImprovement < threshold:
    current.applyBestMove()
    if current.cost < bestSoFar:
      lastImprovement = current.iteration
      bestSoFar = current.cost
    
  current.loadBest()
  return current


iterator batchImprove*(states: seq[GraphState], tabuThreshold: int): GraphState =
  var
    jobs: seq[FlowVarBase]
    idx: int

  for state in states:
    jobs.add(spawn state.tabuImprove(tabuThreshold))
  
  while jobs.len > 0:
    idx = blockUntilAny(jobs)
    yield ^FlowVar[GraphState](jobs[idx])
    jobs.del(idx)


proc buildPopulation*(graph: Graph,
                      k: int,
                      populationSize: int,
                      tabuThreshold: int): seq[GraphState] =
  # Builds a population of tabu-improved coloring assignments for the given graph.
  var initial, improved: seq[GraphState]

  # Begin with random assignment states.
  for i in 0..<populationSize:
    initial.add(initGraphState(graph, k))
  
  # Tabu-improve each, terminating early if a valid coloring is found.
  for e in initial.batchImprove(tabuThreshold):
    echo fmt"Population element {e.cost}"
    improved.add(e)
    if e.cost == 0:
      break

  improved.sort(costCompare)
  return improved


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