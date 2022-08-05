type
  Vertex* = int
  Graph* = object
    n*: int
    neighbors*: seq[seq[Vertex]]
  
iterator vertices*(graph: Graph): Vertex =
  for u in 0..<graph.n:
    yield u

iterator edges*(graph: Graph): (Vertex, Vertex) =
  for u in graph.vertices:
    for v in graph.neighbors[u]:
      if u < v:
        yield (u, v)

func initGraph*(n: int): Graph =
  result.n = n
  result.neighbors = newSeq[seq[int]](n)

func addEdge*(graph: var Graph, u, v: Vertex) =
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