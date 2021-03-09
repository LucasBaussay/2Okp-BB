
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

"""

    JULES AREA

"""

"""
    returns the inverse permutation of the given permutation vector
"""
function revPerm(p::Vector{Int})
    revP = Vector{Int}(undef, length(p))
    for iter = 1:length(p)
        revP[p[iter]] = iter
    end
    return revP
end

"""
    construct and returns the subproblem associated with the given problem and assignment
"""
function createSubProblem(prob::Problem, assignment::Vector{Int}, indEndAssignment::Int; verbose = false)
    verbose && println("[createSubProblem]")
    newNbVars = prob.nbVar - indEndAssignment # new number of variables
    newObjs = Vector{Obj}(undef, prob.nbObj) # new objectives
    for indexObj in 1:length(prob.objs) # going through objectives
        obj = prob.objs[indexObj] # current objetive
        newObj = Vector{Float64}(undef, newNbVars) # new objective, replacing obj
        for indexVar in 1:newNbVars # iterating on the variables not assigned
            newObj[indexVar] = obj[indexVar+indEndAssignment] # filling newObj
        end
        newObjs[indexObj] = newObj
    end
    # result : newObjs contains the new objectives

    newWeightConstr = prob.constraint.maxWeight - assignmentWeight # new max capa
    newWeights = Vector{Float64}(undef,newNbVars) # new vector of weights in the constraint
    for indexVar in 1:newNbVars
        newWeights[indexVar] = prob.constraint.weights[indexVar+indEndAssignment]
    end
    newConstr = Const(newWeightConstr,newWeights)
    # result : newConst is the new constraint for the subproblem

    # creation of the subproblem
    subProb = Problem(prob.nbObj,newNbVars,newObjs,newConstr)
    verbose && println("[END - createSubProblem]")
    return subProb
end

