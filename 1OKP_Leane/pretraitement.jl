
#Projet Recherche Operationnelle
#Sac a dos
#Jourdan L et Baussay L - mars 2020

#Partie 4 Prétraitement


#voir la fonction triFusion() ci dessous
function fusion(L1::Vector{Objet}, L2::Vector{Objet})
    if length(L1) == 0
        return L2
    elseif length(L2) == 0
        return L1
    elseif L1[1].ratio > L2[1].ratio
        return append!([L1[1]], fusion( L1[2:length(L1)], L2))
    else
        return append!([L2[1]], fusion(L1, L2[2:length(L2)]))
    end
end

#Role: Renvoie la liste d'objets L triée de façon décroissante par ratio profit/poids, en suivant une méthode récursive de tri fusion
function triFusion(L::Vector{Objet})
    if length(L)<=1
        return L
    else
        lim::Int64 = floor(length(L)/2)
        return fusion(triFusion(L[1:lim]), triFusion(L[lim+1:length(L)]))
    end
end

#Role: Retourne la somme du poids des objets du sac
#Préconditions: Aucune
function sommePoidsObjets(listeObjets::Vector{Objet})
    accumulateur::Int64=0
    for ind in 1:length(listeObjets)
        accumulateur=accumulateur+listeObjets[ind].cout
    end
    return accumulateur
end

#Role: Retourne la somme du poids des objets du sac
#Préconditions: Aucune
function sommeProfitObjets(listeObjets::Vector{Objet})
    accumulateur::Int64=0
    for ind in 1:length(listeObjets)
        accumulateur=accumulateur+listeObjets[ind].profit
    end
    return accumulateur
end

#Role: Renvoie l'indice de l'objet cassé, la place occupé par la solution Dantzig et le profit généré par la solution Dantzig
#Preconditions: |listeObjets|>0, listeObjets triée par ratio profit/poids décroissant,
#               la somme des objets de la liste doit être strictement supérieure au poids max
function solutionDantzig(listeObjets::Vector{Objet}, poidsMax::Int64)

    #Somme des poids des objets de la solution Dantzig
    if length(listeObjets) != 0
        somme::Int64 = listeObjets[1].cout

        #Iterateurs pour le while
        indObjetCourant = 1
        ObjetCourant::Objet = listeObjets[indObjetCourant]

        #Somme des profits des objets de la solution Dantzig
        dantzig::Int64 = ObjetCourant.profit

        #Recherche de l'objet cassé
        while somme <= poidsMax && indObjetCourant < length(listeObjets)

            indObjetCourant = indObjetCourant +1
            ObjetCourant = listeObjets[indObjetCourant]
            somme = somme + ObjetCourant.cout
            dantzig = dantzig + ObjetCourant.profit

        end

        #A la sortie de la boucle indObjetCourant est l'indice de l'objet casse
        somme = somme-ObjetCourant.cout #place prise par les objets dans le sac
        dantzig = dantzig - ObjetCourant.profit #valeur de la solution dantzig
    else
        indObjetCourant = 0
        somme = 0
        dantzig = 0
    end

    return indObjetCourant, somme , dantzig
end

#Role: Renvoie l'objet cassé, la valeur de la borne inf (profit) calculée par la méthode de l'algo glouton, la capacité résiduelle, la liste des objet non pris et la liste des objets pris
#Preconditions: |L|>0, L triée par ratio profit/poids décroissant
function borneInfAlgoGlouton(L::Vector{Objet}, poidsMax::Int64)

    #A partir de la liste d'objets et du poids max on récupère les caractéristiques de la solution Dantzig
    indObjetCasse::Int64,poidsOccupe::Int64,valeurDantzig::Int64=solutionDantzig(L, poidsMax)

    #Somme des poids des objets de la solution gloutonne
    somme::Int64 = poidsOccupe

    #Somme des profits des objets de la solution gloutonne
    BorneInf::Int64 = valeurDantzig

    #Liste des objets pris
    listeVar1::Vector{Objet} = []

    #Liste des objets non pris
    listeVar0::Vector{Objet} = []

    #Conséquence de la solution Dantzig, on prend les objets situés avant l'objet cassé
    for ind in 1:(indObjetCasse-1)
        append!(listeVar1,[L[ind]])
    end

    #On ne prend pas l'objet cassé
    push!(listeVar0,L[indObjetCasse])

    #Pour les objets suivant si ils peuvent être ajoutés dans le sac on le fait et on les ajoutent à listeVar1 sinon on les ajoutent à listeVar0
    for ind in indObjetCasse+1:length(L)

        if somme+L[ind].cout<=poidsMax
            somme = somme + L[ind].cout
            BorneInf = BorneInf+L[ind].profit
            append!(listeVar1,[L[ind]])
        else
            append!(listeVar0,[L[ind]])
        end
    end

    return L[indObjetCasse], BorneInf, (poidsMax-somme), listeVar0, listeVar1
