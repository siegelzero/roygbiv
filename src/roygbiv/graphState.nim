import random

import graph


randomize()


type
  GraphState* = ref object
    # graph is the underlying graph
    graph: Graph

    # k is the number of colors available in the assignment
    k: int

    # color[u] is the color of the vertex u
    color: seq[int]

    # cost of the current coloring
    # this is the number of edges that have the same colored endpoints
    # the coloring is proper if the cost is 0
    cost: int

    # numAdjacent[u][color] is the number of vertices adjacent to vertex u that are the given color
    numAdjacent: seq[seq[int]]

    # current search iteration
    iteration: int

    # color is tabu for vertex u if tabu[u][color] > iteration
    tabu: seq[seq[int]]



proc initGraphState*(graph: Graph, k: int): GraphState =
  # Returns a new GraphState for the graph with a random assignment of k colors.
  result = GraphState()
  result.graph = graph
  result.color = newSeq[int](graph.n)

  # initialize data structures
  for u in graph.vertices:
    result.numAdjacent.add(newSeq[int](k))
    result.tabu.add(newSeq[int](k))

  # color each vertex randomly
  for u in graph.vertices:
    result.color[u] = rand(k - 1)

  # bookkeeping for efficient neighbor evaluation
  for u in graph.vertices:
    for v in graph.neighbors[u]:
      for color in 0..<k:
        if result.color[v] == color:
          result.numAdjacent[u][color] += 1

  for (u, v) in graph.edges:
    if result.color[u] == result.color[v]:
      result.cost += 1


func colorCost*(state: GraphState, u: Vertex, newColor: int): int =
  # Returns the additional cost incurred by changing vertex u to the given color
  let oldColor = state.color[u]
  return state.numAdjacent[u][newColor] - state.numAdjacent[u][oldColor]


func setColor*(state: GraphState, u: Vertex, newColor: int) =
  # Sets color of vertex u to newColor and updates state
  # First adjust cost
  state.cost += state.colorCost(u, newColor)

  # Next change vertex color
  let oldColor = state.color[u]
  state.color[u] = newColor

  for v in state.graph.neighbors[u]:
    # v is adjancent to one less vertex of oldColor and one more vertex of newColor
    state.numAdjacent[v][oldColor] -= 1
    state.numAdjacent[v][newColor] += 1


when isMainModule:
  proc squareGraph(): Graph =
    result = initGraph(4)
    result.addEdge(0, 1)
    result.addEdge(1, 2)
    result.addEdge(2, 3)
    result.addEdge(3, 0)

  block: # random coloring of square 
    var graph = squareGraph()
    var state = initGraphState(graph, 3)

    assert state.color.len == graph.n

  block: # proper coloring of square 
    var graph = squareGraph()
    var state = initGraphState(graph, 2)

    state.setColor(0, 0)
    state.setColor(2, 0)
    state.setColor(1, 0)
    state.setColor(3, 0)

    # all four edges have same color endpoints
    assert state.cost == 4

    state.setColor(1, 1)
    state.setColor(3, 1)

    # now each edge is adjacent to different colors
    # this is a proper coloring, so the cost should be 0
    assert state.cost == 0
