# !/usr/local/opt/julia/bin/julia

include("getfname.jl")
include("loadQAP.jl")
include("genetic.jl")

function runFile(filename)

	X, flux, distances = loadQAP(filename)

	z, sol = geneticSolver(X, flux, distances, 0.1, 100)

end

function runAll()

	fnames = getfname("/qap")

	for file in fnames

		X, flux, distances = loadQAP(file)

		#geneticSolver(X, flux, distances, 0.1, 50)

	end

end

runFile("qap/chr12a.dat")
