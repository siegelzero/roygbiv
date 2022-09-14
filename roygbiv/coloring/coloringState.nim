import std/[packedsets, random, sequtils]

import ../graph


randomize()


type
  Move* = (Vertex, int)

  ColoringState* = ref object
    # graph is the underlying graph
    graph*: DenseGraph

    # k is the number of colors available in the assignment
    k*: int

    # color[u] is the color of the vertex u
    color*: seq[int]

    # coefficient in tabu tenure
    alpha*: int

    # cost of the current coloring
    # this is the number of edges that have the same colored endpoints
    # the coloring is proper if the cost is 0
    cost*: int

    # best cost seen during the search
    bestCost*: int
    bestColor: seq[int]

    # numAdjacent[u][color] is the number of vertices adjacent to vertex u that are the given color
    numAdjacent*: seq[seq[int]]

    # current search iteration
    iteration*: int

    # color is tabu for vertex u if tabu[u][color] > iteration
    tabu*: seq[seq[int]]


proc initColoringState*(graph: DenseGraph, k: int): ColoringState =
  # Returns a new ColoringState for the graph with a random assignment of k colors.
  var state = ColoringState()
  state.graph = graph
  state.color = newSeq[int](graph.numVertices)
  state.alpha = 6
  state.k = k

  # initialize data structures
  for u in graph.vertices:
    state.numAdjacent.add(newSeq[int](k))
    state.tabu.add(newSeq[int](k))

  # color each vertex randomly
  for u in graph.vertices:
    state.color[u] = rand(k - 1)

  # bookkeeping for efficient neighbor evaluation
  for u in graph.vertices:
    for v in graph.neighbors[u]:
      state.numAdjacent[u][state.color[v]] += 1

  for (u, v) in graph.edges:
    if state.color[u] == state.color[v]:
      state.cost += 1
  
  state.bestCost = state.cost
  state.bestColor = state.color
  return state


proc copy*(state: ColoringState): ColoringState =
  # Returns a copy of the state, with tabu data reset.
  return ColoringState(
    graph: state.graph,
    k: state.k,
    alpha: state.alpha,
    cost: state.cost,
    bestCost: state.bestCost,
    color: state.color,
    bestColor: state.bestColor,
    numAdjacent: state.numAdjacent,
    iteration: 0,
    tabu: newSeqWith(state.graph.numVertices, newSeq[int](state.k)),
  )


func colorCost*(state: ColoringState, u: Vertex, newColor: int): int {.inline.} =
  # Returns the assignment cost obtained by changing vertex u to the given color
  let oldColor = state.color[u]
  return state.cost + state.numAdjacent[u][newColor] - state.numAdjacent[u][oldColor]


proc setColor*(state: ColoringState, u: Vertex, newColor: int, mark: bool = false) {.inline.} =
  # Sets color of vertex u to newColor and updates state
  # First adjust cost
  state.cost = state.colorCost(u, newColor)

  # Next change vertex color
  let oldColor = state.color[u]
  state.color[u] = newColor

  # Now update the best solution
  if state.cost < state.bestCost:
    state.bestCost = state.cost
    state.bestColor = state.color

  for v in state.graph.neighbors[u]:
    # v is adjancent to one less vertex of oldColor and one more vertex of newColor
    state.numAdjacent[v][oldColor] -= 1
    state.numAdjacent[v][newColor] += 1
  
  # Mark oldColor as tabu for vertex u for some number of iterations
  if mark:
    state.tabu[u][oldColor] = state.iteration + state.alpha*state.cost + rand(10)


proc loadBest*(state: ColoringState) =
  # Resets the state to the best coloring seen so far
  for u in state.graph.vertices:
    state.setColor(u, state.bestColor[u])

  doAssert state.color == state.bestColor
  doAssert state.cost == state.bestCost


proc distance*(A, B: ColoringState): int =
  # Returns the distance between the two assignment states; i.e. the number of
  # differently assigned vertices.
  for u in A.graph.vertices:
    if A.color[u] != B.color[u]:
      result += 1


func costCompare*(A, B: ColoringState): int = cmp(A.cost, B.cost)

func `==`*(A, B: ColoringState): bool = distance(A, B) == 0
