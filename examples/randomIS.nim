import std/[os, packedsets, sequtils, strformat, strutils, times]

import roygbiv/[coloring, graph, independent_sets]


when isMainModule:
  let
    n = parseInt(paramStr(1))
    density = parseFloat(paramStr(2))
    k = parseInt(paramStr(3))
    then = epochTime()

  var foo = randomGraph(n, density)
  var state = newIndependentSetState(foo, k)
  #echo fmt"Have cost {state.cost} with {state.used}"
  var res = state.tabuImprove(10000)
  var diff = epochTime() - then

  #echo res.used.toSeq
  echo fmt"Found {res.cost} in {diff:.3f} seconds"
