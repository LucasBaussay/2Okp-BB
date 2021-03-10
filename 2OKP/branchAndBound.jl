
include("1okp.jl")

"""

    Le dernier bug (j'éspère !)

    Quand on créer un sous problème avec moins de variable (B&B), si on veut étudier cette solution par rapport aux autres
    Il faut absolument lui rajouter toutes les variables qu'on lui a enlevé, Faut vraiment être con pour avoir oublier ca
    (Oups !)

"""

"""
    return the λ scalarization of the given problem prob

    @prob : MOKP
    @λ : Vector{Float64}    
"""
function weightedScalarRelax(prob::Problem, λ::Vector{Float64})
    @assert length(λ) == prob.nbObj "Le vecteur λ ne convient pas"

    obj = Vector{Float64}(undef, prob.nbVar) # new merged objective
    # GOAL : calculate the coef of each variable in the new objective by merging all the objectives
    for iterVar = 1:prob.nbVar
        obj[iterVar] = sum([λ[iter] * prob.objs[iter].profits[iterVar] for iter = 1:prob.nbObj])
    end
    # construction of the problem
    return Problem(
        1,
        prob.nbVar,
        [Obj(obj)],
        prob.constraint
    )
end

"""
    return y the point associated with the solution x and the problem prob
"""
function evaluate(prob::Problem, x::Vector{Bool})
    y = zeros(Float64, prob.nbObj)
    # GOAL : calculate the image of x by prob
    for iterObj = 1:prob.nbObj
        for iter = 1:prob.nbVar
            if x[iter]
                y[iterObj] += prob.objs[iterObj].profits[iter]
            end
        end
    end
    # the resulting point
    return Solution(x, y)
end

"""
    whichFathomed(upperBound::DualSet, lowerBound::Vector{Solution}, S::Vector{Solution}, consecutivePoint::Vector{Tuple{Solution, Solution}})

    return the way the subproblem is fathomed : none, infeasibility, optimality, dominance
"""
function whichFathomed(upperBound::DualSet, lowerBound::Vector{Solution}, S::Vector{Solution}, consecutivePoint::Vector{Tuple{Solution, Solution}})
    noNadirUnderUB = true # becomes false if we found a nadir point under the upperBound

    if length(lowerBound) == 0 # no solutions supported
        return infeasibility
    elseif length(lowerBound) == 1 # only one feasible solution
        return optimality
    else
        iterConsecPoint = 0
        while noNadirUnderUB && iterConsecPoint < length(consecutivePoint) # going through the consecutive points
            iterConsecPoint += 1
            solR, solL = consecutivePoint[iterConsecPoint] # getting the two consecutive points
            nadirPoint = [min(solR.y[ind], solL.y[ind]) for ind = 1:length(solR.y)] # constructing the nadir point
            # projection of the nadir point on the constraints of the upper bound
            Ax = upperBound.A * nadirPoint
            # verifying that the nadir point is under each constraint of the upperBound
            indexConstr = 0
            while noNadirUnderUB && indexConstr < length(upperBound.b)
                indexConstr += 1
                noNadirUnderUB = noNadirUnderUB && Ax[indexConstr] > upperBound.b[indexConstr]
            end
        end
        # conclusion on the type of pruning
        if noNadirUnderUB
            return dominance
        else
            return none
        end
    end
end

"""
    updateBounds!(S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, lowerBoundSub::Vector{Solution})

    update upper et lower bound sets according to the new feasible subproblem

    @S : Solution
    @consecutiveSet : Set of tuples of consecutive points
    @lowerBoundSub : Lower bound set for the subproblem
"""

""" LUCAS J'AI DES QUESTIONS SUR LA METHODE GENERALE ???"""
function updateBounds!(S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, lowerBoundSub::Vector{Solution})

    # variables used to memorize where to delete items in consecutiveSet (points that are no longer consecutive because we added some points between them)
    indSuppr       = Vector{Int}(undef, length(consecutiveSet))
    indEndIndSuppr = 0

    for subSol in lowerBoundSub
        for iter = 1:length(consecutiveSet)
            solR, solL = consecutiveSet[iter]
            if subSol.y[1] > min(solR.y[1], solL.y[1]) && subSol.y[2] > min(solR.y[2], solL.y[2]) # subSol dominates the nadir point of solR and solL
                push!(S, subSol) # subSol is a solution
                push!(consecutiveSet, (solR, subSol)) # we update consecutiveSet
                push!(consecutiveSet, (subSol, solL))

                indEndIndSuppr += 1
                indSuppr[indEndIndSuppr] = iter
            end
        end
        # now deleting the previous consecutive points that are no longer consecutive 
        for iter = 1:indEndIndSuppr
            deleteat!(consecutiveSet, indSuppr[iter]-iter+1)
        end
        # reinitializing the variables
        indSuppr = Vector{Int}(undef, length(consecutiveSet)) # maybe there is a better way of doing the initialization... idk
        indEndIndSuppr = 0
    end
