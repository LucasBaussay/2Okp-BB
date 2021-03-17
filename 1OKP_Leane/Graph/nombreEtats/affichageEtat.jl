using PyPlot


function Lecture(str::String)
    file::IOStream = open(str, "r")
	Lstocké::Vector{Vector{Int64}} = [Vector{Int64}(undef, 10) for i in 1:10]
    Lfiltré::Vector{Vector{Int64}} = [Vector{Int64}(undef, 10) for i in 1:10]
    for i in 1:100
        s=readline(file)
        tab::Vector{Int64} = parse.(Int64,split(s,"-",keepempty = false))
        @inbounds n::Int64, k::Int64 = tab[1], tab[2]
        s=readline(file)
        tab2::Vector{Int64} = parse.(Int64,split(s,"-",keepempty = false))
        newN::Float64 = n/50
        n = Int64(floor(newN))
        Lstocké[n][k] = @inbounds tab2[1]
		Lfiltré[n][k] = @inbounds tab2[2]
    end
    return Lstocké, Lfiltré
end

function affichageStocké(str::String, col1::String, nomLeg1::String)
	L, inutil = Lecture(str)
	Lbis = [moyenne(l) for l in L]
	plot(50:50:500, Lbis, col1, label = nomLeg1)
	legend(loc = "upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen stocké/filtrés par nombre d'objet du problème")
	grid()
	end

function affichage2Stocké(str1::String, str2::String, nomLeg1::String, nomLeg2::String, col1::String, col2::String)
	L1, nul1 = Lecture(str1)
	nul2, L2 = Lecture(str2)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen stocké/filtrés par nombre d'objet du problème")
	grid()
end

function affichage3Stocké(str1::String, str2::String, str3::String, nomLeg1::String, nomLeg2::String, nomLeg3::String, col1::String, col2::String, col3::String)
	L1, nul1 = Lecture(str1)
	L2, nul2 = Lecture(str2)
	L3, nul3 = Lecture(str3)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	L3 = [moyenne(l) for l in L3]
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	g3 = plot(50:50:500, L3, col3, label = nomLeg3)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen stocké par nombre d'objet du problème")
	grid()
end

function affichage4Stocké(str1::String, str2::String, str3::String, str4::String, nomLeg1::String, nomLeg2::String, nomLeg3::String, nomLeg4::String, col1::String, col2::String, col3::String, col4::String)
	L1, nul1 = Lecture(str1)
	L2, nul2 = Lecture(str2)
	L3, nul3 = Lecture(str3)
	L4, nul4 = Lecture(str4)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	L3 = [moyenne(l) for l in L3]
	L4 = [moyenne(l) for l in L4]
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	g3 = plot(50:50:500, L3, col3, label = nomLeg3)
	g4 = plot(50:50:500, L4, col4, label = nomLeg4)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen stocké/filtrés par nombre d'objet du problème")
	grid()
end

function affichageFiltré(str::String, col1::String, nomLeg1::String)
	inutil, L = Lecture(str)
	Lbis = [moyenne(l) for l in L]
	plot(50:50:500, Lbis, col1, nomLeg1)
	legend(loc = "upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen stocké/filtrés par nombre d'objet du problème")
	grid()
	end

function affichage2Filtré(str1::String, str2::String, nomLeg1::String, nomLeg2::String, col1::String, col2::String)
	nul1, L1 = Lecture(str1)
	nul2, L2 = Lecture(str2)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen stocké/filtrés par nombre d'objet du problème")
	grid()
end

function affichage3Filtré(str1::String, str2::String, str3::String, nomLeg1::String, nomLeg2::String, nomLeg3::String, col1::String, col2::String, col3::String)
	nul1, L1 = Lecture(str1)
	nul2, L2 = Lecture(str2)
	nul3, L3 = Lecture(str3)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	L3 = [moyenne(l) for l in L3]
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	g3 = plot(50:50:500, L3, col3, label = nomLeg3)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen filtré par nombre d'objet du problème")
	grid()
end

function affichage4Filtré(str1::String, str2::String, str3::String, str4::String, nomLeg1::String, nomLeg2::String, nomLeg3::String, nomLeg4::String, col1::String, col2::String, col3::String, col4::String)
	nul1, L1 = Lecture(str1)
	nul2, L2 = Lecture(str2)
	nul3, L3 = Lecture(str3)
	nul4, L4 = Lecture(str4)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	L3 = [moyenne(l) for l in L3]
	L4 = [moyenne(l) for l in L4]
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	g3 = plot(50:50:500, L3, col3, label = nomLeg3)
	g4 = plot(50:50:500, L4, col4, label = nomLeg4)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Nombre d'état")
	title("Nombre d'état moyen stocké/filtrés par nombre d'objet du problème")
	grid()
end

function moyenne(L::Vector{Int64})
	return somme(L)/length(L)
end

function somme(L::Vector{Int64})
	som = 0
	for i in L
		som += i
	end
	return som
end