end

#Role: Renvoie la valeur de U0 et U1 suivant les formules données dans le sujet
#Préconditions: |L|>=indObjetCasse, indObjetCasse!=0, ObjetCasse=L(indObjetCasse)
function calculBornesSup(L::Vector{Objet}, ObjCasse::Objet, indObjCasse::Int64, valDantzig::Int64, capaResi::Int64)
    if indObjCasse==length(L)
        U0=valDantzig
    else
        U0 = valDantzig + floor(capaResi * L[indObjCasse+1].profit/L[indObjCasse+1].cout)
    end
    if indObjCasse==1
        U1=ObjCasse.profit
    else
        U1 = valDantzig + floor(ObjCasse.profit - (ObjCasse.cout - capaResi) * L[indObjCasse-1].profit/L[indObjCasse-1].cout)
    end

    return U0, U1
end

#Role: Retourne UB le maximum de U0 et U1
function UB(U0::Int64,U1::Int64)
    return max(U0,U1)
end

#Role: Renvoie la valeur de UB0(i) , i correspond à indObjetAEnlever
#Préconditions: |listeObjets|>=indObjetAEnlever et |listeObjets|>=indObjetCasse et placeOccupeDantzig<=poidsMax
function calculUB0(UB::Int64,U1::Int64,listeObjets::Vector{Objet}, indObjetAEnlever::Int64, indObjetCasse::Int64,placeOccupeDantzig::Int64,valDantzig::Int64,poidsMax::Int64)

    nombreObjets= length(listeObjets)

    #On calcule la capacité résiduelle du sac
    capaciteResiduelle::Int64=poidsMax-placeOccupeDantzig

    #Déclaration et initialisation de variables utiles par la suite
    nouvelleValDantzig::Int64=0
    nouvellePlaceOccupeDantzig::Int64=0
    indNouvelObjetCasse::Int64=0
    nouvelObjetCasse::Objet=Objet()
    nouveauU0::Int64=0
    nouveauU1::Int64=0
    nouvelleCapaciteResiduelle::Int64=0


    #On suit la méthode et les différents cas données dans le sujet

    #Cas 1: i<=s-1
    if indObjetAEnlever<=(indObjetCasse-1)

        objetEnleve::Objet=listeObjets[indObjetAEnlever]

        #On enleve l'objet de la solution initiale
        nouvelleValDantzig = valDantzig - objetEnleve.profit
        nouvellePlaceOccupeDantzig = placeOccupeDantzig - objetEnleve.cout

        #Phase 1:Recherche du nouvel objet casse

        #Initialisation de l'itérateur
        indNouvelObjetCasse=indObjetCasse-1


        while nouvellePlaceOccupeDantzig<=poidsMax && indNouvelObjetCasse<nombreObjets

            indNouvelObjetCasse= indNouvelObjetCasse+1

            nouvellePlaceOccupeDantzig=nouvellePlaceOccupeDantzig + listeObjets[indNouvelObjetCasse].cout
            nouvelleValDantzig=nouvelleValDantzig + listeObjets[indNouvelObjetCasse].profit

        end

        #On enleve l'objet cassé de la solution trouvé pour qu'elle soit inférieur au poidsMax
        nouvellePlaceOccupeDantzig=nouvellePlaceOccupeDantzig - listeObjets[indNouvelObjetCasse].cout
        nouvelleValDantzig=nouvelleValDantzig - listeObjets[indNouvelObjetCasse].profit

        #Mise à jour de l'objet cassé
        nouvelObjetCasse=listeObjets[indNouvelObjetCasse]
        #Mise à jour de la capacité résiduelle
        nouvelleCapaciteResiduelle= poidsMax - nouvellePlaceOccupeDantzig

        #Phase 2:Calcul de la nouvelle borne

        #Calcul de la nouvelle valeur de U0
        if indNouvelObjetCasse==nombreObjets
            nouveauU0= nouvelleValDantzig
        else
            nouveauU0= nouvelleValDantzig + floor(nouvelleCapaciteResiduelle * listeObjets[indNouvelObjetCasse+1].profit/listeObjets[indNouvelObjetCasse+1].cout)
        end

        #Calcul de la nouvelle valeur de U1
        #indNouvelObjetCasse>=s et s>1 (car i<=s-1)
        nouveauU1= nouvelleValDantzig + floor(nouvelObjetCasse.profit - (nouvelObjetCasse.cout - nouvelleCapaciteResiduelle)*listeObjets[indNouvelObjetCasse-1].profit/listeObjets[indNouvelObjetCasse-1].cout)

        return max(nouveauU0,nouveauU1)

    #Cas 2: i=s
    elseif indObjetAEnlever==indObjetCasse
        if indObjetCasse==nombreObjets
            return UB
        else
            #Phase 1:Recherche du nouvel objet casse

            sommePoidsObjetsRestants=sommePoidsObjets(listeObjets)-listeObjets[indObjetCasse].cout
            if sommePoidsObjetsRestants<=poidsMax

                sommeProfitObjetsRestants=sommeProfitObjets(listeObjets)-listeObjets[indObjetCasse].profit
                return sommeProfitObjetsRestants

            else
                #Initialisation de l'itérateur
                indNouvelObjetCasse=indObjetCasse+1
                #Mise à jour des valeurs de la solution
                nouvellePlaceOccupeDantzig=placeOccupeDantzig + listeObjets[indNouvelObjetCasse].cout
                nouvelleValDantzig=valDantzig + listeObjets[indNouvelObjetCasse].profit

                while nouvellePlaceOccupeDantzig<=poidsMax

                    indNouvelObjetCasse= indNouvelObjetCasse+1
                    #Mise à jour des valeurs de la solution
                    nouvellePlaceOccupeDantzig=nouvellePlaceOccupeDantzig + listeObjets[indNouvelObjetCasse].cout
                    nouvelleValDantzig=nouvelleValDantzig + listeObjets[indNouvelObjetCasse].profit

                end

                #On enleve l'objet cassé de la solution trouvé pour qu'elle soit inférieur au poidsMax
                nouvellePlaceOccupeDantzig=nouvellePlaceOccupeDantzig - listeObjets[indNouvelObjetCasse].cout
                nouvelleValDantzig=nouvelleValDantzig - listeObjets[indNouvelObjetCasse].profit
                 #Mise à jour de l'objet cassé
                nouvelObjetCasse=listeObjets[indNouvelObjetCasse]

                #Phase 2:Calcul de la nouvelle borne

                #Cas 2.1 s'=s+1
                if indNouvelObjetCasse==(indObjetCasse+1)

                    if indNouvelObjetCasse==nombreObjets
                        nouveauU0=valDantzig
                    else
                        #Calcul de la nouvelle valeurs de U0
                        nouveauU0= valDantzig +floor(capaciteResiduelle * listeObjets[indNouvelObjetCasse+1].profit/listeObjets[indNouvelObjetCasse+1].cout)
                    end

                    if indObjetCasse==1
                        nouveauU1=listeObjets[indObjetCasse].profit+nouvelObjetCasse.profit
                    else
                        #Calcul de la nouvelle valeurs de U0
                        nouveauU1= valDantzig + floor(nouvelObjetCasse.profit - (nouvelObjetCasse.cout - capaciteResiduelle) * listeObjets[indObjetCasse-1].profit/listeObjets[indObjetCasse-1].cout)
                    end
                    return max(nouveauU0,nouveauU1)
                #Cas 2.2 s'>s+1
                else
                    #Mise à jour de la capacité résiduelle
                    nouvelleCapaciteResiduelle= poidsMax - nouvellePlaceOccupeDantzig
                    if indNouvelObjetCasse==nombreObjets
                        nouveauU0=nouvelleValDantzig
                    else
                        #Calcul de la nouvelle valeurs de U0
                        nouveauU0= nouvelleValDantzig + floor(nouvelleCapaciteResiduelle * listeObjets[indNouvelObjetCasse+1].profit/listeObjets[indNouvelObjetCasse+1].cout)
                    end

                    #indNouvelObjetCasse>2 pas besoin de traiter le cas où il serait le premier objet de la liste
                    #Calcul de la nouvelle valeurs de U1
                    nouveauU1= nouvelleValDantzig + floor(nouvelObjetCasse.profit - (nouvelObjetCasse.cout - nouvelleCapaciteResiduelle)*listeObjets[indNouvelObjetCasse-1].profit/listeObjets[indNouvelObjetCasse-1].cout)

                    return max(nouveauU0,nouveauU1)

                end
            end
        end
    #Cas 3: i=s+1
    elseif indObjetAEnlever==(indObjetCasse+1)
        if indObjetCasse+1==nombreObjets
            nouveauU0=valDantzig
        else
            #L'objet s+1 est enlevé, on calcule le nouveau U0 avec l'objet à s+2
            nouveauU0= valDantzig +floor(capaciteResiduelle * listeObjets[indObjetCasse+2].profit/listeObjets[indObjetCasse+2].cout)
        end
        #U1 n'est pas impactée
        return max(nouveauU0,U1)

    #Cas 4: i>s+1
    else
        #Pas d'impact sur la borne Sup
        return UB

    end