"""
    solve1OKPAux(prob::Problem, assignment::Vector{Int}, indEndAssignment::Int = 0, assignmentWeight::Float64 = 0., assignmentProfit::Float64 = 0.; verbose = false)
    
    Solve the 1OKP

    [PARAMETERS]

    @prob : 1OKP to solve
    {
        @prob.nbObjs : always the same as the superProblem
        @prob.nbVars : number of vars of the subProblem and not the superProblem
        @prob.objs : vector of the objectives of the subProblem. Each objective is adapted to the subProblem (same number of variables)
        @prob.constraint : constraint of the subProblem, not the same as the superProblem
        {
            @prob.constraint.maxWeight : equal to maxWeight of the superP minus the assignmentWeight !
            @prob.constraint.weights : adapted to the subProblem, less variables.
        }
    }
    @assignment : array of assignments (of length the original number of variables), indicating the values of the previous variables (non ordered)
    @indEndAssignment : index of the last assigned variable (non ordered)
    @assignmentWeight : the sum of the weights of the variables assigned to one
    @assignmentProfit : the sum of the profits of the variables assigned to one

    [VARIABLES]

    @p : permutation to order variables. p[1] indicate the first best variable.
    @revP : inverse permutation of p.
    @weightRemaining : weight remaining in the bag (take into account the assignment weight of course)
    @bestSolPrim : current best primal solution (indexed on ordered variables) : bestSolPrim[1] targets the first best variable.
    @iterLastOne : index (ordered) of the last variable assigned to one in @bestSolPrim
    @indexFirstNotAssignedOV : index (ordered) of the first variable not assigned
"""
function solve1OKPAux(prob::Problem, assignment::Vector{Int}, indEndAssignment::Int = 0, assignmentWeight::Float64 = 0., assignmentProfit::Float64 = 0.; verbose = false)
    verbose && println("[solve1OKPMain]")
    # permutation list sorting the variables. Beginning with the best ones, ending with worsts.
    # usage : p[1] gives the index of the first best variable
    p = sortperm(prob.objs[1].profits ./ prob.constraint.weights, rev = true)
    # inverse permutation list allowing to get back to the original indexes of the variables
    revP = revPerm(p)

    lb = 0. + assignmentProfit # profit we are sure to make because the solution is feasible
    ub = Inf

    weightRemaining = prob.constraint.maxWeight

    """

    Construction of a good first feasible solution being our LowerBound. We calculate our UpperBound by adding a portion of the next item.

    """

    bestSolPrim = zeros(Bool, prob.nbVar) # current best primal solution (indexed on ordered variables) : bestSolPrim[1] targets the first best variable.
    indexFirstNotAssignedOV = 1 # index (ordered) of the first variable not assigned
    iterLastOne = 0 # index (ordered) of the last variable assigned to one in @bestSolPrim
    # GOAL : inside bestSolPrim, we want to force to one all the first variables (ordered) that could fit in the knapsack
    # iterating on the best variables first. We stop if we can't assign the next variable to one. 
    while indexFirstNotAssignedOV <= prob.nbVar && prob.constraint.weights[p[indexFirstNotAssignedOV]] <= weightRemaining
        orderedVar = p[indexFirstNotAssignedOV] # index of the variable (ordered)
        bestSolPrim[indexFirstNotAssignedOV] = 1 # we put the variable to one in the current solution
        weightRemaining -= prob.constraint.weights[orderedVar] # we substract the weight (non ordered) of the variable that we assigned to one
        lb += prob.objs[1].profits[orderedVar] # we add to the primal bound the profit of var
        iterLastOne = indexFirstNotAssignedOV # update iterLastOne
        indexFirstNotAssignedOV += 1
    end

    # GOAL : check if bestSolPrim is optimal, and if not, calculate a first upper bound
    if indexFirstNotAssignedOV <= prob.nbVar # at least one object is assigned to zero
        # we can set the upper bound by adding the portion of the next item that can fit inside the knapsack
        ub = lb + (weightRemaining / prob.constraint.weights[p[indexFirstNotAssignedOV]]) * prob.objs[1].profits[p[indexFirstNotAssignedOV]]
    else # all the variables are assigned to one
        # bestSolPrim is optimal
        verbose && println("[END - solve1OKPAux]")
        return reconstructSuperSolution(Solution(bestSolPrim[revP], [lb]), assignment, indEndAssignment, assignmentProfit, verbose=verbose)
    end

    # GOAL : we finish to go through variables and try to put as many to one.
    # iterating on remaining variables (ordered), we stop if we don't have any space remaining in the bag
    while indexFirstNotAssignedOV <= prob.nbVar && weightRemaining > 0
        orderedVar = p[indexFirstNotAssignedOV] # index of the variable (non ordered)
        if prob.constraint.weights[orderedVar] <= weightRemaining # if the current var fits in the bag
            bestSolPrim[indexFirstNotAssignedOV] = 1 # assigning the var to one
            weightRemaining -= prob.constraint.weights[orderedVar] # updating the remaining space in the bag
            lb += prob.objs[1].profits[orderedVar] # updating the lower bound because we added a variable
            iterLastOne = indexFirstNotAssignedOV # updating iterLastOne
        end
        indexFirstNotAssignedOV += 1
    end

    """

    Backtracking or End

    """

    if iterLastOne >= 1 # we'll begin the backtracking after the assignment
        sol, lb = backtrackJules(prob, p, revP, iterLastOne, bestSolPrim, lb, weightRemaining, lb, ub, verbose = verbose)
        verbose && println("[END - solve1OKPAux]")
        return reconstructSuperSolution(Solution(sol[revP], [lb]), assignment, indEndAssignment, assignmentProfit, verbose=verbose)
    else # the backtrack is useless
        verbose && println("[END - solve1OKPAux]")
        return reconstructSuperSolution(Solution(bestSolPrim[revP], [lb]), assignment, indEndAssignment, assignmentProfit, verbose=verbose)
    end
end

"""
    returns the solution of the initial super problem, from a given solution and assignment for a subProblem
"""
function reconstructSuperSolution(solution::Solution, assignment::Vector{Int}, indEndAssignment::Int, assignmentProfit::Float64; verbose = false)
    verbose && println("[reconstructSuperSolution]")
    if indEndAssignment != 0
        nbVarsInSuperP = length(solution.x) + indEndAssignment
        newX = Vector{Bool}(undef,nbVarsInSuperP)
        # construction of newX
        for indexVar in 1:nbVarsInSuperP
            if indexVar <= indEndAssignment
                newX[indexVar] = assignment[indexVar]
            else
                newX[indexVar] = solution.x[indexVar-indEndAssignment]
            end
        end
        # result : newX is the new x
        newY = solution.y + assignmentProfit
        verbose && println("[END - reconstructSuperSolution]")
        return Solution(newX,newY)
    else
        verbose && println("[END - reconstructSuperSolution]")
        return solution
    end
end

