import std/[algorithm, packedsets, random, sequtils]

import graph


randomize()


type
  VertexSet = PackedSet[Vertex]

  Move* = (Vertex, int)

  GraphState* = ref object
    # graph is the underlying graph
    graph*: Graph

    # k is the number of colors available in the assignment
    k*: int

    # color[u] is the color of the vertex u
    color*: seq[int]

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


proc initGraphState*(graph: Graph, k: int): GraphState =
  # Returns a new GraphState for the graph with a random assignment of k colors.
  var state = GraphState()
  state.graph = graph
  state.color = newSeq[int](graph.n)
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
      for color in 0..<k:
        if state.color[v] == color:
          state.numAdjacent[u][color] += 1

  for (u, v) in graph.edges:
    if state.color[u] == state.color[v]:
      state.cost += 1
  
  state.bestCost = state.cost
  state.bestColor = state.color
  return state


proc copy*(state: GraphState): GraphState =
  # Returns a copy of the state, with tabu data reset.
  return GraphState(
    graph: state.graph,
    k: state.k,
    cost: state.cost,
    bestCost: state.bestCost,
    color: state.color,
    bestColor: state.bestColor,
    numAdjacent: state.numAdjacent,
    iteration: 0,
    tabu: newSeqWith(state.graph.n, newSeq[int](state.k)),
  )


func colorCost*(state: GraphState, u: Vertex, newColor: int): int {.inline.} =
  # Returns the assignment cost obtained by changing vertex u to the given color
  let oldColor = state.color[u]
  return state.cost + state.numAdjacent[u][newColor] - state.numAdjacent[u][oldColor]


proc setColor*(state: GraphState, u: Vertex, newColor: int, mark: bool = false) {.inline.} =
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
    state.tabu[u][oldColor] = state.iteration + 6*state.cost + rand(10)


proc loadBest*(state: GraphState) =
  # Resets the state to the best coloring seen so far
  for u in state.graph.vertices:
    state.setColor(u, state.bestColor[u])

  doAssert state.color == state.bestColor
  doAssert state.cost == state.bestCost


proc vertexPartition*(state: GraphState): seq[VertexSet] =
  var
    group: VertexSet
    partition: seq[VertexSet]

  # Initialize empty group for each color in the assignment
  for i in 0..<state.k:
    group = initPackedSet[Vertex]()
    partition.add(group)

  # Put each vertex into its color group
  for u in state.graph.vertices:
    partition[state.color[u]].incl(u)

  # Sort the groups according to least element
  func min(A: VertexSet): Vertex = A.items.toSeq.min()
  func myCmp(A, B: VertexSet): int = return cmp(A.min(), B.min())
  partition.sort(myCmp)

  return partition


proc alignColors*(state, target: GraphState) =
  doAssert target.k == state.k

  let targetPartition = target.vertexPartition()
  var
    currentPartition = state.vertexPartition()
    bestMatch: VertexSet
    newPartition: seq[VertexSet]
    intersection, maxIdx, maxIntersection: int

  for group in targetPartition:
    maxIntersection = 0
    maxIdx = 0
    for i in 0..<currentPartition.len:
      intersection = group.intersection(currentPartition[i]).len()
      if intersection > maxIntersection:
        maxIntersection = intersection
        maxIdx = i

    bestMatch = currentPartition[maxIdx]
    newPartition.add(bestMatch)
    currentPartition.del(maxIdx)
  
  for i in 0..<newPartition.len:
    for u in newPartition[i]:
      state.setColor(u, i)


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

    assert state.iteration == 0
    assert state.k == 3
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

  block: # vertex partitioning
    var graph = squareGraph()
    var state = initGraphState(graph, 2)
    state.setColor(0, 0)
    state.setColor(1, 1)
    state.setColor(2, 0)
    state.setColor(3, 1)
    assert state.cost == 0

    var partition = state.vertexPartition()
    assert partition == @[[0, 2].toPackedSet, [1, 3].toPackedSet]

  block: # color alignment
    var graph = squareGraph()
    # Initialize two GraphStates for the graph, with equivalent (but different)
    # color assignments
    var state1 = initGraphState(graph, 2)
    state1.setColor(0, 0)
    state1.setColor(1, 1)
    state1.setColor(2, 0)
    state1.setColor(3, 1)

    var state2 = initGraphState(graph, 2)
    state2.setColor(0, 1)
    state2.setColor(1, 0)
    state2.setColor(2, 1)
    state2.setColor(3, 0)

    # Check that both color assignments are valid but different
    assert state1.cost == 0
    assert state2.cost == 0
    assert state1.color != state2.color

    # Align state2 assignment with state1
    state2.alignColors(state1)

    # Check that assignments are now the same
    assert state1.cost == 0
    assert state2.cost == 0
    assert state1.color == state2.color
