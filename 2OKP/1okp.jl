
"""Solves a 1OKP"""

"""
    backtrack(prob::Problem, indEndAssignment::Int, permList::Vector{Int}, iter::Int, bestSolPrim::Vector{Bool}, currentLB::Float64, poidsRestPrim::Float64, lb::Float64, ub::Float64; verbose = false)

    returns ...

    @prob : 1OKP to solve (the sub problems have the same number of variables)
    @assignment : array of assignments (of length n) (non ordered)
    @indFinAssignment : index of the last assigned variable (non ordered)
    @permList : permutation list sorting the variables. Beginning with the best ones, ending with worsts. Usage : permList[1] gives the index of the first best variable
    @revPermList : inverse permutation list allowing to get back to the original indexes of the variables
    @iter : ancient iterLastOne (ordered)
    @bestSolPrim : current best primal solution (indexed on ordered variables) : bestSolPrim[1] targets the first best variable.
    @currentLB : current lb
    @poidsRestPrim : space left in the bag
    @lb : best lower bound
    @ub : best upper bound
"""
function backtrack(prob::Problem, assignment::Vector{Int}, indEndAssignment::Int, permList::Vector{Int}, revPermList::Vector{Int}, iter::Int, bestSolPrim::Vector{Bool}, currentLB::Float64, poidsRestPrim::Float64, lb::Float64, ub::Float64; verbose = false)

    if iter == indEndAssignment || lb == ub # stopping rule, end of study or optimality
        return bestSolPrim, lb
    elseif bestSolPrim[iter] == 0 # we can't test anything here because the item is not assigned to one, we backtrack with iter-1
        return backtrack(prob, assignment, indEndAssignment, permList, revPermList, iter-1, bestSolPrim, currentLB, poidsRestPrim, lb, ub, verbose = verbose)
    elseif assignment[permList[iter]] != -1


    else
        iterLastOne = prob.nbVar # initialization of iterLastOne 

        verbose && println("On tente d'améliorer en fixant x_$(permList[iter]) à 0")

        # GOAL : improve current solution by assigning the variable permList[iter] to zero.
        
        currentPoidsRest = poidsRestPrim + prob.constraint.weights[permList[iter]]
        currentProfit = currentLB - prob.objs[1].profits[permList[iter]]
        currentUB = Inf
        sol = falses(prob.nbVar-iter)

        iterSub = iter+1

        while iterSub <= prob.nbVar && prob.constraint.weights[permList[iterSub]] <= currentPoidsRest
            sol[iterSub - iter] = 1
            currentPoidsRest -= prob.constraint.weights[permList[iterSub]]
            currentProfit += prob.objs[1].profits[permList[iterSub]]
            iterLastOne = iterSub
            iterSub += 1
        end

        if iterSub <= prob.nbVar
            currentUB = currentProfit + (currentPoidsRest / prob.constraint.weights[permList[iterSub]]) * prob.objs[1].profits[permList[iterSub]]
        else
            currentUB = currentProfit
        end

        verbose && println("La valeur max du sous problème est : $currentUB et la meilleure solution actuelle : $lb")

        if currentUB > lb

            verbose && println("Le sous problème est peut-être améliorant ! ")

            while iterSub <= prob.nbVar && currentPoidsRest != 0
                if prob.constraint.weights[permList[iterSub]] <= currentPoidsRest
                    sol[iterSub - iter] = 1
                    currentPoidsRest -= prob.constraint.weights[permList[iterSub]]
                    currentProfit += prob.objs[1].profits[permList[iterSub]]
                    iterLastOne = iterSub
                end
                iterSub += 1
            end

            if currentProfit > lb

                verbose && println("Youpi on améliore : de $lb à $currentProfit")

                lb = currentProfit
                bestSolPrim[iter] = 0
                bestSolPrim[iter+1:end] = sol[1:end]
                iter = iterLastOne
                poidsRestPrim = currentPoidsRest

                verbose && println()
                return backtrack(prob, assignment, indEndAssignment, permList, revPermList, iter, bestSolPrim, lb, poidsRestPrim, lb, ub, verbose = verbose)
            else
                verbose && println("Coup dur, on continue le Backtrack")
                verbose && println()
                return backtrack(prob, assignment, indEndAssignment, permList, revPermList, iter-1, bestSolPrim, currentLB - prob.objs[1].profits[permList[iter]], poidsRestPrim + prob.constraint.weights[permList[iter]], lb, ub, verbose = verbose)
            end
        else
            verbose && println()
            return backtrack(prob, assignment, indEndAssignment, permList, revPermList, iter-1, bestSolPrim, currentLB - prob.objs[1].profits[permList[iter]], poidsRestPrim + prob.constraint.weights[permList[iter]], lb, ub, verbose = verbose)
        end
    end

end