"""
    solve1OKPMain(prob::Problem, assignment::Vector{Int} = Vector{Int}(), indEndAssignment::Int = 0, assignmentWeight::Float64 = 0., assignmentProfit::Float64 = 0.; verbose = false)
    
    Transform the problem into a subproblem and call solve1OKPAux on it

    @prob : 1OKP to solve (the sub problems have the same number of variables)
    @assignment : array of assignments (of length n) (ordered)
    @indEndAssignment : index of the last assigned variable (ordered)
    @assignmentWeight : the sum of the weights of the variables assigned to one
    @assignmentProfit : the sum of the profits of the variables assigned to one
"""
function solve1OKPMain(prob::Problem, assignment::Vector{Int} = Vector{Int}(), indEndAssignment::Int = 0, assignmentWeight::Float64 = 0., assignmentProfit::Float64 = 0.; verbose = false)
    @assert prob.nbObj == 1 "This problem is no 1OKP"
    verbose && println("[solve1OKPMain]")

    # if the assignment is empty, we initialize the array at a size of nbVars in prob
    if assignment == []
        verbose && println("[END - solve1OKPMain]")
        return solve1OKPAux(prob,assignment,indEndAssignment,assignmentWeight,assignmentProfit,verbose=verbose)
    else
        # creation of the subproblem
        subProb = createSubProblem(prob,assignment,indEndAssignment, verbose=verbose)
        print(subProb)
        verbose && println("[END - solve1OKPMain]")
        return solve1OKPAux(prob,assignment,indEndAssignment,assignmentWeight,assignmentProfit,verbose=verbose)
    end
end

