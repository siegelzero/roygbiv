import std/[algorithm, random, strformat, threadpool]

import graph
import graphState
import tabu


proc hybridEvolutionary*(graph: Graph,
                         k: int,
                         populationSize: int,
                         iterations: int,
                         threshold: int): GraphState =

  var
    A, B, C: GraphState
    population: seq[GraphState]
    currentThreshold = threshold

  # Begin by building a population of tabu refined assignment states.
  echo fmt"Building initial population"
  population = buildPopulation(graph, k, populationSize, currentThreshold)
  if population[0].cost == 0:
    return population[0]

  for i in 0..<iterations:
    population.shuffle()
    A = population[0]
    B = population[1]
    C = crossover(A, B).tabuImprove(currentThreshold)

    echo fmt"Iteration {i}: crossover {A.cost} - {B.cost} --> {C.cost}"

    if C.cost == 0:
      return C

    if A.cost > B.cost:
      population[0] = C
    else:
      population[1] = C

  population.sort(costCompare)
  return population[0]


proc batchCrossoverImprove*(states: var seq[GraphState], tabuThreshold: int) =
  var
    jobs: seq[FlowVarBase]
    child: GraphState

  var i = 0
  while i + 1 < states.len:
    jobs.add(spawn crossover(states[i], states[i + 1]).tabuImprove(tabuThreshold))
    i += 2

  for i, job in jobs:
    child = ^FlowVar[GraphState](job)
    echo fmt"{states[i].cost} - {states[i + 1].cost} -> {child.cost}"

    if states[i].cost > states[i + 1].cost:
      states[i] = child
    else:
      states[i + 1] = child


proc hybridEvolutionaryParallel*(graph: Graph,
                                 k: int,
                                 populationSize: int,
                                 iterations: int,
                                 threshold: int): GraphState =

  var
    population: seq[GraphState]
    currentThreshold = threshold

  doAssert populationSize mod 2 == 0

  # Begin by building a population of tabu refined assignment states.
  echo fmt"Building initial population"
  population = buildPopulation(graph, k, populationSize, currentThreshold)
  if population[0].cost == 0:
    return population[0]

  for i in 0..<iterations:
    population.shuffle()
    population.batchCrossoverImprove(currentThreshold)
    population.sort(costCompare)
    if population[0].cost == 0:
      break

  return population[0]