end

#Fonction utile pour calculUB1()
#Role:Dans le cas d'une "solution" supérieure au poidsMax (solution Dantzig + une objet forcé) supprime des objets de la solution Dantzig en partant de la fin et
#     renvoie l'indice du nouvel objet cassé et les caractéristiques de la nouvelle solution
#Préconditions: indObjetForce>=indObjetCasse, |listeObjets|>=indObjetCasse et ObjetForce.cout<=poidsMax
function calculRetrograde(listeObjets::Vector{Objet}, indObjetCasse::Int64, indObjetForce::Int64,valDantzig::Int64, placeDantzig::Int64, poidsMax::Int64)

    objetForce=listeObjets[indObjetForce]

    #Mise à jour des valeurs de la solution
    nouvelleValDantzig::Int64=valDantzig+objetForce.profit
    nouvellePlaceDantzig::Int64=placeDantzig+objetForce.cout
    #Initialisation de l'itérateur
    nouvelIndObjetCasse::Int64=indObjetCasse

    #Recherche du nouvel objet cassé
    while nouvellePlaceDantzig>poidsMax && nouvelIndObjetCasse>1

        nouvelIndObjetCasse=nouvelIndObjetCasse-1
        #Mise à jour des valeurs de la solution
        nouvelleValDantzig=nouvelleValDantzig-listeObjets[nouvelIndObjetCasse].profit
        nouvellePlaceDantzig=nouvellePlaceDantzig-listeObjets[nouvelIndObjetCasse].cout

    end

    #En sortie de boucle pas besoin de mise à jour des valeurs de la solution, elles sont déjà correct dans ce cas
    #Mise à jour de la capacité résiduelle
    capaciteResiduelle::Int64=poidsMax-nouvellePlaceDantzig

    return nouvelIndObjetCasse, nouvelleValDantzig, nouvellePlaceDantzig, capaciteResiduelle