"""
    backtrackJules(prob::Problem, p::Vector{Int}, revP::Vector{Int}, indexOnOrdered::Int, bestSolPrim::Vector{Bool}, currentLB::Float64, weightRemaining::Float64, lb::Float64, ub::Float64; verbose = false)

    returns ...

    [PARAMETERS]

    @prob : 1OKP to solve
    {
        @prob.nbObjs : always the same as the superProblem
        @prob.nbVars : number of vars of the subProblem and not the superProblem
        @prob.objs : vector of the objectives of the subProblem. Each objective is adapted to the subProblem (same number of variables)
        @prob.constraint : constraint of the subProblem, not the same as the superProblem
        {
            @prob.constraint.maxWeight : equal to maxWeight of the superP minus the assignmentWeight !
            @prob.constraint.weights : adapted to the subProblem, less variables.
        }    
    }

    @p : permutation to order variables. p[1] indicate the first best variable.
    @revP : inverse permutation of p.
    @indexOnOrdered : index of the backtrack (going through the ordered vector)
    @bestSolPrim : current best primal solution (indexed on ordered variables) : bestSolPrim[1] targets the first best variable.
    @currentLB : current lb
    @weightRemaining : space left in the bag
    @lb : best lower bound
    @ub : best upper bound
"""
function backtrackJules(prob::Problem, p::Vector{Int}, revP::Vector{Int}, indexOnOrdered::Int, bestSolPrim::Vector{Bool}, currentLB::Float64, weightRemaining::Float64, lb::Float64, solLB::Vector{Bool}, ub::Float64; verbose = false)
    verbose && println("[backtrackJules] - indexOnOrdered = $indexOnOrdered, bestSolPrim = $bestSolPrim, bestSolPrim[revP] = $(bestSolPrim[revP])")

    if indexOnOrdered == 0 || lb == ub # stopping rule, end of study or optimality
    verbose && println("[END - backtrackJules]")
        return bestSolPrim, lb
    elseif bestSolPrim[indexOnOrdered] == 0 # we can't test anything here because the item is not assigned to one, we backtrackJules with indexOnOrdered-1
        verbose && println("[RECURSIVE CALL - backtrackJules]")
        return backtrackJules(prob, p, revP, indexOnOrdered-1, bestSolPrim, currentLB, weightRemaining, lb, solLB, ub, verbose = verbose)
    else # we are somewhere in the oredered list and we indexOnOrdered targets a item assigned to one
        iterLastOne = prob.nbVar # initialization of iterLastOne 

        verbose && println("\n- On tente d'améliorer en fixant x_$(p[indexOnOrdered]) (non ordered) à 0")

        # GOAL : improve current solution by assigning the variable p[indexOnOrdered] to zero.
        sol = falses(prob.nbVar-indexOnOrdered) # sol keep track of the current solution we are building
        currentWeightRemaining = weightRemaining + prob.constraint.weights[p[indexOnOrdered]] # because we took an item out of the bag
        currentProfit = currentLB - prob.objs[1].profits[p[indexOnOrdered]]
        currentUB = Inf

        verbose && println("\n- Forcing first variables that can fit into the bag")
        # GOAL : force the next variables (ordered). This will help us calculate a new upper bound.
        # we stop when the next item can't fit in the bag
        indexBrokenOV = indexOnOrdered+1 # the item indexOnOrdered has to stay assigned to zero
        while indexBrokenOV <= prob.nbVar && prob.constraint.weights[p[indexBrokenOV]] <= currentWeightRemaining
            verbose && println("    (forcing $(p[indexBrokenOV]))")
            sol[indexBrokenOV - indexOnOrdered] = 1 # we assign the item to one
            currentWeightRemaining -= prob.constraint.weights[p[indexBrokenOV]] # the remaining weight decreases 
            currentProfit += prob.objs[1].profits[p[indexBrokenOV]] # the profit increases
            iterLastOne = indexBrokenOV
            indexBrokenOV += 1
        end
        # result : indexBrokenOV targets the broken item in ordered list

        verbose && println("    -> new broken item (non ordered) = $(p[indexBrokenOV])")

        verbose && println("\n- updating currentLB")
        if indexBrokenOV <= prob.nbVar # at least the last variable (ordered) is assigned to zero, we can add a portion of the next item assigned to zero to get a UB.
            currentUB = currentProfit + (currentWeightRemaining / prob.constraint.weights[p[indexBrokenOV]]) * prob.objs[1].profits[p[indexBrokenOV]]
        else # all the next variables are assigned to one. The UB is the 
            currentUB = currentProfit
        end
        # result : currentUB is the upper bound of the current sol

        verbose && println("    -> the current UB : $currentUB, best LB : $lb")

        if currentUB > lb # the new solution could be better than the old one 

            verbose && println("\n- currentUB > lb -> Le sous problème est peut-être améliorant ! ")

            verbose && println("\n- Forcing the rest of the items that fit inside the bag")
            # GOAL : Calculate the current LowerBound by forcing the rest of the items that fit in the bag to one.
            while indexBrokenOV <= prob.nbVar && currentWeightRemaining != 0
                if prob.constraint.weights[p[indexBrokenOV]] <= currentWeightRemaining
                    verbose && println("    (forcing $(p[indexBrokenOV]))")
                    sol[indexBrokenOV - indexOnOrdered] = 1 # the item is set to one
                    currentWeightRemaining -= prob.constraint.weights[p[indexBrokenOV]] # the remaining weight decreases 
                    currentProfit += prob.objs[1].profits[p[indexBrokenOV]] # the profit increases
                    iterLastOne = indexBrokenOV
                end
                indexBrokenOV += 1
            end
            # result : indexBrokenOV doesn't target a item in particular ! Could be a broken item or the end of the list.
            #        : currentProfit is the new current lb
            verbose && println("    -> currentProfit is the new current lb, currentProfit = $currentProfit")

            if currentProfit > lb # comparing the new lower bound to the new one

                verbose && println("\n- currentProfit > lb -> YEY we have made a progress : from $lb to $currentProfit")

                verbose && println("\n- Update time(lb,bestSolPrim,indexOnOrdered,weightRemaining")
                lb = currentProfit # updating lb
                bestSolPrim[indexOnOrdered] = 0 # putting indexOnOrdered item to zero was a good choice, so we update bestSolPrim accordingly
                bestSolPrim[indexOnOrdered+1:end] = sol[1:end] # bestSolPrim copy the solution saved in the vector sol
                indexOnOrdered = iterLastOne
                weightRemaining = currentWeightRemaining

                # we start a new backtrack, starting from the last one value
                verbose && println("[RECURSIVE CALL - backtrackJules]")
                return backtrackJules(prob, p, revP, indexOnOrdered, bestSolPrim, lb, weightRemaining, lb, solLB, ub, verbose = verbose)
            else # the new solution is not better
                verbose && println("\n- The new solution is not better, we keep backtracking\n")
                # we free the variable indexOnOrdered, so the lb and weightRemaining are updated
                newCurrentLB = currentLB - prob.objs[1].profits[p[indexOnOrdered]]
                newWeightRemaining = weightRemaining + prob.constraint.weights[p[indexOnOrdered]]
                verbose && println("[RECURSIVE CALL - backtrackJules]")
                return backtrackJules(prob, p, revP, indexOnOrdered-1, bestSolPrim, newCurrentLB, newWeightRemaining, lb, solLB, ub, verbose = verbose)
            end
        else # there is no way the new solution can be better than the old one
            verbose && println("The new solution can't be better, we keep backtracking\n")
            # we free the variable indexOnOrdered, so the lb and weightRemaining are updated
            newCurrentLB = currentLB - prob.objs[1].profits[p[indexOnOrdered]]
            newWeightRemaining = weightRemaining + prob.constraint.weights[p[indexOnOrdered]]
            verbose && println("[RECURSIVE CALL - backtrackJules]")
            return backtrackJules(prob, p, revP, indexOnOrdered-1, bestSolPrim, newCurrentLB, newWeightRemaining, lb, solLB, ub, verbose = verbose)
        end
    end
end

function branchAndBoundJules(prob::Problem, p::Vector{Int}, revP::Vector{Int}, indexOnOrdered::Int, bestSolPrim::Vector{Bool}, currentLB::Float64, weightRemaining::Float64, lb::Float64, ub::Float64; verbose = false)

end