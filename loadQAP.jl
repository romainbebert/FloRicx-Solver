# --------------------------------------------------------------------------- #
# Original code for loading SPP instances by Xavier Gandibleux
# Loading an instance of QAP (format: FloRicx library)

function loadSPP(fname)
    f=open(fname)
    # lecture du nbre d'entrepots et d'emplacements
    n = parse.(Int, readline(f))
    # Lecture du X à satisfaire
    X = parse.(Int, readline(f))
    # Construction des matrices à remplir
    flux = zeros(Int, n, n)
    distances = zeros(Int, n, n)

    readline(f)

    for i=1:n
        # lecture du nombre d'elements non nuls sur la contrainte i (non utilise)
        j=1
        # lecture des indices des elements non nuls sur la contrainte i
        for valeur in split(readline(f))
          flux[i,j]=parse.(Int,valeur)
          j+=1
        end
    end

    readline(f)

    for i=1:n
        # lecture du nombre d'elements non nuls sur la contrainte i (non utilise)
        j=1
        # lecture des indices des elements non nuls sur la contrainte i
        for valeur in split(readline(f))
          distances[i,j]=parse.(Int,valeur)
          j+=1
        end
    end
	
    close(f)
    println(flux)
    return X, flux, distances
end
