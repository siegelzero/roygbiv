# Package
version = "0.1"
author = "Kenneth Brown"
description = "Metaheuristics for Graph Coloring"
license = "MIT"

srcDir = "src"
bin = @["roygbiv"]

# Deps
requires "nim >= 0.13.0"

task test, "Test":
  exec "nim c -r src/roygbiv/graph.nim"
  exec "nim c -r src/roygbiv/graphState.nim"
  exec "nim c -r src/roygbiv/tabu.nim"