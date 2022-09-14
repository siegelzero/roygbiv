import std/[packedsets]


type
  Vertex* = int
  VertexSet* = PackedSet[Vertex]

  DenseGraph* = ref object
    ## Undirected Simple Graph with n vertices, represented by 0, 1, ..., n-1
    numVertices*: int
    neighbors*: seq[VertexSet]
  
iterator vertices*(graph: DenseGraph): Vertex =
  # Iterator over the vertices of the graph
  for u in 0..<graph.numVertices: yield u

iterator edges*(graph: DenseGraph): (Vertex, Vertex) =
  # Iterator over the edges (u, v) of the graph with u < v
  for u in graph.vertices:
    for v in graph.neighbors[u]:
      if u < v:
        yield (u, v)

func newDenseGraph*(n: int): DenseGraph =
  # Returns new DenseGraph on n vertices
  DenseGraph(numVertices: n, neighbors: newSeq[VertexSet](n))

func addEdge*(graph: var DenseGraph, u, v: Vertex) =
  # Adds edge (u, v) to the graph
  graph.neighbors[u].incl(v)
  graph.neighbors[v].incl(u)


func petersenGraph*(): DenseGraph =
  # Returns Petersen graph
  result = newDenseGraph(10)
  result.addEdge(0, 2)
  result.addEdge(0, 3)
  result.addEdge(0, 6)
  result.addEdge(1, 3)
  result.addEdge(1, 4)
  result.addEdge(1, 7)
  result.addEdge(2, 4)
  result.addEdge(2, 8)
  result.addEdge(3, 9)
  result.addEdge(4, 5)
  result.addEdge(5, 6)
  result.addEdge(5, 9)
  result.addEdge(6, 7)
  result.addEdge(7, 8)
  result.addEdge(8, 9)


when isMainModule:
  import sequtils

  block: # Petersen graph
    let graph = petersenGraph()

    assert graph.numVertices == 10
    assert graph.vertices.toSeq.len == 10
    assert graph.edges.toSeq.len == 15