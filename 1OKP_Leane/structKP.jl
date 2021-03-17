
# Baussay Lucas, Jourdan Léane #

#= *****************************
Structures de données et parseur
***************************** =#

# Structure contenant les données du problème
mutable struct dataKP
	p::Vector{Int64} # Vecteur des profits des objets
	w::Vector{Int64} # Vecteur des poids des objets
	n::Int64 # Nombre d'objets
	Omega::Int64 # Capacité du sac
end

# Structure correspondant à une solution du problème
mutable struct solutionKP
	X::Vector{Int8} # Vecteur des variables
	z::Int64 # Valeur de la fonction objectif
end

# Structure correspondant à un état dans la version la plus basique de l'algorithme
mutable struct etat
	z::Int64
	omega::Int64
	prec::Union{etat,Nothing}
end
#= Pour rappel, les variables d'un type structuré en Julia sont en réalité des références sur une structure.
   Le type Nothing ne contient qu'une valeur : nothing qui joue le rôle de NULL (ou Nil) dans d'autres langages.
   Cette valeur est nécessaire pour spécifier que l'état initial n'a pas de prédécesseur.
   Lorsqu'on charge plusieurs fois de suite un même fichier, les structures de données et fonctions dont le nom n'est pas changé sont écrasés.
   Cela est interdit dans le cas des structures de données récursives en Julia, ce qui peut être pénible quand on fait des modifications de code.
   Pour cette raison, il est recommandé de charger ce fichier contenant les structures et le parseur une seule fois.
   Le reste de votre code pourra être écrit dans un autre fichier que vous pourrez recharger de manière répétée. =#

#= Autres structures de données
	.
	.
	.
	=#

struct Objet
	profit::Union{Int64, Nothing}
	#cout=poids
	cout::Union{Int64, Nothing}
	id::Union{Int64, Nothing}
	ratio::Union{Float64, Nothing}
	
	#Constructeur classique via tout ses paramètres
	function Objet(profit, cout, id)
		new(profit, cout, id, profit/cout)
	end

	#Constructeur vide : Créer un objet vide, utilisé notamment pour faire de l'inférence de type (Forcer un paramètre à être un OBjet)
	function Objet()
		new(nothing, nothing, nothing, nothing)
	end
end

mutable struct Etat
	
	pere::Union{Etat, Nothing}
	prendPere::Union{Bool, Nothing}
	k::Int64
	c::Int64
	d::Int64

	#Constructeur classique avec touts les paramètres
	function Etat(p::Etat, niveau::Int64, profit::Int64, poids::Int64, prend::Bool)
		new(p, prend, niveau, profit, poids)
	end

	#Constructeur vide : Créer l'état vide, le tout premier du tableau
	function Etat()
		new(nothing, nothing, 1, 0, 0)
	end

	#Constructeur nouvel etat a partir du parent si l'objet n'est PAS pris
	function Etat(parent::Etat)
		new(parent, false, parent.k+1, parent.c, parent.d)
	end

	#Constructeur nouvel etat a partir du parent si l'objet est pris
	function Etat(parent::Etat, nouvelObjet::Objet)
		new(parent, true, parent.k+1, parent.c + nouvelObjet.profit, parent.d + nouvelObjet.cout)
	end
end


	


function parseKP(filename::String)
	f::IOStream = open(filename,"r")

    # Première ligne : taille du problème (nombre d'objets)
    s::String = readline(f)
    tab::Vector{Int64} = parse.(Int64,split(s," ",keepempty = false))
    @inbounds n::Int64 = tab[1]

	# Deuxième ligne : capacité du sac à dos
    s = readline(f)
	tab = parse.(Int64,split(s," ",keepempty = false))
	@inbounds Omega::Int64 = tab[1]

	# Troisième ligne : profits des objets
    s = readline(f)
	p::Vector{Int64} = parse.(Int64,split(s," ",keepempty = false))

	# Quatrième ligne : poids des objets
    s = readline(f)
	w::Vector{Int64} = parse.(Int64,split(s," ",keepempty = false))

    # End
    close(f)

    return dataKP(p,w,n,Omega)
end


#= En commentaire ci-dessous, un exemple de script pour résoudre toutes les instances
   La macro @time a pour but de mesurer le temps CPU de l'appel
   Pour une mesure correcte, il faut s'assurer que l'ensemble des cas possibles pour la fonction ont déjà été exécutés
   (La compilation de chaque portion de code est réalisée à la première exécution)

function scriptKP()
	for i in 50:50:500
		for j in 1:10
			d = parseKP("Instances/KP$i-$j.dat")
			@time retour1, retour2, retour 3 = monImplementationDeFeu(d)
		end
	end
end

=#
