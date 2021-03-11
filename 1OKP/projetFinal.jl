#Projet Recherche Operationnelle
#Sac a dos
#Jourdan L et Baussay L - mars 2020

#Projet Final : Condensé de tout nos programme pour proposé une implémentation alliant le prétraitement et la programmation dynamique

include("pretraitement.jl")
include("progDynamique_V2.jl")
include("pourAllerPlusLoin.jl")

#Role : On utilise la méthode du triFusion pour créer la liste de Int8 constenant les variables x_i de la modélisation en programme linéaire.
#Préconditions : Les listes L0 et L1 doivent être triés dans l'ordre des Id des objets croissants.
function fusionFinale(L0::Vector{Objet}, L1::Vector{Objet})
    if length(L0) == 0
        return [1 for obj in L1]
    elseif length(L1) == 0
        return [0 for obj in L0]
    else
        if L0[1].id < L1[1].id
            return append!(fusionFinale(L0[2:length(L0)], L1), [0])
        else
            return append!(fusionFinale(L0, L1[2:length(L1)]), [1])
        end
    end
end

#Role : Récupère le prétraitement effectué sur la liste d'objet donnée en paramètre et applique l'algotithme programmation dynamique V2 sur les données
#		restantes.
#Préconcidtion : i, j doivent être dans {50, 100, 150, ..., 500} x {1, 2, ..., 10}
function projetProgDyn(ListObj::Vector{Objet}, poidsMax::Int64, i, j)

	#On récupère tout les résultats du prétraitement
    Res_Pretrait = main_pretrait(i,j)
    poids1::Int64 = 0
    for obj in Res_Pretrait[2]
        poids1 = poids1 + obj.cout
    end

	Var0::Vector{Objet} = Res_Pretrait[1]
	Var1::Vector{Objet} = Res_Pretrait[2]
	profit::Int64 = Res_Pretrait[4]

	#On test si il reste des variables libres ou si on peut directement renvoyer le résultat.
    if length(Res_Pretrait[3]) != 0

		#On appel donc La programmation dynamique V2 et on ajoute ses résultats à ceux obtenus pour le prétraitement
		Res_ProgDyn = main_progDyn0(Res_Pretrait[3], poidsMax - poids1)
		append!(Var0, Res_ProgDyn[1])
		append!(Var1, Res_ProgDyn[2])
		profit += Res_ProgDyn[3]
	end

	#On commence à ranger les objets par leurs places initiales dans la liste d'objet garder dans le paramètre id
    Var0 = triId(Var0)
    Var1 = triId(Var1)

	#On créer donc la liste qui sera renvoyer dans la structure solutionKP
    ListeFinale::Vector{Int8} = fusionFinale(Var0, Var1)

	#On test si notre solution trouver avec la programmation dynamique est meilleure que la borne Inferieur trouvée lors du prétraitement. Si c'est le cas on
	#Renvoie ce résultat sinon on renvoie la borne inf du prétraitement ainsi que les différentes variables fixées à 0 ou 1.
	if Res_Pretrait[7] <= profit
    	return solutionKP(ListeFinale, profit)
	else
		Var0 = triId(Res_Pretrait[5])
		Var1 = triId(Res_Pretrait[6])
		return solutionKP(fusionFinale(Var0, Var1), Res_Pretrait[7])
	end

end
#Role : Execute le programme sur l'instance KP$i-$j.dat
#Précondtions : i doit appartenir à {50, 100, 150, ..., 500} et j à {1, 2, ..., 10}
function test_fichierFinalProgDyn(i::Int64, j::Int64)

	#on recupère les données liées à l'instance KP$i-$j.dat avec le parser
    lien::String = "Instances/KP$i-$j.dat"

    d = parseKP(lien)

    profits::Vector{Int64} = d.p
    poids::Vector{Int64} = d.w

    poidsMax::Int64 = d.Omega

    taille::Int64 = size(poids)[1]

    ListObj::Vector{Objet} = [Objet(profits[i], poids[i], i) for i in 1:taille]

	#On applique la fonction projet qui se charge de faire tout les calculs
    return projetProgDyn(ListObj, poidsMax, i, j)
end

