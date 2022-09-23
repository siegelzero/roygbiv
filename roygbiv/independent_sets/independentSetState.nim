import std/[random, strformat]

import ../graph


type
  IndependentSetState* = ref object
    graph*: DenseGraph
    k: int
    cost*: int
    #used*: VertexSet
    used*: seq[bool]
    bestCost*: int
    #bestUsed: VertexSet
    bestUsed: seq[bool]
    numAdjacent: seq[int]
    iteration*: int
    tabu*: seq[int]
  
proc newIndependentSetState*(graph: DenseGraph, k: int): IndependentSetState =
  var state = IndependentSetState()
  state.graph = graph
  state.k = k
  state.iteration = 0
  state.numAdjacent = newSeq[int](graph.numVertices)
  state.tabu = newSeq[int](graph.numVertices)
  state.used = newSeq[bool](graph.numVertices)

  var numAdded, idx: int
  while numAdded < k:
    idx = rand(state.graph.numVertices - 1)
    if not state.used[idx]:
      numAdded += 1
      state.used[idx] = true

  for u in graph.vertices:
    for v in graph.neighbors[u]:
      if state.used[v]:
        state.numAdjacent[u] += 1

  for (u, v) in graph.edges:
    if state.used[u] and state.used[v]:
      state.cost += 1

  state.bestCost = state.cost
  state.bestUsed = state.used
  
  return state

proc copy*(state: IndependentSetState): IndependentSetState =
  return IndependentSetState(
    graph: state.graph,
    k: state.k,
    cost: state.cost,
    bestCost: state.bestCost,
    used: state.used,
    bestUsed: state.bestUsed,
    numAdjacent: state.numAdjacent,
    iteration: 0,
    tabu: newSeq[int](state.graph.numVertices)
  )

proc swapCost*(state: IndependentSetState, u, v: Vertex): int {.inline.} =
  return state.cost + state.numAdjacent[v] - state.numAdjacent[u] + (1 - state.graph.adjacent[u][v])

proc swap*(state: IndependentSetState, u, v: Vertex, markTabu: bool = false) =
  state.cost = state.swapCost(u, v)

  state.used[u] = false
  for nu in state.graph.neighbors[u]:
    state.numAdjacent[nu] -= 1

  state.used[v] = true
  for nv in state.graph.neighbors[v]:
    state.numAdjacent[nv] += 1

  if state.cost < state.bestCost:
    echo fmt"Found {state.cost}"
    state.bestCost = state.cost
    state.bestUsed = state.used

  if markTabu:
    state.tabu[u] = state.iteration + 1 + rand(10)


proc loadBest*(state: IndependentSetState) =
  # Resets the state to the best coloring seen so far
  state.used = state.bestUsed
  state.cost = state.bestCost
