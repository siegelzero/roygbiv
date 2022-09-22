import std/[packedsets, random, sequtils]
export packedsets

################################################################################
# DenseGraph
################################################################################

type
  Vertex* = int
  VertexSet* = PackedSet[Vertex]

  DenseGraph* = ref object
    ## Undirected Simple Graph with n vertices, represented by 0, 1, ..., n-1
    numVertices*: int
    neighbors*: seq[VertexSet]
    adjacent*: seq[seq[int]]
  
iterator vertices*(graph: DenseGraph): Vertex {.inline.} =
  for u in 0..<graph.numVertices: yield u

iterator edges*(graph: DenseGraph): (Vertex, Vertex) =
  # Iterator over the edges (u, v) of the graph with u < v
  for u in graph.vertices:
    for v in graph.neighbors[u]:
      if u < v:
        yield (u, v)

func newDenseGraph*(n: int): DenseGraph =
  DenseGraph(
    numVertices: n,
    neighbors: newSeq[VertexSet](n),
    adjacent: newSeqWith(n, newSeq[int](n)),
  )

func addEdge*(graph: DenseGraph, u, v: Vertex) =
  graph.neighbors[u].incl(v)
  graph.neighbors[v].incl(u)
  graph.adjacent[u][v] = 1
  graph.adjacent[v][u] = 1

proc randomGraph*(n: int, density: float): DenseGraph =
  result = newDenseGraph(n)
  for u in result.vertices:
    for v in result.vertices:
      if u < v:
        if rand(1.0) <= density:
          result.addEdge(u, v)

proc complement*(graph: DenseGraph): DenseGraph =
  result = newDenseGraph(graph.numVertices)
  for u in graph.vertices:
    for v in graph.vertices:
      if not (v in graph.neighbors[u]):
        result.addEdge(u, v)
