# !/usr/local/opt/julia/bin/julia

include("getfname.jl")
include("loadQAP.jl")
include("genetic.jl")

function runFile(filename)

	instance = loadQAP(filename)

	geneti(instance)

end

function runAll()

	fnames = getfname("/qap")

	for file in fnames

		instance = loadQAP(file)

		#genetic(instance)

	end

end

runAll()
