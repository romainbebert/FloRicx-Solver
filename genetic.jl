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
	people::Array{Array{Int8,1},1} #Population of solutions
	fitnesses::Array{Int64} #To delete and only have the barrel ? 
	roulette::Array{Int64} #fitness' cumsum for random picking
	mchance::Float64 #Mutation chance
	gen_mean::Float64 #Fitness mean for this generation
	gen_best::Int64 #Best fitness of the generation
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
	curr_best = 2^31-1 #Initialized at max Int32 value

	for i in 1:nbInd
		push!(gen,shuffle(1:nbEntrepots))
		fitnesses[i] = fitness(gen[i], flux, distances)

		if fitnesses[i] < curr_best
	end
	
	roulette = cumsum(fitnesses)

	return Generation(nbInd, starter, fitnesses, roulette, 0.1, roulette[nbInd]/nbInd, curr_best)
end

function nextGen(objective, constraints, people::Generation)
	m,n = size(constraints)
	for i=1:people.nbInd
		
	end
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

function mutation(x,nbVar)
	ind = rand(1:nbVar)
	x[ind] == 0 ? x[ind]=1 : x[ind]=0
	return x
end

#-------------------------------------------------------------------

function geneticSolver(objective, constraints,mchance, gen_size, stopTime)

	#Première génération random
	populace = firstGen(objective, constraints, gen_size)
	endDate = now() + Dates.Millisecond(stopTime)
	i = 1

	while(now() < endDate)
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