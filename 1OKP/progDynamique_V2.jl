
#Projet Recherche Operationnelle
#Sac a dos
#Jourdan L et Baussay L - mars 2020

#Partie 3.3 Algorithme de programmation dynamique un peu moins basique

#C'est l'algorithme de programmation dynamique que nous allons utiliser dans la suite du projet pour résoudre le problème du Sac à dos.

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
function recupChemin(etat::Etat, ListObjet::Vector{Objet})

    #Initialisation de la liste des objets pris (L1) et celle des objets non pris (L0)
    L1::Vector{Objet} = []
    L0::Vector{Objet} = []
    etatTmp::Etat = etat

    #A chaque fois on regarde si on prend l'objet relatif à l'État du père ou non, on renvoie ainsi 2 listes d'objets.
    while etatTmp.k > 1
        if etatTmp.prendPere
            append!(L1, [ListObjet[etatTmp.k-1]])
        else
            append!(L0, [ListObjet[etatTmp.k-1]])
        end
        etatTmp = etatTmp.pere
    end
    return L0, L1
end

#Role: Retourne le poids cumulé de tout les objets dont l'indice est superieur à celui passé en paramètre. 
#Preconditions: |listeObjets|>=indice
function calculPoidsObjetsRestants(listeObjets::Vector{Objet}, indice::Int64)
    #Initialisation du paramètre renvoyé
    sommePoids::Int64=0

    #Incrémentation de paramètre
    for i in indice:length(listeObjets)
        sommePoids= sommePoids+(listeObjets[i]).cout
    end
    return sommePoids
end

#Role: renvoie vrai si l'état 2 domine l'état 1
#Preconditions: etat1 et etat2 doivent être initialisés avec leur variable c non vide
function est_domine(etat1::Etat, etat2::Etat)
    return (etat2.c >= etat1.c)
end

#Role: renvoie la nouvelle colonne du tableau en fonction de l'ancienne
#Preconditions: colonne_prec doit être non vide
function colonne_suivante(colonne_prec::Vector{Etat}, nouvelObjet::Objet, poidsMax::Int64, poidsObjetsRestants::Int64)
   
    #Résultat du programme :la nouvelle colonne d'état
    nouvelleColonne::Vector{Etat}=[]

    #Initialisation des deux itérateurs avec et sans.
    sans::Int64=1
    avec::Int64=1

    #Initialisation des variables utiles par la suite
    etatCourantAvec::Etat = Etat()
    parentCourantAvec::Etat=Etat()

    parentCourantSans::Etat=Etat()
    etatCourantSans::Etat= Etat() 

    #Taille de la nouvelle colonne
    tailleActuelle::Int64=length(nouvelleColonne)
    
    #On calcule un nouvel état à la fois tant que l'un des itérateurs n'est pas arrivé au bout de la colonne précedente
    while sans<=length(colonne_prec) && avec<=length(colonne_prec)
        
        #On récupère l'état sur lequel se trouve l'itérateur sans
        parentCourantSans=colonne_prec[sans]
        #On créé le nouvel état découlant de l'itérateur sans grâce aux informations du parent
        etatCourantSans= Etat(parentCourantSans)
        
        #Si on peut rentrer tout les objets restants dans le sac alors l'iterateur sans n'est ici pas utile et on le passe à 
        #l'état suivant.
        if parentCourantSans.d+poidsObjetsRestants <= poidsMax
            sans=sans+1

        else
            #On récupère l'état sur lequel se trouve l'itérateur sans
            parentCourantAvec=colonne_prec[avec]
            #On créé le nouvel état découlant de l'itérateur avec grâce aux informations du parent et de l'objet ajouté
            etatCourantAvec = Etat(parentCourantAvec,nouvelObjet)

            tailleActuelle=length(nouvelleColonne)

            # On choisit lequel des deux itérateurs va créer un nouvel état en comparant leur poids cumulé
            if etatCourantSans.d <= etatCourantAvec.d
                #Cas 1: l'iterateur sans à le poids cumulé le plus faible                               
                #On regarde si on peut mettre l'état dans la nouvelle colonne (dominance)
                if tailleActuelle==0 || !(est_domine(etatCourantSans,nouvelleColonne[tailleActuelle]))
                    append!(nouvelleColonne, [etatCourantSans])
                end
                #On incrémente l'itérateur
                sans= sans+1
            else
                #Cas 2: l'iterateur avec à le poids cumulé le plus faible
                #On regarde si on peut mettre l'état dans la nouvelle colonne (dominance)
                if etatCourantAvec.d<=poidsMax && (tailleActuelle==0 || !(est_domine(etatCourantAvec,nouvelleColonne[tailleActuelle])))
                    append!(nouvelleColonne, [etatCourantAvec])
                end
                #On incrémente l'itérateur
                avec=avec+1
            end
        end
    end

    #On complète la nouvelle colonne en créant les états manquant (issus de l'itérateur n'ayant pas fini son parcours)
    #On regarde quel itérateur n'a pas fini son parcours
    if sans <= length(colonne_prec) && avec > length(colonne_prec)
        while sans <=length(colonne_prec)
            parentCourantSans=colonne_prec[sans]
            etatCourantSans= Etat(parentCourantSans)
    
            tailleActuelle=length(nouvelleColonne)
            if tailleActuelle==0 || !(est_domine(etatCourantSans,nouvelleColonne[tailleActuelle]))
                append!(nouvelleColonne, [etatCourantSans])
            end 
            sans= sans+1
        end
    elseif sans > length(colonne_prec) && avec <= length(colonne_prec)
        while avec <= length(colonne_prec)
            parentCourantAvec=colonne_prec[avec]
            etatCourantAvec = Etat(parentCourantAvec,nouvelObjet)
            
            tailleActuelle=length(nouvelleColonne)
            if etatCourantAvec.d<=poidsMax && (tailleActuelle==0 || !(est_domine(etatCourantAvec,nouvelleColonne[tailleActuelle])))
                append!(nouvelleColonne, [etatCourantAvec])
            end
            avec=avec+1
        end
    end
    return nouvelleColonne
