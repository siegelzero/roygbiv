import std/strutils


type
  Vertex* = int
  Graph* = ref GraphObj
  GraphObj = object
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
  result = Graph(
    n: n,
    neighbors: newSeq[seq[int]](n)
  )


func addEdge*(graph: var Graph, u, v: Vertex) =
  # Adds edge (u, v) to the graph
  graph.neighbors[u].add(v)
  graph.neighbors[v].add(u)


proc loadDIMACS*(path: string): Graph =
  let file = open(path, fmRead)
  var
    u, v: int
    numEdges, numVertices: int
    terms: seq[string]

  for line in file.lines:
    terms = line.split(" ")
    if terms[0] == "p":
      numVertices = parseInt(terms[2])
      numEdges = parseInt(terms[3])
      break

  var graph = initGraph(numVertices)

  for line in file.lines:
    var terms = line.split(" ")
    if terms[0] == "e":
      u = parseInt(terms[1]) - 1
      v = parseInt(terms[2]) - 1
      graph.addEdge(u, v)

  return graph


func petersenGraph*(): Graph =
  # Returns Petersen graph
  result = initGraph(10)
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

    assert graph.n == 10
    assert graph.vertices.toSeq.len == 10
    assert graph.edges.toSeq.len == 15