end

"""
    newAssignments(A::Vector{Int},i::Int)

    return a tuple of the two vectors : assignments for the two subproblems.
    For the first (copyA), the variable i has been assigned to zero, for the second (A), i has been assigned to one
"""
function newAssignments(A::Vector{Int},i::Int)
    """ VRAIE COPIE ????"""
    copyA = A[1:end]
    copyA[i] = 0
    A[i] = 1
    return copyA, A
end

"""

    En cours de Travaux

"""

"""
    computeBoundDicho(prob::Problem, assignment::Vector{Int}, indEndAssignment::Int, assignmentWeight::Float64, assignmentProfit::Vector{Float64}, ϵ::Float64; verbose = false)

    computes bound dicho

    @prob : current problem
    @assignment : assignment of variables (non ordered) (length = nbVars)
    @indEndAssignment : index of the the last variable (non ordered) assigned in the problem
    @assignmentWeight : sum of the weights of the variables assigned to one
    @assignmentProfit : sum of the profits of the variables assigned to one
    @ϵ : small value to compute the vector lambda and compute the weighted scalarization

    @XSEm - Vector of solutions : memorize all the supported efficient and extreme solutions
    @consecutiveSet : memorize tuples of points that are consecutive
    @S : Queue of tuples of consecutive points to study
"""
function computeBoundDicho(prob::Problem, assignment::Vector{Int}, indEndAssignment::Int, assignmentWeight::Float64, assignmentProfit::Vector{Float64}, ϵ::Float64; verbose = false)

    XSEm = Vector{Solution}() # memorize all the supported efficient and extreme solutions
    consecutiveSet = Vector{Tuple{Solution, Solution}}() # memorize tuples of points that are consecutive
    S = Vector{Tuple{Solution, Solution}}() # queue of solutions to study

    # computing the two first points, sol1 is the best for the only the objective number 1, and sol2 for the objective number 2.
    sol1 = solve1OKP(weightedScalarRelax(prob, [1., ϵ]), assignment, indEndAssignment, assignmentWeight, sum([1., ϵ] .* assignmentProfit), verbose = verbose)
    sol2 = solve1OKP(weightedScalarRelax(prob, [ϵ, 1.]), assignment, indEndAssignment, assignmentWeight, sum([ϵ, 1.] .* assignmentProfit), verbose = verbose)

    # evaluating the two sols and constructing the associated solutions
    sol1 = evaluate(prob, sol1.x)
    sol2 = evaluate(prob, sol2.x)

    # computing the maximum of each objective
    max1 = sol1.y[1] # maximum of objective 1
    max2 = sol2.y[2] # maximum of objective 2

    verbose && println("On crée les solution lexico : $(sol1.y) et $(sol2.y)")

    if sol1.y == sol2.y # solutions are adenticals
        push!(XSEm, sol1)
    else # solutions are different
        push!(S, (sol1, sol2)) # we'll need to study (sol1,sol2)
        push!(XSEm, sol1, sol2) # sol1 and sol2 are supported efficient and extreme solutions

        # goal : compute the dichotomy
        while length(S) != 0 # while we have solutions to study
            solR, solL = pop!(S) # get the two consecutive points from the queue of tuples to study

            verbose && println("On étudie la paire de solution : $(solR.y) et $(solL.y)")
            # computing the direction of the search
            λ = [solL.y[2]-solR.y[2], solR.y[1]-solL.y[1]]
            # computing the resulting solution
            solE = solve1OKP(weightedScalarRelax(prob, λ), assignment, indEndAssignment, assignmentWeight, sum(λ .* assignmentProfit), verbose = false)
            solE = evaluate(prob, solE.x)

            """ SEE BELOW ??? """
            if sum(λ .* solE.y) > sum(λ .* solR.y) # solE is better than solR according to λ
                push!(XSEm, solE) # solE is solution we want
                push!(S, (solR, solE), (solE, solL)) # now we need to study (solR, solE) and (solE, solL)
                verbose && println("On a trouvé la solution : $(solE.y)")
            else # solE is equal to solR according to λ, so we didn't find new solutions 
                push!(consecutiveSet, (solR, solL)) # we know we won't find solutions between solR, solL, so we memorize the tuple 
                verbose && println("On a rien trouvé dans cette direction")
            end
        end
    end

    # GOAL : compute dual bound set
    # we represent the dual bound set not with points because there is an infinity of them but with constraints
    # the dual bound : A.x = B
    A = Array{Float64, 2}(undef, length(consecutiveSet) + 2, 2)
    B = Vector{Float64}(undef, length(consecutiveSet)+2)
    # construction of the maxtrix A and the vector B
    for iter = 1:length(consecutiveSet)
        a, b = consecutiveSet[iter]
        a, b = a.y, b.y
        A[iter, 1] = b[2] - a[2]
        A[iter, 2] = a[1] - b[1]

        B[iter] = (b[2] - a[2]) * a[1] - (b[1] - a[1]) * a[2]
    end

    # finishing the computation by adding the max1, max2 values
    A[end-1, 1] = 1
    A[end-1, 2] = 0
    B[end-1] = max1

    A[end, 1] = 0
    A[end, 2] = 1
    B[end] = max2

    return XSEm, consecutiveSet, DualSet(A, B)
