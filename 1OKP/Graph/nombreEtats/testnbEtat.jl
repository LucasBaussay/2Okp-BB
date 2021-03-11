#include("progDynamique_part3_3_V2.jl")
#include("prog_dyn.jl")
include("pourAllerPlusLoin.jl")
#
#function complexiteSpatialeProgDyn1(ind::Int64)
#    file::IOStream = open("nombreEtats/ProgDyn1_$ind.txt", "w")
#    for i in 50:50:500
#        for j in 1:10
#            println(i)
#			L, val, nbEtatsStock, nbEtatsFiltres = main_prog_basique(i,j)
#            write(file, string(i)*"-"*string(j)*"\n")
#            write(file,string(nbEtatsStock)*"-"*string(nbEtatsFiltres)*"\n")
#        end
#    end
#    close(file) 
#end

#function complexiteSpatialeProgDyn2(ind::Int64)
#    file::IOStream = open("nombreEtats/ProgDyn2_$ind.txt", "w")
#    for i in 50:50:500
#        for j in 1:10
#            
#            L0, L1, val, nbEtatsStock, nbEtatsFiltres = test_fichier(i,j)
#            println(i," ",nbEtatsStock," ",nbEtatsFiltres)
#            write(file, string(i)*"-"*string(j)*"\n")
#            write(file,string(nbEtatsStock)*"-"*string(nbEtatsFiltres)*"\n")
#        end
#    end
#    close(file)
#end

function complexiteSpatialePlusLoin(ind::Int64)
    file::IOStream = open("nombreEtats/PlusLoin_$ind.txt", "w")
    for i in 50:50:500
        for j in 1:10
            
            L0, L1, val, nbEtatsStock, nbEtatsFiltres = test_fichierPlusLoin(i,j)
            println(i," ",nbEtatsStock," ",nbEtatsFiltres)
            write(file, string(i)*"-"*string(j)*"\n")
            write(file,string(nbEtatsStock)*"-"*string(nbEtatsFiltres)*"\n")
        end
    end
    close(file)
end