end

#Fonction utile pour calculUB1()
#Role: Voir calculRetrograde(), on applique les résultats renvoyé par calculRetrograde a la formule de U0 et on renvoie U0 mise à jour
#Préconditions: indObjetForce>=indObjetCasse, |listeObjets|>=indObjetCasse
function calculRetrogradeU0(listeObjets::Vector{Objet}, indObjetCasse::Int64, indObjetForce::Int64,valDantzig::Int64, placeDantzig::Int64, poidsMax::Int64)
    objetForce=listeObjets[indObjetForce]

    nouvelIndObjetCasse::Int64, nouvelleValDantzig::Int64, nouvellePlaceDantzig::Int64, capaciteResiduelle::Int64= calculRetrograde(listeObjets, indObjetCasse, indObjetForce,valDantzig, placeDantzig, poidsMax)

    #Typage de U0
    nouveauU0::Int64=0
    if nouvelIndObjetCasse==length(listeObjets)
        nouveauU0= nouvelleValDantzig

    else
        nouveauU0= nouvelleValDantzig + floor(capaciteResiduelle*listeObjets[nouvelIndObjetCasse+1].profit/listeObjets[nouvelIndObjetCasse+1].cout)
    end

    return nouveauU0
end

#Fonction utile pour calculUB1()
#Role: Voir calculRetrograde(), on applique les résultats renvoyé par calculRetrograde a la formule de U1 et on renvoie U1 mise à jour
#Préconditions: indObjetForce>=indObjetCasse, |listeObjets|>=indObjetCasse
function calculRetrogradeU1(listeObjets::Vector{Objet}, indObjetCasse::Int64, indObjetForce::Int64,valDantzig::Int64, placeDantzig::Int64, poidsMax::Int64)
    objetForce=listeObjets[indObjetForce]

    nouvelIndObjetCasse::Int64, nouvelleValDantzig::Int64, nouvellePlaceDantzig::Int64, capaciteResiduelle::Int64= calculRetrograde(listeObjets, indObjetCasse, indObjetForce,valDantzig, placeDantzig, poidsMax)

    nouvelObjetCasse=listeObjets[nouvelIndObjetCasse]
    if nouvelIndObjetCasse==1
        nouveauU1= nouvelObjetCasse.profit

    else
        nouveauU1= nouvelleValDantzig + floor(nouvelObjetCasse.profit - (nouvelObjetCasse.cout - capaciteResiduelle)* listeObjets[nouvelIndObjetCasse-1].profit/listeObjets[nouvelIndObjetCasse-1].cout)
    end
    return nouveauU1
end

