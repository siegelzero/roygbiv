import std/[packedsets]

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
  
iterator vertices*(graph: DenseGraph): Vertex {.inline.} =
  for u in 0..<graph.numVertices: yield u

iterator edges*(graph: DenseGraph): (Vertex, Vertex) =
  # Iterator over the edges (u, v) of the graph with u < v
  for u in graph.vertices:
    for v in graph.neighbors[u]:
      if u < v:
        yield (u, v)

func newDenseGraph*(n: int): DenseGraph =
  DenseGraph(numVertices: n, neighbors: newSeq[VertexSet](n))

func addEdge*(graph: var DenseGraph, u, v: Vertex) =
  # Adds edge (u, v) to the graph
  graph.neighbors[u].incl(v)
  graph.neighbors[v].incl(u)
