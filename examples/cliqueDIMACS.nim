import std/[os, packedsets, strformat, strutils, times]

import roygbiv/[graph, independent_sets]


proc loadDIMACS*(path: string): DenseGraph =
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

  var graph = newDenseGraph(numVertices)

  for line in file.lines:
    var terms = line.split(" ")
    if terms[0] == "e":
      u = parseInt(terms[1]) - 1
      v = parseInt(terms[2]) - 1
      graph.addEdge(u, v)

  return graph


proc cliqueDIMACS(path: string, k: int): IndependentSetState =
  var graph = loadDIMACS(path)

  let
    # populationSize = 2*max(graph.n div 60, 10)
    # populationSize = 16
    # populationSize = 4
    # generations = 1000
    # tabuThreshold = 10*graph.numVertices
    tabuThreshold = 1000000
  
  echo "Finding Clique..."
  var complement = graph.complement()
  var state = newIndependentSetState(complement, k)
  var improved = state.tabuImprove(tabuThreshold)

  return improved


when isMainModule:
  let
    path = paramStr(1)
    k = parseInt(paramStr(2))
    then = epochTime()

  let res = cliqueDIMACS(path, k)
  let diff = epochTime() - then

  echo fmt"Found {res.cost} in {diff:.3f} seconds"
