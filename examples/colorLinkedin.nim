import std/[os, strformat, strutils, tables, times]

import roygbiv/[graph, coloring]


proc loadLinkedin*(path: string): (Graph, Table[string, int]) =
  let file = open(path, fmRead)
  var
    currentLine = -1
    numVertices: int
    vertexCount = 0
    vertex, neighbors: string
    vertexNeighbors: seq[string]

  var
    graph: Graph
    nameToInt: Table[string, int]

  echo "Reading file..."
  for line in file.lines:
    currentLine += 1
    if currentLine == 0:
      numVertices = parseInt(line)
      graph = initGraph(numVertices)
    else:
      if currentLine == numVertices:
        break
      vertexNeighbors = line.split(":")
      doAssert vertexNeighbors.len == 2

      vertex = vertexNeighbors[0]
      neighbors = vertexNeighbors[1]

      if not nameToInt.hasKey(vertex):
        nameToInt[vertex] = vertexCount
        vertexCount += 1

      for neighbor in neighbors.split(","):
        if not nameToInt.hasKey(neighbor):
          nameToInt[neighbor] = vertexCount
          vertexCount += 1
        
        graph.addEdge(nameToInt[vertex], nameToInt[neighbor])

  doAssert vertexCount == numVertices
  echo "Done."
  return (graph, nameToInt)


proc colorLinkedin(path: string): ColoringState =
  let (graph, nameToInt) = loadLinkedin(path)

  let
    k = 3
    tabuThreshold = 1000000
  
  echo "Coloring graph..."
  return initColoringState(graph, k).tabuImprove(tabuThreshold)


when isMainModule:
  let
    path = paramStr(1)
    then = epochTime()

  let res = colorLinkedin(path)
  let diff = epochTime() - then

  echo fmt"Found {res.cost} in {diff:.3f} seconds"
