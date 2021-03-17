#using PyPlot


function Lecture(str::String)
    file::IOStream = open(str, "r")
    L::Vector{Vector{Float64}} = [Vector{Float64}(undef, 10) for i in 1:10]
    for i in 1:100
        s=readline(file)
        tab::Vector{Int64} = parse.(Int64,split(s,"-",keepempty = false))
        @inbounds n::Int64, k::Int64 = tab[1], tab[2]
        s=readline(file)
        tab2::Vector{Float64} = parse.(Float64,split(s," ",keepempty = false))
        newN::Float64 = n/50
        n = Int64(floor(newN))
        L[n][k] = @inbounds tab2[1]
    end
    return L
end

function affichage(str::String)
	L = Lecture(str)
	Lbis = [moyenne(l) for l in L]
	plot(50:50:500, Lbis, "b")
	xlabel("Nombre d'objets")
	ylabel("Temps (en sec)")
	title("Temps moyen d'exécution en fonction du nombre d'objets")
	grid()
	end

function affichage2(str1::String, str2::String, nomLeg1::String, nomLeg2::String, col1::String, col2::String)
	L1 = Lecture(str1)
	L2 = Lecture(str2)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Temps (en sec)")
	title("Temps moyen d'execution en fonction du nombre d'objets")
	grid()
end

function affichage3(str1::String, str2::String, str3::String, nomLeg1::String, nomLeg2::String, nomLeg3::String, col1::String, col2::String, col3::String)
	L1 = Lecture(str1)
	L2 = Lecture(str2)
	L3 = Lecture(str3)
	L1 = [moyenne(l) for l in L1]
	L2 = [moyenne(l) for l in L2] 
	L3 = [moyenne(l) for l in L3]
	g1 = plot(50:50:500, L1, col1, label = nomLeg1)
	g2 = plot(50:50:500, L2, col2, label = nomLeg2)
	g3 = plot(50:50:500, L2, col3, label = nomLeg3)
	legend(loc="upper left")
	xlabel("Nombre d'objets")
	ylabel("Temps (en sec)")
	title("Temps moyen d'execution en fonction du nombre d'objets")
	grid()
end

function affichage4(str1::String, str2::String, str3::String, str4::String, nomLeg1::String, nomLeg2::String, nomLeg3::String, nomLeg4::String, col1::String, col2::String, col3::String, col4::String)
	L1 = Lecture(str1)
	L2 = Lecture(str2)
	L3 = Lecture(str3)
	L4 = Lecture(str4)
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
	ylabel("Temps (en sec)")
	title("Temps moyen d'execution en fonction du nombre d'objets")
	grid()
end

function moyenne(L::Vector{Float64})
	return somme(L)/length(L)
end

function somme(L::Vector{Float64})
	som = 0
	for i in L
		som += i
	end
	return som
end
