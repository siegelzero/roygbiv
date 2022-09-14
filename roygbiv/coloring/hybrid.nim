import std/[algorithm, packedsets, random, strformat, threadpool]

import ../graph
import coloringState, tabu


randomize()


type
  Partition = seq[VertexSet]


proc vertexPartition*(state: ColoringState): seq[VertexSet] =
  # Partitions the vertices of the underlying graph according to color.
  var
    group: VertexSet
    partition: seq[VertexSet]

  # Initialize empty group for each color in the assignment
  for i in 0..<state.k:
    group = initPackedSet[Vertex]()
    partition.add(group)

  # Put each vertex into its color group
  # partition[i] is the set of vertices of color i in the assignment
  for u in state.graph.vertices:
    partition[state.color[u]].incl(u)

  return partition


func biggestGroup(A: seq[VertexSet]): VertexSet =
  result = A[0]
  for i in 1..<A.len:
    if A[i].len > result.len:
      result = A[i]


proc crossover*(A, B: ColoringState): ColoringState =
  var
    group: VertexSet
    pairedGroups: seq[Partition]

  pairedGroups = @[A.vertexPartition(), B.vertexPartition()]
  result = newColoringState(A.graph, A.k)

  for i in 0..<A.k:
    group = biggestGroup(pairedGroups[i mod 2])
    for u in group:
      result.setColor(u, i)
    for gp in pairedGroups[(i + 1) mod 2].mitems:
      gp.excl(group)
    for gp in pairedGroups[i mod 2].mitems:
      gp.excl(group)


proc batchCrossoverImprove*(states: var seq[ColoringState], tabuThreshold: int) =
  var
    i = 0
    jobs: seq[FlowVarBase]
    child: ColoringState

  states.shuffle()

  while i + 1 < states.len:
    child = crossover(states[i], states[i + 1])
    jobs.add(spawn child.tabuImprove(tabuThreshold))
    i += 2

  for i, job in jobs:
    child = ^FlowVar[ColoringState](job)

    if states[i].cost > states[i + 1].cost:
      states[i] = child
    else:
      states[i + 1] = child

  states.sort(costCompare)


proc populationDetails(states: seq[ColoringState]) =
  var costs: seq[int]
  for state in states:
    costs.add(state.cost)
  echo fmt"Population: {costs}"


proc hybridEvolutionaryParallel*(graph: DenseGraph,
                                 k: int,
                                 populationSize: int,
                                 iterations: int,
                                 threshold: int): ColoringState =

  var
    population: seq[ColoringState]

  # Begin by building a population of tabu refined assignment states.
  echo fmt"Building initial population"
  population = buildPopulation(graph, k, populationSize, threshold)
  if population[0].cost == 0:
    return population[0]

  for i in 0..<iterations:
    populationDetails(population)
    population.batchCrossoverImprove(threshold)
    if population[0].cost == 0:
      break

  return population[0]
