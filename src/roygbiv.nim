import std/[os, strformat, strutils, times]
import roygbiv/[graph, graphState, hybrid, scatter, tabu]


proc tabuColor*(graph: Graph, k, tabuThreshold: int): GraphState =
  var state = initGraphState(graph, k)
  return state.tabuImprove(tabuThreshold)


when isMainModule:
  let
    path = paramStr(1)
    k = parseInt(paramStr(2))
    popSize = parseInt(paramStr(3))
    iterations = parseInt(paramStr(4))
    threshold = parseInt(paramStr(5))
  
  var g = loadDIMACS(path)

  let start = epochTime()
  # var improved = tabuColor(g, k, threshold)
  # var improved = scatterSearch(g, k, popSize, iterations, threshold)
  # var improved = hybridEvolutionary(g, k, popSize, iterations, threshold)
  var improved = hybridEvolutionaryParallel(g, k, popSize, iterations, threshold)
  let stop = epochTime()

  echo fmt"Found {improved.cost}"
  echo fmt"Time taken: {stop - start:.3f}"