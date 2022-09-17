import std/[os, packedsets, strformat, strutils, times]

import roygbiv/[coloring, graph]


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


proc colorDIMACS(path: string, k: int): ColoringState =
  let graph = loadDIMACS(path)

  let
    # populationSize = 2*max(graph.n div 60, 10)
    populationSize = 16
    # populationSize = 4
    generations = 1000
    tabuThreshold = 10*graph.numVertices
    # tabuThreshold = 1000000
  
  echo "Coloring graph..."
  # let improved = scatterSearch(graph, k, populationSize, generations, tabuThreshold)
  let improved = hybridEvolutionaryParallel(graph, k, populationSize, generations, tabuThreshold)
  # let improved = newColoringState(graph, k).tabuImprove(tabuThreshold, verbose = true)

  if improved.cost == 0:
    let filename = fmt"{path}.sol.{k}"
    echo fmt"Saving solution {filename}"
    var output = open(filename, fmWrite)
    for u in improved.graph.vertices:
      output.writeLine(improved.color[u])
    output.close()

  return improved


when isMainModule:
  let
    path = paramStr(1)
    k = parseInt(paramStr(2))
    then = epochTime()

  let res = colorDIMACS(path, k)
  let diff = epochTime() - then

  echo fmt"Found {res.cost} in {diff:.3f} seconds"
