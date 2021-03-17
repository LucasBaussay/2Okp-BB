#Projet Recherche Operationnelle
#Sac a dos
#Jourdan L et Baussay L - mars 2020

#Algorithme de programmation dynamique basique

#Role: renvoie l'état ayant le plus grand profit cumulé de la liste donné
#Preconditions: L non vide
function recupMax(L::Vector{Etat})
    #Un algorithme de recherche de maximum mais sur un paramètre de la structure Etat.
    etatMax::Etat = L[1]
    for etat in L
        if etatMax.c<etat.c
            etatMax = etat
        end
    end
    return etatMax
end

#Role : renvoie le chemin entre l'état initial du tableau (1,0,0) et ce même état
#Preconditions: etat doit appartenir au tableau créé avec la Liste d'objet
function recupChemin(etat::Etat)
    L::Vector{Bool} = []
    etatTmp::Etat = etat
    while etatTmp.k > 1
        #A chaque fois on regarde si on prend l'objet relatif à l'État du père ou non, on renvoie ainsi une liste de booléen.
        L = append!(L, [etatTmp.prendPere])
        #Le père de notre état devient l'état étudié et on recommence jusqu'à ce que le pere de notre état soit l'état initial.
        etatTmp = etatTmp.pere
    end
    return reverse!(L)
end
   
#Role: Renvoie vrai si l'état 2 est dominé par l'état 1 et qu'ils sont différents
#Preconditions: etat1 et etat2 doivent être initialisés avec leur variable c non vide
function domine(etat1::Etat, etat2::Etat)
    return ((etat1.c >= etat2.c) && (etat1.d <= etat2.d) && etat1 != etat2)
end

#Role: renvoie la nouvelle colonne d'etats du tableau en fonction de l'ancienne
#Preconditions: L doit être non vide
function Nouveaux_Etat(L::Vector{Etat}, obj::Objet, poidsMax::Int64)


    #La nouvelle colonne sans avoir fait le test de lominance
    resTmp::Vector{Etat} = []

    #La nouvelle colonne après avoir fait tout les tests de dominance
    res::Vector{Etat} = []
    
    for etats in L
        #Pour chacun des états de l'ancienne colonne on ajoute 2 nouveaux états, l'état avec et l'état sans.
        resTmp = append!(resTmp, [Etat(etats, etats.k +1, etats.c, etats.d, false), Etat(etats, etats.k+1, etats.c+obj.profit, etats.d+obj.cout, true)])
    end

    #Pour chacun des nouveaux états créés
    for etats in resTmp
        #Ce booléen correspond à : true -> On ajoute effectivement cet états à notre nouvel liste d'état , false -> on le supprime (ex : dominance, partie "Pour aller plus loin")
        estAdd::Bool = true

        

        if etats.d<=poidsMax
            #On regarde ici notre état est dominé par un autre état différent de lui même, si oui estAdd = false sinon il rest à true
            for etats2 in resTmp
                estAdd = estAdd && !(domine(etats2, etats))

            end

            #On regarde ici si le poids cumulé associé à notre état est plus grand que la capacité du sac, si c'est le cas l'état est supprimé sinon il est laissé tel quel.
            if estAdd
                res = append!([etats], res)
            end

        end
    end


    return res
end

#Role: fonction principale de la création de la structure de données, renvoie le graph du sujet.
#Préconditions: ListObj non vide.
function creationTab(ListObj::Vector{Objet}, poidsMax::Int64)
    nbObjet::Int64 = length(ListObj)

    #On initialise le tableau avec L'état initial : (1,0,0)
    T = Vector{Vector{Etat}}(undef, nbObjet+1)
    T[1] = [Etat()]
    
    #On calcule chaque nouvelle colonne du tableau par rapport à la précedente, à l'objet que l'on prend ou non et à la capacité max du sac.
    for i in 2:(nbObjet+1)
        T[i]= Nouveaux_Etat(T[i-1], ListObj[i-1], poidsMax::Int64)
        
    end

    return T
end

#Role: Renvoie la liste des variables xi (1 si l'objet est pris dans le sac,0 sinon) et le profit cumulé de la solution optimale du problème.
#Preconditions: i appartient à {50, 100, ..., 500} et j appartient à {1, 2, ..., 10}
function main_prog_basique(i::Int64=50, j::Int64=1)
    lien::String = "Instances/KP$i-$j.dat"
    
    d = parseKP(lien)

    profits::Vector{Int64} = d.p
    poids::Vector{Int64} = d.w

    poidMax::Int64 = d.Omega

    taille::Int64 = size(poids)[1]

    #Création de la liste des objets avec pour chaque leur profits, poids, et un identifiant unique
    ListObj::Vector{Objet} = [Objet(profits[i], poids[i], i) for i in 1:taille]

    #T correspond au graph du sujet, il contient ainsi des liste d'États.
    T::Vector{Vector{Etat}}= creationTab(ListObj, poidMax)

    #On récupère l'état possedant le profit cumulé le plus grand sur la dernières colonne.
    etatOpt::Etat = recupMax(T[length(T)])

    #L récupère simplement le chemin depuis l'état optimal de la dernière colonne vers l'état 1,0,0 en regardant si on prend chaque objet ou non.
    L::Vector{Bool} = recupChemin(etatOpt)

    return L,etatOpt.c
end