#Role: Renvoie la valeur de UB1(i) , i correspond à indObjetAAJouter
#Préconditions: |listeObjets|>=indObjetAAJouter et |listeObjets|>=indObjetCasse et placeOccupeDantzig<=poidsMax
function calculUB1(UB::Int64,U0::Int64,U1::Int64,listeObjets::Vector{Objet}, indObjetAAJouter::Int64, indObjetCasse::Int64,placeOccupeDantzig::Int64,valDantzig::Int64,poidsMax::Int64)
    #On calcule la capacité résiduelle du sac
    capaciteResiduelle::Int64=poidsMax-placeOccupeDantzig

    #Déclaration et initialisation de variables utiles par la suite
    nouveauU0::Int64=0
    nouveauU1::Int64=0

    #Cas 1: i<=s-2
    if indObjetAAJouter<=(indObjetCasse-2)
        #Pas d'impact sur la borne Sup
        return UB

    #Cas 2: i=s-1
    elseif indObjetAAJouter==(indObjetCasse-1)

        objetCasse::Objet=listeObjets[indObjetCasse]

        #indObjetCasse>=2
        if indObjetCasse==2
            nouveauU1= valDantzig + objetCasse.profit
        else
            #On remplace l'objet s-1 par l'objet s-2 dans la formule de U1
            nouveauU1= valDantzig + floor(objetCasse.profit - (objetCasse.cout- capaciteResiduelle) * listeObjets[indObjetCasse-2].profit/listeObjets[indObjetCasse-2].cout)
        end

        #U0 n'est pas impactée par ce changement
        return max(U0,nouveauU1)
    #Cas 3: i=s
    elseif indObjetAAJouter==indObjetCasse
        #On met à jour U0
        nouveauU0= calculRetrogradeU0(listeObjets, indObjetCasse, indObjetAAJouter,valDantzig, placeOccupeDantzig, poidsMax)
        #U1 n'est pas impactée par ce changement
        return max(nouveauU0,U1)

    #Cas 4: i=s+1
    elseif (indObjetAAJouter==indObjetCasse+1) && (capaciteResiduelle/listeObjets[indObjetCasse+1].cout>=1)
        #On met à jour U1
        nouveauU1=calculRetrogradeU1(listeObjets, indObjetCasse, indObjetAAJouter,valDantzig, placeOccupeDantzig, poidsMax)
        return max(U0,nouveauU1)

    else
        #On met à jour U0 et U1
        nouveauU0=calculRetrogradeU0(listeObjets, indObjetCasse, indObjetAAJouter,valDantzig, placeOccupeDantzig, poidsMax)
        nouveauU1=calculRetrogradeU1(listeObjets, indObjetCasse, indObjetAAJouter,valDantzig, placeOccupeDantzig, poidsMax)
        return max(nouveauU0, nouveauU1)
    end

end

#Role: Renvoie la valeur de LB0(i) , i correspond à indObjetSuppr
#Préconditions:|L|>=indObjetSuppr
function calculLb0(L::Vector{Objet}, poidsMax::Int64, indObjetSuppr::Int64)

    ObjetSuppr = L[indObjetSuppr]
    #Copie profonde de la liste d'objets pour pouvoir être modifiée
    Lbis = L[:]
    #On supprime l'objet i du problème
    deleteat!(Lbis, indObjetSuppr)
    #On calcule la solution du nouveau problème
    if length(Lbis) == 0
        ObjCasse, BorneInf, capaResi, Var0, Var1 = Objet(), 0, 0, Vector{Objet}(), Vector{Objet}()
    else
        ObjCasse::Objet, BorneInf::Int64,  capaResi::Int64, Var0::Vector{Objet}, Var1::Vector{Objet} = borneInfAlgoGlouton(Lbis, poidsMax)
    end
    #On ajoute l'objet i à la liste des onjets qu'on ajoute pas dans le sac
    append!(Var0, [ObjetSuppr])


	return BorneInf, Var0, Var1
end

"""

                                                                                                                            L'ERREUR EST LA

"""

#Role: Renvoie la valeur de LB1(i) , i correspond à indObjetAjout
#Préconditions:|L|>=indObjetAjout
function calculLb1(L::Vector{Objet}, poidsMax::Int64, indObjetAjout::Int64)

    ObjetAjout = L[indObjetAjout]
    #Copie profonde de la liste d'objets pour pouvoir être modifiée
    Lbis = L[:]
    #On supprime l'objet i du problème
    deleteat!(Lbis, indObjetAjout)
    #On calcule la solution du nouveau problème (avec un sac à dos plus petit)
    if length(Lbis) != 0
        ObjCasse::Objet, BorneInf::Int64,  capaResi::Int64, Var0::Vector{Objet}, Var1::Vector{Objet} = borneInfAlgoGlouton(Lbis, poidsMax-ObjetAjout.cout)
    else
        ObjCasse, BorneInf,  capaResi, Var0, Var1 = Objet(), 0, 0, Vector{Objet}(), Vector{Objet}()
    end

    #On ajoute l'objet i à la liste des onjets qu'on ajoute dans le sac (sac de base)
    append!(Var1, [ObjetAjout])

    return BorneInf+ObjetAjout.profit, Var0, Var1
