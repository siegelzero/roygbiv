type
  Vertex* = int
  Graph* = object
    # n is the number of vertices
    n*: int

    # neighbors[u] contains the vertices v that share an edge with u
    neighbors*: seq[seq[Vertex]]

  
iterator vertices*(graph: Graph): Vertex =
  # Iterator over the vertices of the graph
  for u in 0..<graph.n:
    yield u


iterator edges*(graph: Graph): (Vertex, Vertex) =
  # Iterator over the edges (u, v) of the graph standardized with u < v.
  for u in graph.vertices:
    for v in graph.neighbors[u]:
      if u < v:
        yield (u, v)


func initGraph*(n: int): Graph =
  # Returns new Graph on n vertices
  result.n = n
  result.neighbors = newSeq[seq[int]](n)


func addEdge*(graph: var Graph, u, v: Vertex) =
  # Adds edge (u, v) to the graph
  graph.neighbors[u].add(v)
  graph.neighbors[v].add(u)


when isMainModule:
  import sequtils

  block: # square graph
    var graph = initGraph(4)
    graph.addEdge(0, 1)
    graph.addEdge(1, 2)
    graph.addEdge(2, 3)
    graph.addEdge(3, 0)

    assert graph.n == 4
    assert graph.vertices.toSeq.len == 4
    assert graph.edges.toSeq == @[(0, 1), (0, 3), (1, 2), (2, 3)]