end

"""
    branchAndBound(prob::Problem, assignment::Vector{Int}, assignmentWeight::Float64, assignmentProfit::Vector{Float64}, S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, indEndAssignment::Int = 0, ϵ::Float64 =0.01; verbose = false)

"""
function branchAndBound(prob::Problem, assignment::Vector{Int}, assignmentWeight::Float64, assignmentProfit::Vector{Float64}, S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, indEndAssignment::Int = 0, ϵ::Float64 =0.01; verbose = false)

    #Arranger pour un sous problème
    lowerBoundSub, consecutivePointSub, upperBoundSub = computeBoundDicho(prob, assignment, indEndAssignment, assignmentWeight, assignmentProfit, ϵ, verbose = verbose)

    fathomed::Fathomed = whichFathomed(upperBoundSub, lowerBoundSub, S, consecutiveSet)

    if fathomed != dominance && fathomed != infeasibility
        updateBounds!(S, consecutiveSet, lowerBoundSub)
    end
    if fathomed == none && indEndAssignment<prob.nbVar
        A0, A1 = newAssignments(assignment,indEndAssignment+1) # creating the two assignments for the subproblems : A0 is a copy, A1 == assignment
        verbose && println("Branch and Bound sur la variable $(indEndAssignment+1), on la fixe à 0")
        branchAndBound(prob, A0, assignmentWeight, assignmentProfit, S, consecutiveSet, indEndAssignment+1, ϵ, verbose = verbose) # exploring the first subproblem
        verbose && println()
        verbose && println("Branch and Bound sur la variable $(i+1), on la fixe à 1")

        variableProfit = broadcast(obj->obj.profits[indEndAssignment+1], prob.objs)

        branchAndBound(prob, A1, assignmentWeight + prob.constraint.weights[indEndAssignment+1], assignmentProfit + variableProfit, S, consecutiveSet, indEndAssignment+1, ϵ, verbose = verbose) # exploring the second subproblem
    end
end

"""
    reorderVariable(prob::Problem, reorderVect::Vector{Int})

    returns a new problem ordered with reorderVect
"""
function reorderVariable(prob::Problem, reorderVect::Vector{Int})
    @assert prob.nbVar==length(reorderVect) "Wrong argument for the function reorderVariable"

    return Problem(
        prob.nbObj,
        prob.nbVar,
        [Obj(prob.objs[iter].profits[reorderVect]) for iter=1:prob.nbObj],
        Const(prob.constraint.maxWeight, prob.constraint.weights[reorderVect])
    )
end

"""

    Attention à l'ordre des variables !

"""

"""
    main_BranchandBound(prob::Problem, orderName = "random", ϵ::Float64 = 0.01 ; verbose = false)

    returns the set of non dominated points coputed with the multi objective branch and bound

    @S : XSEm at first, then completed with the branch and bound to become XE
    @consecutivePoints = vector of tiples of consecutive points (the points are the points in S)
"""
function main_BranchandBound(prob::Problem, orderName = "random", ϵ::Float64 = 0.01 ; verbose = false)

    permVect, revPermVect = permOrder(prob, orderName) # order variables accordingly
    auxProb = reorderVariable(prob, permVect) # creating the new ordered problem

    # computing a first dichotomy to obtain a lower bound (the XSEm set, here S)
    S, consecutivePoints = computeBoundDicho(auxProb, Vector{Int}(), 0, 0., zeros(Float64, prob.nbObj), ϵ, verbose = verbose)[1:2]

    # initializing the assignment vector
    assignment = Vector{Int}(undef, prob.nbVar)
    for iter=1:prob.nbVar
        assignment[iter] = -1
    end

    # computing the branch and bound
    branchAndBound(auxProb, assignment, 0., zeros(Float64, prob.nbObj),  S, consecutivePoints, 0, ϵ, verbose = verbose)

    # reorder variables inside items of S
    S = broadcast(sol->Solution(sol.x[revPermVect], sol.y), S)

    return S
end
