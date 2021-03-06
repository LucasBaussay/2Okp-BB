function backtrack(prob::Problem, permList::Vector{Int}, iter::Int, bestSolPrim::Vector{Bool}, poidsRestPrim::Float64, lb::Float64, ub::Float64, nbIter::Int = 1; verbose = false)
    iterLastOne = 0

    verbose && println("On commence le Backtrack n°$nbIter")

    if iter == 0 || lb == ub
        return bestSolPrim, lb
    elseif bestSolPrim[iter] == 0
        return backtrack(prob, permList, iter-1, bestSolPrim, poidsRestPrim, lb, ub, nbIter+1, verbose = verbose)
    else
        poidsRest = poidsRestPrim + prob.constraint.weights[permList[iter]]
        profitAct = lb - prob.objs[1].profits[permList[iter]]
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
        if ubAct > lb
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

                ub = ubAct
                lb = profitAct
                bestSolPrim[iter] = 0
                bestSolPrim[iter+1:end] = sol[1:end]
                iter = iterLastOne
                poidsRestPrim = poidsRest

                return backtrack(prob, permList, iter, bestSolPrim, poidsRestPrim, lb, ub, nbIter+1, verbose = verbose)
            else
                return backtrack(prob, permList, iter-1, bestSolPrim, poidsRestPrim + prob.constraint.weights[permList[iter]], lb, ub, nbIter+1, verbose = verbose)
            end
        else
            return backtrack(prob, permList, iter-1, bestSolPrim, poidsRestPrim + prob.constraint.weights[permList[iter]], lb, ub, nbIter+1, verbose = verbose)
        end
    end

end

function solve1OKP(prob::Problem; verbose = false)
    @assert prob.nbObj == 1 "This problem is no 1OKP"

    permList = sortperm(prob.objs[1].profits ./ prob.constraint.weights, rev = true)

    revPermList = Vector{Int}(undef, length(permList))

    for iter = 1:length(permList)
        revPermList[permList[iter]] = iter
    end

    poidsRestPrim = prob.constraint.maxWeight
    bestSolPrim = zeros(Bool, prob.nbVar) #Par Objets triés
    indFinObjTake = 0

    iter = 1
    iterLastOne = 0

    lb = 0.
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

    sol, lb = backtrack(prob, permList, iterLastOne, bestSolPrim, poidsRestPrim, lb, ub, 0, verbose = verbose)

    return sol[revPermList]

end