#Role : Récupère le prétraitement effectué sur la liste d'objet donnée en paramètre et applique l'algotithme "pour aller plus loin" sur les données restantes.
#Préconcditions : i, j doivent être dans {50, 100, 150, ..., 500} x {1, 2, ..., 10}
function projetPlusLoin(ListObj::Vector{Objet}, poidsMax::Int64, i, j)

	#On récupère tout les résultats du prétraitement
	Res_Pretrait = main_pretrait(i,j)
    poids1::Int64 = 0
    for obj in Res_Pretrait[2]
        poids1 = poids1 + obj.cout
    end

	Var0::Vector{Objet} = Res_Pretrait[1]
	Var1::Vector{Objet} = Res_Pretrait[2]
	profit::Int64 = Res_Pretrait[4]

	#On test si il reste des variables libres ou si on peut directement renvoyer le résultat.
    if length(Res_Pretrait[3]) != 0

		#On appel donc la partie pour aller plus loin et on ajoute ses résultats à ceux obtenus pour le prétraitement
		Res_ProgDyn = main_progDyn0(Res_Pretrait[3], poidsMax - poids1)
		append!(Var0, Res_ProgDyn[1])
		append!(Var1, Res_ProgDyn[2])
		profit += Res_ProgDyn[3]
	end

	#On commence à ranger les objets par leurs places initiales dans la liste d'objet garder dans le paramètre id
    Var0 = triId(Var0)
    Var1 = triId(Var1)

	#On créer donc la liste qui sera renvoyer dans la structure solutionKP
    ListeFinale::Vector{Int8} = fusionFinale(Var0, Var1)

	#On test si notre solution trouver avec la partie pour aller plus loin est meilleure que la borne Inferieur trouvée lors du prétraitement. Si c'est le cas on
	#Renvoie ce résultat sinon on renvoie la borne inf du prétraitement ainsi que les différentes variables fixées à 0 ou 1.
	if Res_Pretrait[7] <= profit
    	return solutionKP(ListeFinale, profit)
	else
		Var0 = triId(Res_Pretrait[5])
		Var1 = triId(Res_Pretrait[6])
		return solutionKP(fusionFinale(Var0, Var1), Res_Pretrait[7])
	end

end

#Role : Execute le programme sur l'instance KP$i-$j.dat
#Précondtions : i doit appartenir à {50, 100, 150, ..., 500} et j à {1, 2, ..., 10}
function test_fichierFinalPlusLoin(i::Int64, j::Int64)

	#on recupère les données liées à l'instance KP$i-$j.dat avec le parser
    lien::String = "Instances/KP$i-$j.dat"

    d = parseKP(lien)

    profits::Vector{Int64} = d.p
    poids::Vector{Int64} = d.w

    poidsMax::Int64 = d.Omega

    taille::Int64 = length(poids)

    ListObj::Vector{Objet} = [Objet(profits[i], poids[i], i) for i in 1:taille]

	#On applique la fonction projet qui se charge de faire tout les calculs
    return projetPlusLoin(ListObj, poidsMax, i, j)
end

function main1Okp(ListObj::Vector{Objet}, poidsMax::Int64)

	#On récupère tout les résultats du prétraitement
	Res_Pretrait = main_pretrait(ListObj, poidsMax)
    poids1::Int64 = 0
    for obj in Res_Pretrait[2]
        poids1 = poids1 + obj.cout
    end

	Var0::Vector{Objet} = Res_Pretrait[1]
	Var1::Vector{Objet} = Res_Pretrait[2]
	profit::Int64 = Res_Pretrait[4]

	#On test si il reste des variables libres ou si on peut directement renvoyer le résultat.
    if length(Res_Pretrait[3]) != 0

		#On appel donc la partie pour aller plus loin et on ajoute ses résultats à ceux obtenus pour le prétraitement
		Res_ProgDyn = main_progDyn0(Res_Pretrait[3], poidsMax - poids1)
		append!(Var0, Res_ProgDyn[1])
		append!(Var1, Res_ProgDyn[2])
		profit += Res_ProgDyn[3]
	end

	#On commence à ranger les objets par leurs places initiales dans la liste d'objet garder dans le paramètre id
    Var0 = triId(Var0)
    Var1 = triId(Var1)

	#On créer donc la liste qui sera renvoyer dans la structure solutionKP
    ListeFinale::Vector{Int8} = fusionFinale(Var0, Var1)

	#On test si notre solution trouver avec la partie pour aller plus loin est meilleure que la borne Inferieur trouvée lors du prétraitement. Si c'est le cas on
	#Renvoie ce résultat sinon on renvoie la borne inf du prétraitement ainsi que les différentes variables fixées à 0 ou 1.
	if Res_Pretrait[7] <= profit
    	return solutionKP(ListeFinale, profit)
	else
		Var0 = triId(Res_Pretrait[5])
		Var1 = triId(Res_Pretrait[6])
		return solutionKP(fusionFinale(Var0, Var1), Res_Pretrait[7])
	end

end
