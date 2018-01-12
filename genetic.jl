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

#--------------- Generation fabrication functions ------------------

function firstGen(flux, distances, nbInd)
	#Generation attributes initialization
	gen = []
	nbEntrepots = size(distances,1)
	fitnesses = zeros(Int32, nbInd)
	roulette = zeros(Int32, nbInd)
	curr_best = 2^31-1 #Initialized at max Int32 value
	fittest = []

	for i in 1:nbInd
		push!(gen,shuffle(1:nbEntrepots))
		fitnesses[i] = fitness(gen[i], flux, distances)

		if fitnesses[i] < curr_best
			curr_best = fitnesses[i]
			fittest = gen[i]
		end
	end

	roulette = cumsum(fitnesses)
	roulette = broadcast(-, roulette[nbInd], fitnesses)

	return Generation(nbInd, gen, fitnesses, roulette, 0.1, roulette[1]/nbInd, curr_best, fittest)
end

function nextGen(flux, distances, population::Generation)
	newGen = []
	#Création de la nouvelle génération par crossovers
	for i in floor(Int,1):floor(Int,population.nbInd/2)
		randomFit1 = rand(1:population.roulette[1])
		randomFit2 = rand(1:population.roulette[1])

		#Sélection des parents dans la roulette
		iter = 1
		while randomFit1 > population.roulette[iter]
			if iter == 100
				println(randomFit1)
			end
			iter += 1
		end
		parent1 = population.people[iter]

		iter = 1
		while randomFit2 > population.roulette[iter]
			if iter == 100
				println(randomFit2)
			end
			iter += 1
		end
		parent2 = population.people[iter]
		c1, c2 = OX_crossover(parent1, parent2)
		push!(newGen, c1)
		push!(newGen, c2)

	end

	newFitnesses = zeros(Int32, population.nbInd)
	curr_best = 2^31-1
	fittest = []
	#Update des fitnesses
	for i in 1:population.nbInd
		#Potentielle mutation
		if rand() > population.mchance
			newGen[i] = mutation(newGen[i])
		end

		newFitnesses[i] = fitness(newGen[i], flux, distances)

		if newFitnesses[i] < curr_best
			curr_best = newFitnesses[i]
			fittest = newGen[i]
		end
	end

	roulette = cumsum(newFitnesses)

	#Actualisation de l'objet Génération
	population.people = newGen
	population.fitnesses = newFitnesses
	population.roulette = broadcast(-, roulette[population.nbInd], roulette)
	population.gen_best = curr_best
	population.fittest = fittest

end

#-------------------------------------------------------------------


#--------- Diversification and intensification strategies ----------

#One point crossover
function crossover(p1,p2)
	#Init indice random et découpage des parents
	ind = rand(1:size(p1,1))
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
function mutation(x)
	nbVar = size(x,1)
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

function fitness(solution, flux, distances)
	tot = 0
	for i in 1:size(flux,1)
		for j in i:size(flux,1)
			tot += flux[i, j]*distances[solution[i], solution[j]]

		end
	end
	return tot*2
end

function localsearch(solution, flux, distances)
	fittest = copy(solution)
	curr_best = fitness(solution,flux,distances)
	for i in 1:size(solution,1)-1
		for j in i+1:size(solution,1)
			new_sol = copy(solution)
			new_sol[i] = solution[j]
			new_sol[j] = solution[i]
			val = fitness(new_sol, flux, distances)
			if val > curr_best
				fittest = new_sol
				curr_best = val
			end
		end
	end
	
	return fittest
end

#-------------------------------------------------------------------

function geneticSolver(X, flux, distances,mchance, gen_size)

	#Première génération random
	populace = firstGen(flux, distances, gen_size)
	i = 1
	curr_best = populace.gen_best

	while(curr_best > X)
		println("\n########### STARTING GENERATION ", i ," ########### \n")
		nextGen(flux, distances, populace)
		if populace.gen_best < curr_best
			curr_best = populace.gen_best
		end

		println("	CURRENT BEST : ", curr_best)
		#println("GEN STATS :")
		#println("	MEAN : ", populace.gen_mean)
		println("	GEN BEST : ", populace.gen_best)
		i+=1
	end

	println("z = ", populace.gen_best,"\nSolution : ", populace.fittest)

	return (populace.gen_best, populace.fittest)

end
