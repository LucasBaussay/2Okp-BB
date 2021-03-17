function Ecriture(ind::Int64)
    file::IOStream = open("TestAffichage/affichage_$ind.txt", "w")
    for i in 50:50:500
        for j in 1:10
			val, t, bytes, gctime, memallocs = @timed testFichier(i,j)
            write(file, string(i)*"-"*string(j)*"\n")
            write(file, string(gctime)*"\n")
        end
    end
    close(file) 
end
