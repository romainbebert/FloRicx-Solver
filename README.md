# FloRicx-Solver

First year of master's degree in Operations Research project
Subject : Using a language of your choice, create a solver for QAP instances implementing the heuristic of your choice.

The QAP (Quadratic Assignment Problem) consists of n facilities and locations. One location can implement one facility. 
Each facility has flows to move to other facilities and each location are at a certain distance from one another.
The goal is to minimize sum(flows*distance) for each location/facility pairs

Language : Julia 
Heuristic : Genetic Algorithm (I'm also interested in Tabu Search, may do it later if I find the time)

Genetic algorithm implementation choices :

Generational strategy using a roulette selection depending on the value of the fitnesses to determine the chances to get picked
as a parent for the next generation. I use crossovers as my mean to create the next generations (some also do tournaments to 
save part of the precedent generation and have a crossover chance). Some mutations may occur as random swaps (currently fixed 
at 10% chance of happening).

A solution is represented as an array containing the location of the warehouses. If array[1] = 7, 
warehouse n°1 is at location n°7 allowing for a simple representation making crossover and mutations easy to implement.

At the moment, the first generation is generated creating nbInd random individuals, but using a fine tuned GRASP or rGRASP 
heuristic could prove to be really beneficial if I have the time to implement it.
