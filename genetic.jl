#= 	Author : Romain Bernard
	Problem : QAP

	Genetic parameters :
		(crossover chance : xchance) -> pas applicable à cette implémentation
		mutation chance : mchance
		generation size : gen_size
		stop condition : stop (nb gen or time ?)

	Steps :
		create first gen (at random or via a heuristic)
		create its chance barrel using solution fitness and cumsum
		apply crossover using parents taken randomly from the barrel
		apply mutation to the childrens randomly
		rince and repeat until stop condition and return best solution found

	Strategy :
		Generational ?
		First gen created at random (change for a less random heuristic ? Like fine tuned GRASP or rGRASP)

	Solution's representation :
		Array of nbEntrepots values from 1 to nbEntrepots to represent the space to which a warehouse is attributed

	Since the solutions are created as the array of 1 to nbEntrepots shuffled, no constraint checking seems necessary when computing fitness
=#

#------------------- Type(s) definitions ---------------------------

type Generation
	nbInd::Int64
	people::Array{Array{Int64,1},1} #Population of solutions
	fitnesses::Array{Int64} #To delete and only have the barrel ?
	roulette::Array{Int64} #fitness' cumsum for random picking
	mchance::Float64 #Mutation chance
	gen_mean::Float64 #Fitness mean for this generation
	gen_best::Int64 #Best fitness of the generation
	fittest::Array{Int64,1} #Best solution of the generation (probable duplicate with gen_best but it makes some things easier to code)
end

#-------------------------------------------------------------------

#May be overkill to do a function, but in case we need to add constraint checking or something here
function fitness(solution, flux, distances)

	return sum(flux[i,solution[i]]*distances[i, solution[i]] for i in 1:size(distances,1))

end

#--------------- Generation fabrication functions ------------------

function firstGen(flux, distances, nbInd)
	#Generation attributes initialization
	gen = []
	nbEntrepots = size(distances,1)
	fitnesses = zeros(Int32, nbInd)
	roulette = zeros(Int32, nbInd)
	curr_best = 2^31-1 #Initialized at max Int32 value

	for i in 1:nbInd
		push!(gen,shuffle(1:nbEntrepots))
		fitnesses[i] = fitness(gen[i], flux, distances)

		if fitnesses[i] < curr_best
			curr_best = fitnesses[i]
			fittest = gen[i]
		end
	end

	roulette = curr_best .- fitnesses

	return Generation(nbInd, gen, fitnesses, roulette, 0.1, roulette[nbInd]/nbInd, curr_best, fittest)
end

function nextGen(objective, constraints, population::Generation)
	m,n = size(constraints)
	newGen = []

	#Création de la nouvelle génération par crossovers
	for i=1:population.nbInd/2

		randomFit1 = rand(1:population.roulette[population.nbInd])
		randomFit2 = rand(1:population.roulette[population.nbInd])

		#Sélection des parents dans la roulette
		iter = 1
		while population.roulette[i] < randomFit1
			iter += 1
		end
		parent1 = population.people[iter]

		iter = 1
		while population.roulette[i] < randomFit2
			iter += 1
		end
		parent2 = population.people[iter]

		push!(newGen, OX_crossover(parent1, parent2))

	end

	newFitnesses = zeros(Int32, population.nbInd)
	#Update des fitnesses
	for i in 1:nbInd
		newFitnesses[i] = fitness(newGen[i], flux, distances)

		if newFitnesses[i] < curr_best
			curr_best = newFitnesses[i]
			fittest = newGen[i]
		end
	end

	#Actualisation de l'objet Génération
	population.people = newGen
	population.fitnesses = newFitnesses
	population.roulette = newRoulette
	population.gen_best = curr_best
	population.fittest = fittest

end

#-------------------------------------------------------------------


#--------- Diversification and intensification strategies ----------

#One point crossover
function crossover(p1,p2)
	#Init indice random et découpage des parents
	ind = rand(1:size(p1,1))
	println(ind)
	p11 = splice!(p1,1:ind)
	p12 = p1
	p21 = splice!(p2,1:ind)
	p22 = p2

	c1 = []; c2 = []

	append!(c1, p11)
	append!(c1, p22)
	append!(c2, p21)
	append!(c2, p12)

	return c1,c2
end

#Mask crossover (increases randomness)
function mask_crossover(p1,p2)
	nbVar = size(p1,1)
	mask = rand!(zeros(Int8,nbVar),0:1)
	c1 = zeros(Int8,nbVar); c2 = zeros(Int8,nbVar)

	for i in 1:size(p1)
		if mask[i] == 0
			c1[i] = p1[i]
			c2[i] = p1[i]
		else
			c1[i] = p2[i]
			c2[i] = p1[i]
		end
	end
end

#= Etapes d'OX :
	- Choisir deux points de coupe
	- Enfant 1 prend la partie coupée de parent1
	- Enfant 1 récupère les éléments de parent2 ne se trouvant pas dans subseq1
	- Idem pour Enfant 2 en inversant les parents
=#
function OX_crossover(p1,p2)
	nbVar = size(p1,1)
	num1 = rand(1:nbVar)
	num2 = rand(1:nbVar)
	deb = min(num1, num2)
	fin = max(num1, num2)
	c1 = zeros(Int64,nbVar); c2 = zeros(Int64,nbVar)

	subseq1 = p1[deb:fin]
	subseq2 = p2[deb:fin]
	c1[deb:fin] = subseq1
	c2[deb:fin] = subseq2
	remaining1 = filter(x -> !in(x,subseq1), p2)
	remaining2 = filter(x -> !in(x,subseq2), p1)

	for i in 1:nbVar
		if c1[i] == 0
			c1[i] = shift!(remaining1)
		end
		if c2[i] == 0
			c2[i] = shift!(remaining2)
		end
	end

	return c1,c2
	#http://www.rubicite.com/Tutorials/GeneticAlgorithms/CrossoverOperators/Order1CrossoverOperator.aspx
end

#Mutation by swapping
function mutation(x,nbVar)
	num1 = rand(1:nbVar)
	num2 = rand(1:nbVar)
	#Pas indispensable mais ça serait dommage de gâcher une occurence de mutation
	while num1 == num2
		num2 = rand(1:nbVar)
	end

	swap1 = min(num1, num2)
	swap2 = max(num1, num2)

	tmp = x[swap1]
	x[swap1] = x[swap2]
	x[swap2] = tmp

	return x
end

#-------------------------------------------------------------------

function geneticSolver(X, objective, constraints,mchance, gen_size)

	#Première génération random
	populace = firstGen(objective, constraints, gen_size)
	i = 1

	while(curr_best > X)
		println("########### STARTING GENERATION ", i ," ###########")
		new_gen = nextGen(objective, constraints, populace)
		if curr_best < gen_best
			curr_best = gen_best
		end

		println("CURRENT BEST : ", curr_best)
		println("GEN STATS :")
		println("	MEAN : ", gen_mean)
		println("	BEST : ", gen_best)
		println("##############################################")
		i+=1
	end

end
