function backtrack(prob::Problem, indFinAssignment::Int, permList::Vector{Int}, iter::Int, bestSolPrim::Vector{Bool}, profitPrim::Float64, poidsRestPrim::Float64, lb::Float64, ub::Float64; verbose = false)
    iterLastOne = 0

    if iter == indFinAssignment || lb == ub
        return bestSolPrim, lb
    elseif bestSolPrim[iter] == 0
        return backtrack(prob, indFinAssignment, permList, iter-1, bestSolPrim, profitPrim, poidsRestPrim, lb, ub, verbose = verbose)
    else

        verbose && println("On tente d'améliorer en fixant x_$(permList[iter]) à 0")

        poidsRest = poidsRestPrim + prob.constraint.weights[permList[iter]]
        profitAct = profitPrim - prob.objs[1].profits[permList[iter]]
        ubAct = Inf
        sol = falses(prob.nbVar-iter)

        iterSub = iter+1

        while iterSub <= prob.nbVar && prob.constraint.weights[permList[iterSub]] <= poidsRest
            sol[iterSub - iter] = 1
            poidsRest -= prob.constraint.weights[permList[iterSub]]
            profitAct += prob.objs[1].profits[permList[iterSub]]
            iterSub += 1
        end

        if iterSub <= prob.nbVar
            ubAct = profitAct + (poidsRest / prob.constraint.weights[permList[iterSub]]) * prob.objs[1].profits[permList[iterSub]]
        else
            ubAct = profitAct
        end

        verbose && println("La valeur max du sous problème est : $ubAct et la meilleure solution actuelle : $lb")

        if ubAct > lb

            verbose && println("Le sous problème est peut-être améliorant ! ")

            while iterSub <= prob.nbVar && poidsRest != 0
                if prob.constraint.weights[permList[iterSub]] <= poidsRest
                    sol[iterSub - iter] = 1
                    poidsRest -= prob.constraint.weights[permList[iterSub]]
                    profitAct += prob.objs[1].profits[permList[iterSub]]
                    iterLastOne = iterSub
                end
                iterSub += 1
            end

            if profitAct > lb

                verbose && println("Youpi on améliore : de $lb à $profitAct")

                lb = profitAct
                bestSolPrim[iter] = 0
                bestSolPrim[iter+1:end] = sol[1:end]
                iter = iterLastOne
                poidsRestPrim = poidsRest

                verbose && println()
                return backtrack(prob, indFinAssignment, permList, iter, bestSolPrim, lb, poidsRestPrim, lb, ub, verbose = verbose)
            else
                verbose && println("Coup dur, on continue le Backtrack")
                verbose && println()
                return backtrack(prob, indFinAssignment, permList, iter-1, bestSolPrim, profitPrim - prob.objs[1].profits[permList[iter]], poidsRestPrim + prob.constraint.weights[permList[iter]], lb, ub, verbose = verbose)
            end
        else
            verbose && println()
            return backtrack(prob, indFinAssignment, permList, iter-1, bestSolPrim, profitPrim - prob.objs[1].profits[permList[iter]], poidsRestPrim + prob.constraint.weights[permList[iter]], lb, ub, verbose = verbose)
        end
    end

end

function solve1OKP(prob::Problem, assignment::Vector{Int} = Vector{Int}(), indFinAssignment::Int = 0, assignmentWeight::Float64 = 0., assignmentProfit::Float64 = 0.; verbose = false)
    @assert prob.nbObj == 1 "This problem is no 1OKP"

    permList = sortperm(prob.objs[1].profits ./ prob.constraint.weights, rev = true)

    revPermList = Vector{Int}(undef, length(permList))

    for iter = 1:length(permList)
        revPermList[permList[iter]] = iter
    end

    poidsRestPrim = prob.constraint.maxWeight - assignmentWeight
    bestSolPrim = zeros(Bool, prob.nbVar) #Par Objets triés

    iterLastOne = 0

    for iter = 1:indFinAssignment
        bestSolPrim[permList[iter]] = assignment[permList[iter]]
        if assignment[permList[iter]] == 1
            iterLastOne = iter
        end
    end

    iter = indFinAssignment + 1

    lb = 0. + assignmentProfit
    ub = Inf

    """

    Initialisation pour avoir une LowerBound et UpperBound

    """

    while iter <= prob.nbVar && prob.constraint.weights[permList[iter]] <= poidsRestPrim
        bestSolPrim[iter] = 1
        poidsRestPrim -= prob.constraint.weights[permList[iter]]
        lb += prob.objs[1].profits[permList[iter]]
        iterLastOne = iter
        iter += 1
    end

    if iter <= prob.nbVar
        ub = lb + (poidsRestPrim / prob.constraint.weights[permList[iter]]) * prob.objs[1].profits[permList[iter]]
    else
        return bestSolPrim[revPermList]
    end

    while iter <= prob.nbVar && poidsRestPrim != 0
        if prob.constraint.weights[permList[iter]] <= poidsRestPrim
            bestSolPrim[iter] = 1
            poidsRestPrim -= prob.constraint.weights[permList[iter]]
            lb += prob.objs[1].profits[permList[iter]]
            iterLastOne = iter
        end
        iter += 1
    end

    """

    Backtracking

    """

    println(bestSolPrim, lb)
    println(permList)

    verbose && println("On comment le Backtracking")

    sol, lb = backtrack(prob, indFinAssignment, permList, iterLastOne, bestSolPrim, lb, poidsRestPrim, lb, ub, verbose = verbose)

    return Solution(sol[revPermList], [lb])

end
