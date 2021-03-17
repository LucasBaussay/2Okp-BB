# 13-03-2020 Projet Recherche Opérationelle
# 681C Baussay L et Jourdan L
# Résolution directe du problème du sac à dos par GLPK

using GLPK, JuMP

function model_solve_sac_a_dos(solverSelected::DataType, poids::Vector{Int64}, profits::Vector{Int64}, poids_max::Int64)

    m::Model = Model(with_optimizer(solverSelected))
    nbVars::Int64 = length(poids)

    # Vaut 1 si l'objet est mit dans le sac 0 sinon
    @variable(m,x[1:nbVars],Bin)

    @objective(m, Max, sum(profits[i]*x[i] for i in 1:nbVars))

    @constraint(m,limite_poids, sum(poids[i]*x[i] for i in 1:nbVars) <=poids_max)

    optimize!(m)

    status = termination_status(m)

    # Affichage des résultats 
    if status == MOI.OPTIMAL
        #println("Problème résolu à l'optimalité")

        #println("z = ",objective_value(m)) # affichage de la valeur optimale
        #println("x = ",value.(m[:x])) # affichage des valeurs du vecteur de variables issues du modèle

        # On peut trouver le premier affichage lourd, et préférer se limiter aux variables fixées à 1 dans l'affichage
        #print("Liste des variables fixées à 1: ")
        for i in 1:num_variables(m)
            if isapprox(value(m[:x][i]),1)
                #print(i," ")
            end
        end
        #println()

    elseif status == MOI.INFEASIBLE
        #println("Problème impossible")

    elseif status == MOI.INFEASIBLE_OR_UNBOUNDED
		
    end
end

#Role : Applique le problème du sac à dos via JuMP sur l'exemple du sujet (Désormais présent dans les instances sous le nom : KP4-1.dat)
#Préconditions : 
function sac_a_dos()

    profits::Vector{Int64}=[5, 6, 4, 9]
    poids::Vector{Int64}=[5, 4, 6, 5]

    poidsMax::Int64=10

    model_solve_sac_a_dos(GLPK.Optimizer, poids, profits, poidsMax)
end

#Role : Applique le problème du sac à dos via JuMP sur l'instance KP$i-$j.dat
#Préconditions : i doit appartenir à {50, 100, 150, ..., 500} et à {1, 2, ..., 10}
function testFichier(i::Int64,j::Int64)
    lien::String = "Instances/KP$i-$j.dat"

    d = parseKP(lien)

    profits::Vector{Int64} = d.p
    poids::Vector{Int64} = d.w

    poidsMax::Int64 = d.Omega

    model_solve_sac_a_dos(GLPK.Optimizer, poids, profits, poidsMax)
end
