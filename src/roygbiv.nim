import std/strutils
import std/strformat
import std/sequtils
import std/os
import std/times

import "./roygbiv/tabu"
import "./roygbiv/graph"
import "./roygbiv/graphState"


when isMainModule:
  let
    k = parseInt(paramStr(1))
    threshold = parseInt(paramStr(2))
    # start = epochTime()

    # path = "../data/dimacs/dsjc125.1.col" # 5
    # path = "../data/dimacs/dsjc125.5.col" # 17
    # path = "../data/dimacs/dsjc125.9.col" # 44

    # path = "../data/dimacs/dsjc250.1.col" # 8
    # path = "../data/dimacs/dsjc250.5.col" # 28/?
    # path = "../data/dimacs/dsjc250.9.col" # 72

    # path = "../data/dimacs/dsjc500.1.col" # 12/?
    path = "../data/dimacs/dsjc500.5.col" # 48/?
    # path = "../data/dimacs/dsjc500.9.col" # 126/?

    # path = "../data/dimacs/dsjc1000.1.col" # 20/?
    # path = "../data/dimacs/dsjc1000.5.col" # 85/?
    # path = "../data/dimacs/dsjc1000.9.col" # 223/?

    file = open(path, fmRead)
  
  var
    numEdges, numVertices: int
    u, v: int
  

  for line in file.lines:
    var terms = line.split(" ")
    if terms[0] == "p":
      numVertices = parseInt(terms[2])
      numEdges = parseInt(terms[3])
      break

  var g = initGraph(numVertices)

  for line in file.lines:
    var terms = line.split(" ")
    if terms[0] == "e":
      u = parseInt(terms[1]) - 1
      v = parseInt(terms[2]) - 1
      g.addEdge(u, v)

  assert 2*g.edges.toSeq.len == numEdges


  var state = initGraphState(g, k)
  let start = epochTime()

  var improved = state.tabuImprove(threshold)

  echo improved.cost

  let stop = epochTime()
  echo fmt"Time taken: {stop - start:.3f}"