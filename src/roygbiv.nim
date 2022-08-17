import std/[os, strformat, strutils, times]
import "./roygbiv/tabu"
import "./roygbiv/graph"
import "./roygbiv/graphState"


when isMainModule:
  let
    path = paramStr(1)
    k = parseInt(paramStr(2))
    threshold = parseInt(paramStr(3))
  
  var g = loadDIMACS(path)
  var state = initGraphState(g, k)
  let start = epochTime()
  var improved = state.tabuImprove(threshold)

  echo improved.cost

  let stop = epochTime()
  echo fmt"Time taken: {stop - start:.3f}"