end

#Tentative d'une deuxième version "plus efficace" pour calculer LB0 sans avoir à rappeler borneInfAlgoGlouton() à chaque fois: ECHEC
function calculLB0bis(listeObjets::Vector{Objet},indObjetSuppr::Int64,indObjetCasse::Int64,BorneInf::Int64,listeVar0::Vector{Objet},listeVar1::Vector{Objet},valDantzig::Int64,placeOccupeDantzig::Int64,poidsMax::Int64)
    objetSuppr=listeObjets[indObjetSuppr]

    if objetSuppr in listeVar0
        return BorneInf, listeVar0, listeVar1
    else

        Var0::Vector{Objet}=[]
        Var1::Vector{Objet}=[]


        Var1=listeVar1[1:(indObjetCasse-1)]

        if objetSuppr in Var1
            Var1=deleteat!(Var1, indObjetSuppr)
        end

        append!(Var0,[objetSuppr])

        if indObjetSuppr<indObjetCasse

            LB0::Int64= valDantzig- objetSuppr.profit
            placeOccupe::Int64= placeOccupeDantzig- objetSuppr.cout
        else
            LB0=valDantzig
            placeOccupe=placeOccupeDantzig
        end


        for ind in indObjetCasse:length(listeObjets)
            if ind!=indObjetSuppr
                if (listeObjets[ind].cout+placeOccupe<=poidsMax)
                    placeOccupe= placeOccupe+ listeObjets[ind].cout
                    LB0=LB0+listeObjets[ind].profit
                    append!(Var1,[listeObjets[ind]])
                else
                    append!(Var0,[listeObjets[ind]])
                end
            end
        end

        return LB0, Var0,Var1
    end

end

#Fonction utile pour calculLB1bis(), voir calculLB1bis()
#Role: Cherche l'objet aTrouver dans la liste et renvoie son indice
function getIndexObjet( listeATraiter::Vector{Objet}, aTrouver::Objet)
    indiceCourant::Int64=1
    trouve::Bool=false
    while !trouve && indiceCourant<=length(listeATraiter)
        if listeATraiter[indiceCourant]==aTrouver
            trouve=!trouve
        else
            indiceCourant=indiceCourant+1
        end
    end
    if trouve
        return indiceCourant
    else
        return 0
    end
end

#Tentative d'une deuxième version "plus efficace" pour calculer LB1 sans avoir à rappeler borneInfAlgoGlouton() à chaque fois: ECHEC
function calculLB1bis(listeObjets::Vector{Objet},indObjetAjout::Int64,indObjetCasse::Int64,BorneInf::Int64,L0::Vector{Objet},L1::Vector{Objet},valDantzig::Int64,placeOccupeDantzig::Int64,poidsMax::Int64)
    listeVar0 = L0[:]
    listeVar1 = L1[:]

    if indObjetAjout<indObjetCasse
        return BorneInf,listeVar0,listeVar1
    else
        indCourant::Int64=indObjetCasse-1

        objetAjout=listeObjets[indObjetAjout]
        estDansVar1::Bool = objetAjout in listeVar1

        if estDansVar1
            return BorneInf,listeVar0,listeVar1
        else

            Var0::Vector{Objet}=[]
            Var1::Vector{Objet}=[]


            Var1= append!([objetAjout],listeVar1[1:(indObjetCasse-1)])
            Var0= []


            LB0::Int64= valDantzig + objetAjout.profit
            placeOccupe::Int64= placeOccupeDantzig + objetAjout.cout

            if placeOccupe>poidsMax
                indCourant=length(Var1)
                while placeOccupe>poidsMax
                    LB0= LB0 - Var1[indCourant].profit
                    placeOccupe= placeOccupe - Var1[indCourant].cout

                    Var0= append!(Var0,[Var1[indCourant]])
                    deleteat!(Var1,indCourant)
                    indCourant=indCourant-1

                end
                for ind in indObjetCasse:length(listeObjets)
                    if ind!=indObjetAjout
                        append!(Var0,[listeObjets[ind]])
                    end
                end
            else
                indCourant=indObjetCasse
                while placeOccupe<=poidsMax
                    if indCourant!=indObjetAjout
                        if placeOccupe+listeObjets[indCourant].cout<=poidsMax
                            placeOccupe=placeOccupe+listeObjets[indCourant].cout
                            LB0= LB0+listeObjets[indCourant].profit
                            append!(Var1, [listeObjets[indCourant]])
                        else
                            append!(Var0,[listeObjets[indCourant]])
                        end
                        indCourant=indCourant+1
                    end
                end
                for ind in indCourant:length(listeObjets)
                    append!(Var0,[listeObjets[ind]])
                end



            end

            return LB0,Var0,Var1

        end
    end