"""
    solve1OKP(prob::Problem, assignment::Vector{Int} = Vector{Int}(), indEndAssignment::Int = 0, assignmentWeight::Float64 = 0., assignmentProfit::Float64 = 0.; verbose = false)
    
    return the unique solution of the given 1OKP

    @prob : 1OKP to solve (the sub problems have the same number of variables)
    @assignment : array of assignments (of length n) (non ordered)
    @indFinAssignment : index of the last assigned variable (non ordered)
    @assignmentWeight : the sum of the weights of the variables assigned to one
    @assignmentProfit : the sum of the profits of the variables assigned to one

    @bestSolPrim : current best primal solution (indexed on ordered variables) : bestSolPrim[1] targets the first best variable.
    @iterLastOne : index (ordered) of the last variable assigned to one in @bestSolPrim
"""
function solve1OKP(prob::Problem, assignment::Vector{Int} = Vector{Int}(), indEndAssignment::Int = 0, assignmentWeight::Float64 = 0., assignmentProfit::Float64 = 0.; verbose = false)
    @assert prob.nbObj == 1 "This problem is no 1OKP"

    # if the assignment is empty, we initialize the array at a size of nbVars in prob
    if assignment == []
        assignment  = Vector{Int}(undef, prob.nbVar)
        for iter = 1:prob.nbVar
            assignment[iter] = -1
        end
    end

    # permutation list sorting the variables. Beginning with the best ones, ending with worsts.
    # usage : permList[1] gives the index of the first best variable
    permList = sortperm(prob.objs[1].profits ./ prob.constraint.weights, rev = true)

    # inverse permutation list allowing to get back to the original indexes of the variables
    revPermList = Vector{Int}(undef, length(permList))
    # construction of the inverse permutation list
    for iter = 1:length(permList)
        revPermList[permList[iter]] = iter
    end

    # weight still available
    poidsRestPrim = prob.constraint.maxWeight - assignmentWeight

    # current best primal solution (indexed on ordered variables) : bestSolPrim[1] targets the first best variable.
    bestSolPrim = zeros(Bool, prob.nbVar)
    # construction of bestSolPrim
    iterLastOne = 0 # index (ordered) of the last variable assigned to one
    for iter = 1:prob.nbVar # iterating on variables (non ordered)
        var = permList[iter] # index of var (ordered)
        if assignment[var] != -1 # if the variable is assigned
            bestSolPrim[iter] = assignment[var] # the current sol assign this var to the same value
            if assignment[var] == 1 # the variable is assigned to one
                iterLastOne = var
            end
        end
    end

    iter = indEndAssignment + 1 # index (non ordered) of the first non assigned variable

    lb = 0. + assignmentProfit # profit we are sure to make because the solution is feasible
    ub = Inf

    """

    Construction of a good first feasible solution being our LowerBound. We calculate our UpperBound by adding a portion of the next item.

    """

    # GOAL : inside bestSolPrim, we want to force to one all the first variables (ordered) that could fit in the knapsack
    # iterating on the variables after iter. We stop if we can't assign the next variable to one. 
    while iter <= prob.nbVar && prob.constraint.weights[permList[iter]] <= poidsRestPrim
        var = permList[iter] # index of the variable (non ordered)
        bestSolPrim[iter] = 1 # we put the variable to one in the current solution
        poidsRestPrim -= prob.constraint.weights[var] # we substract the weight (non ordered) of the variable that we assigned to one
        lb += prob.objs[1].profits[var] # we add to the primal bound the profit of var
        iterLastOne = var # update iterLastOne
        iter += 1
    end

    # GOAL : check if bestSolPrim is optimal, and if not, calculate a first upper bound
    if iter <= prob.nbVar # at least one object is assigned to zero
        # we can set the upper bound by adding the portion of the next item that can fit inside the knapsack
        ub = lb + (poidsRestPrim / prob.constraint.weights[permList[iter]]) * prob.objs[1].profits[permList[iter]]
    else # all the variables are assigned to one
        # bestSolPrim is optimal
        return Solution(bestSolPrim[revPermList], [lb])
    end

    # GOAL : we finish to go through variables and try to put as many to one.
    # iterating on remaining variables (non ordered), we stop if we don't have any space remaining in the bag
    while iter <= prob.nbVar && poidsRestPrim > 0
        var = permList[iter] # index of the variable (non ordered)
        if prob.constraint.weights[var] <= poidsRestPrim # if the current var feets in the bag
            bestSolPrim[iter] = 1 # assigning the var to one
            poidsRestPrim -= prob.constraint.weights[var] # updating the remaining space in the bag
            lb += prob.objs[1].profits[var] # updating the lower bound because we added a variable
            iterLastOne = var # updating iterLastOne
        end
        iter += 1
    end

    """

    Backtracking

    """
    
    verbose && println("On commence le Backtracking")

    return Solution(bestSolPrim[revPermList], [lb])
    exit()

    if revPermList[iterLastOne] > indEndAssignment # we'll begin the backtracking after the assignment
        sol, lb = backtrack(prob, assignment, indEndAssignment, permList, revPermList, iterLastOne, bestSolPrim, lb, poidsRestPrim, lb, ub, verbose = verbose)
        return Solution(sol[revPermList], [lb])
    else # the backtrack is useless
        return Solution(bestSolPrim[revPermList], [lb])
    end
end