end


#Role: fonction principale de la création de la structure de données, renvoie le graph du sujet.
#Préconditions: ListObj non vide.
function creationTab(ListObj::Vector{Objet}, poidsMax::Int64)
    nbObjet::Int64 = length(ListObj)

    #On initialise le tableau avec l'état initial : (1,0,0)
    T = Vector{Vector{Etat}}(undef, nbObjet+1)
    T[1] = [Etat()]

    #On calcule chaque nouvelle colonne du tableau par rapport à la précedente, à l'objet que l'on prend ou non et à la capacité max du sac,
    #ainsi que le poids total de tout les objets n'ayant pas été étudiés.
    for i in 2:(nbObjet+1)

        T[i] = colonne_suivante(T[i-1], ListObj[i-1], poidsMax, calculPoidsObjetsRestants(ListObj, i-1))
    
    end
   
    return T
end

#Role: Renvoie la liste des variables misent à 0, celles misent à 1 et le profit cumulé de la solution optimale du problème.
#Préconditions:|ListObj|>0
function main_progDyn0(ListObj::Vector{Objet}, poidsMax::Int64)
    
    #T correspond au graph du sujet, il contient ainsi des liste d'États.
    T::Vector{Vector{Etat}}= creationTab(ListObj, poidsMax)

    #On récupère l'état possedant le profit cumulé le plus grand sur la dernière colonne.
    etatOpt::Etat = recupMax(T[length(T)])

    #L0 récupère simplement les variables à 0 et L1 les variables à 1 sur le chemin depuis l'état optimal de la dernière colonne vers l'état 1,0,0 
    #en regardant si on prend chaque objet ou non.
    L0::Vector{Objet}, L1::Vector{Objet} = recupChemin(etatOpt, ListObj)

    return L0, L1, etatOpt.c
end

#Role: Ajout pour pouvoir appliquer l'algo de programmation dynamique sur les instances fournies.
#Preconditions: i appartient à {50, 100, ..., 500} et j appartient à {1, 2, ..., 10}
function test_fichier0(i,j)
    #D'après le parser fournit dans structKP
    lien::String = "Instances/KP$i-$j.dat"
    
    d = parseKP(lien)

    profits::Vector{Int64} = d.p
    poids::Vector{Int64} = d.w

    poidMax::Int64 = d.Omega

    taille::Int64 = size(poids)[1]

    ListObj::Vector{Objet} = [Objet(profits[i], poids[i], i) for i in 1:taille]

    return main_progDyn0(ListObj, poidMax)
end

#Role: Renvoie la liste des variables misent à 0, celles misent à 1 et le profit cumulé de la solution optimale du problème.
#Préconditions:|ListObj|>0
function main_progDyn(ListObj::Vector{Objet}, poidsMax::Int64)
    
    L0, L1, profitsCumulé = main_progDyn0(ListObj, poidsMax)
	
	ListeFinale::Vector{Int8} = Vector{Int8}(undef, length(ListObj))
	for obj in L0
		ListeFinale[obj.id] = 0
	end
	for obj in L1
		ListeFinale[obj.id] = 1
	end

	return solutionKP(ListeFinale, profitsCumulé)
end

#Role: Ajout pour pouvoir appliquer l'algo de programmation dynamique sur les instances fournies.
#Preconditions: i appartient à {50, 100, ..., 500} et j appartient à {1, 2, ..., 10}
function test_fichier(i,j)
    #D'après le parser fournit dans structKP
    lien::String = "Instances/KP$i-$j.dat"
    
    d = parseKP(lien)

    profits::Vector{Int64} = d.p
    poids::Vector{Int64} = d.w

    poidMax::Int64 = d.Omega

    taille::Int64 = size(poids)[1]

    ListObj::Vector{Objet} = [Objet(profits[i], poids[i], i) for i in 1:taille]

    return main_progDyn(ListObj, poidMax)
end