end

#Role: Renvoie la liste des objets qu'on est sur de ne pas prendre, la liste de ceux qu'on est sur de prendre,
#      la liste de ceux qu'il reste à traiter et la somme des profits des objets qu'on est sur de prendre, ainsi que ces même données pour la
#	   borne Inf
#Préconditions:|L|>0, L triée par ratio profit/poids décroissant
function calculVariable(L::Vector{Objet}, poidsMax::Int64)


    longueurL::Int64 = length(L)
    poidsTotalObjets::Int64=sommePoidsObjets(L)

    if poidsTotalObjets>poidsMax
        #A partir de la liste d'objets et du poids max on récupère les caractéristiques de la solution Dantzig
        indObjCasse::Int64, placeOccupeDantzig::Int64, valDantzig::Int64= solutionDantzig(L,poidsMax)

        #A partir de la liste d'objets et du poids max on récupère les caractéristiques de la solution gloutonne
        ObjCasse::Objet, BorneInfInit::Int64,  capaResi::Int64, VarBIAG0::Vector{Objet}, VarBIAG1::Vector{Objet} = borneInfAlgoGlouton(L, poidsMax)

        #On fait des copie profonde afin de pouvoir modifier les liste et la BorneInf tout en gardant les valeurs initiales
        VarInf0 = VarBIAG0[:]
        VarInf1 = VarBIAG1[:]
        BorneInf = BorneInfInit

        #////////////////////////
        #VarInf0bis = VarBIAG0[:]
        #VarInf1bis = VarBIAG1[:]
        #BorneInfbis = BorneInfInit
        #//////////////////////////

        #On calcule U0 et U1
        U0::Int64, U1::Int64 = calculBornesSup(L, ObjCasse, indObjCasse, valDantzig, poidsMax-placeOccupeDantzig)
        #On détermine la borne sup
        BorneSup::Int64=UB(U0,U1)

        #On initialise les listes qui contiendrons les valeurs UB0(i) et UB1(i) pour tout les objets de la liste
        UB0::Vector{Int64} = []
        UB1::Vector{Int64} = []

        #On initialise les liste qui contiendrons:
        Var1::Vector{Objet} = [] #les objets forcément pris
        Var0::Vector{Objet} = [] # ceux forcément pas pris
        VarRestantes::Vector{Objet} = [] #ceux qu'il reste à traiter

        #Pour chaque objet de la liste:
        for ind in 1:longueurL

            #On calcule UB0(i)
            UB0 = append!(UB0, [calculUB0( BorneSup,U1,L, ind, indObjCasse,placeOccupeDantzig,valDantzig,poidsMax)])
            #On calcule UB1(i)
            UB1 = append!(UB1, [calculUB1( BorneSup,U0,U1,L, ind, indObjCasse,placeOccupeDantzig,valDantzig,poidsMax )])

            #On calcule LB0(i)
            lb0, Var0Suppr, Var1Suppr = calculLb0( L, poidsMax, ind )
            #On calcule LB1(i)
            lb1, Var0Ajout, Var1Ajout = calculLb1( L, poidsMax, ind )

            #//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            #LB0bis, Var0Supprbis, Var1Supprbis = calculLB0bis(L,ind,indObjCasse,BorneInfInit,VarBIAG0,VarBIAG1,valDantzig,placeOccupeDantzig,poidsMax)
            #LB1bis, Var0Ajoutbis, Var1Ajoutbis = calculLB1bis(L,ind,indObjCasse,BorneInfInit,VarBIAG0,VarBIAG1,valDantzig,placeOccupeDantzig,poidsMax)
            #//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            #On regarde la plus grande des deux bornes inférieures
            if lb0 < lb1
                #Si c'est LB1(i) et qu'elle est plus grande que la BorneInf actuelle on met BorneInf à jour (sa valeur et ses listes)
                if BorneInf < lb1

                    BorneInf = lb1

                    VarInf0 = Var0Ajout
                    VarInf1 = Var1Ajout

                end
                #Si c'est LB0(i) et qu'elle est plus grande que la BorneInf actuelle on met BorneInf à jour (sa valeur et ses listes)
            elseif BorneInf < lb0
                BorneInf = lb0

                VarInf0 = Var0Suppr
                VarInf1 = Var1Suppr

            end

            #////////////////////////////////
            #if LB0bis < LB1bis
            #    if BorneInfbis < LB1bis
            #        BorneInfbis = LB1bis
            #
            #        VarInf0bis = Var0Ajoutbis
            #        VarInf1bis = Var1Ajoutbis
            #
            #    end
            #elseif BorneInfbis < LB0bis
            #    BorneInfbis = LB0bis
            #
            #    VarInf0bis = Var0Supprbis
            #    VarInf1bis = Var1Supprbis
            #
            #end
            #///////////////////////////////

        end

        #Une fois la valeur finale de la BorneInf obtenue

        #Pour tout les objets de la liste

        for ind in 1:longueurL

            #On regarde si ils sont forcément pris
            if UB0[ind] <= BorneInf && UB1[ind] >BorneInf
                Var1 = append!(Var1, [L[ind]])
	    	elseif UB0[ind] <= BorneInf && UB1[ind] <= BorneInf
	    		return VarInf0, VarInf1, [], BorneInf, VarInf0, VarInf1, BorneInf
            #si ils sont forcément pas pris
            elseif UB1[ind] <= BorneInf

                Var0 = append!(Var0, [L[ind]])
            #ou si cela reste à déterminer
            else
                VarRestantes = append!(VarRestantes, [L[ind]])
            end
        end

        #On s'interesse aux objets qu'on prend forcément

        #On calcule la somme de leur poids
        sommePoidsVar1::Int64 = 0
        #et celle de leur profit
        sommeProfitVar1::Int64 = 0

        for obj in Var1
            sommePoidsVar1 = sommePoidsVar1 + obj.cout
            sommeProfitVar1 = sommeProfitVar1 + obj.profit
        end

        #Si les poids cumulés dépasse le poids maximum on retourne la Borne Inf
        if sommePoidsVar1>poidsMax

            return VarInf0, VarInf1, [], BorneInf, VarInf0, VarInf1, BorneInf

        else
            #Sinon, on s'interesse aux variables qu'il reste à traiter
            VarRestantesTmp = VarRestantes[:]
            VarRestantes = []
            #on élimine celles dont le poids est supérieur à la capacité résiduelle du sac
            for i in 1:length(VarRestantesTmp)
                obj = VarRestantesTmp[i]
                #si c'est le cas alors cela veut dire que l'objet est forcément pas pris
                if obj.cout>(poidsMax - sommePoidsVar1)

                    append!(Var0, [obj])
                else
                    #sinon c'est à la programmation dynamique de traiter cela
                    append!(VarRestantes, [obj])
                end
            end

            return Var0,Var1,VarRestantes,sommeProfitVar1, VarInf0, VarInf1, BorneInf
        end
    else
        profitTotal::Int64=sommeProfitObjets(L)
        varsA1::Vector{Objet}=[]

        for ind in 1:longueurL
            push!(varsA1,L[ind])
        end

        return [],varsA1,[],profitTotal, [], varsA1, profitTotal
    end

