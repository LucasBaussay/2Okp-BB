# Sac à dos Ro

Mode d'emploi pour lancer un programme : 

	- Ouvrir dans une un terminal Linux, situé dans le dossier du projet, le REPL de Julia

	- taper : >> include("structKP.jl") #Permet d'inclure toutes les structures de données correspondantes au problème du sac à dos.

	- puis taper : >> include( # L'implémentation choisi # )

	- Ensuite taper la commande executant le fichier : dépend de l'implémentation choisi : 


Fonction executant le programme pour chaque instances : 

	- jump.jl 				-> Pour l'executer sur une Instance KP$i-$j.dat : testFichier(i,j)
	
	- prog_dyn.jl	 		-> Pour l'executer sur une Instance KP$i-$j.dat : main_prog_basique(i,j)

	- progDynamique_V2.jl 	-> Pour l'executer sur une Instance KP$i-$j.dat : test_fichier(i,j)

	- pourAllerPlusLoin.jl 	-> Pour l'executer sur une Instance KP$i-$j.dat : test_fichierPlusLoin(i,j)

	- pretraitement.jl 		-> Pour l'executer sur une Instance KP$i-$j.dat : main_pretrait(i,j)

	- projetFinal.jl 		-> Pour l'executer sur une Instance KP$i-$j.dat avec La programmation dynamique : test_fichierFinalProgDyn(i,j)

							-> Pour l'executer sur une Instance KP$i-$j.dat avec La partie pour Aller plus loin : test_fichierFinalPlusLoin(i,j)

Maintenant la signification de chaque fichier Julia : 

	- jump.jl 				-> Execute le problème du sac à dos via JuMP et GLPK

	- prog_dyn.jl 			-> Execute la programation dynamique basique

	- progDynamique_V2 		-> Execute la programmation dynamique moins basique

	- pourAllerPlusLoin.jl	-> Execute la programmation dynamique moins basique mais avec les idées proposés dans la partie Pour aller plus loin

	- pretraitement.jl 		-> Applique le prétraitement et renvoie donc la liste des Variables misent à 0, 1, et celles qui restent à traiter, le profit 
							   générer avec les variables misent à 1 ainsi que les mêmes caractéristiques pour la borne Inferieur du problème.

	- projetFinal.jl 		-> Ce fichier-ci éxecute d'abord le prétraitement puis applique un algorithme de programmation dynamique sur les variables restantes
							   afin de finir le problème.


	- structKP.jl			-> Ce fichier contient toutes nos structures de données ainsi que celles proposées par Anthony PRZYBYLSKI.


Certaines fonctions ont le même nom dans des fichiers différents avec des return différents, aussi il sera grandement suggéré, pour éviter des erreurs, de fermer le REPL avant d'utiliser une autre implémentation.