end

#Voir triId() ci-dessous
function fusionId(L1::Vector{Objet}, L2::Vector{Objet})
    if length(L1) == 0
        return L2
    elseif length(L2) == 0
        return L1
    elseif L1[1].id < L2[1].id
        return append!([L1[1]], fusionId( L1[2:length(L1)], L2))
    else
        return append!([L2[1]], fusionId(L1, L2[2:length(L2)]))
    end
end

#Role: Renvoie la liste d'objets L triée de façon croissante par ratio identifiant, en suivant une méthode récursive de tri fusion
function triId(L::Vector{Objet})
    if length(L)<=1
        return L
    else
        lim::Int64 = floor(length(L)/2)
        return fusionId(triId(L[1:lim]), triId(L[lim+1:length(L)]))
    end
end

#Fonction principale
#Role: Pour une instance donnée, effectue le prétraitement  et renvoie la liste des objets qu'on est sur de ne pas prendre,
#      la liste de ceux qu'on est sur de prendre,la liste de ceux qu'il reste à traiter et la somme des profits des objets qu'on est sur de prendre
#Précondition: i et j doivent correspondre à une instance existante: i in {50,100,150...500}, j in {1,2,...,10}
function main_pretrait(i::Int64=50, j::Int64=1)
    lien::String = "Instances/KP$i-$j.dat"

    #On récupère les données renvoyées par le parseur
    d = parseKP(lien)

    profits::Vector{Int64} = d.p
    poids::Vector{Int64} = d.w

    poidsMax::Int64 = d.Omega
    taille::Int64 = length(poids)

    ListObj::Vector{Objet} = [Objet(profits[i], poids[i], i) for i in 1:taille]
    #Tri des objets par ratio
    ListObj = triFusion(ListObj)

    #Pré-traitement
    Res0, Res1, ResPif, Somme, Var0, Var1, BorneInf = calculVariable(ListObj, poidsMax)

    return Res0, Res1, ResPif, Somme, Var0, Var1, BorneInf
end

function main_pretrait(ListObj::Vector{Objet}, poidsMax::Int)
    ListObj = triFusion(ListObj)
    return calculVariable(ListObj, poidsMax)

end
