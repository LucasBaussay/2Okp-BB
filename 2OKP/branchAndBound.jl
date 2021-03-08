
include("1okp.jl")

"""

    Le dernier bug (j'éspère !)

    Quand on créer un sous problème avec moins de variable (B&B), si on veut étudier cette solution par rapport aux autres
    Il faut absolument lui rajouter toutes les variables qu'on lui a enlevé, Faut vraiment être con pour avoir oublier ca
    (Oups !)

"""

# return the λ scalarization of the problem prob
function weightedScalarRelax(prob::Problem, λ::Vector{Float64})
    @assert length(λ) == prob.nbObj "Le vecteur λ ne convient pas"

    obj       = Vector{Float64}(undef, prob.nbVar)
    # calculate the coefs of each variable by merging all the objectives
    for iterVar = 1:prob.nbVar
        obj[iterVar] = sum([λ[iter] * prob.objs[iter].profits[iterVar] for iter = 1:prob.nbObj])
    end

    return Problem(
        1,
        prob.nbVar,
        [Obj(obj)],
        prob.constraint
    )
end

# return y the point associated with the solution x and the problem prob
function evaluate(prob::Problem, x::Vector{Bool})
    y = zeros(Float64, prob.nbObj)
    for iterObj = 1:prob.nbObj
        for iter = 1:prob.nbVar
            if x[iter]
                y[iterObj] += prob.objs[iterObj].profits[iter]
            end
        end
    end

    # the resulting point
    return y
end

# temporary test function
function testBandB(P::Problem)
    print(P)
    A = [-1,-1,-1]
    branchAndBound(P,A,1,[0])
    print("end")
end

# return the way the subproblem is fathomed : none, infeasibility, optimality, dominance
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

# update upper et lower bound sets according to the new feasible subproblem
function updateBounds!(S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, lowerBoundSub::Vector{Solution})

    indSuppr       = Vector{Int}(undef, length(consecutiveSet))
    indFinIndSuppr = 0

    for subSol in lowerBoundSub
        for iter = 1:length(consecutiveSet)
            solR, solL = consecutiveSet[iter]
            if subSol.y[1] > min(solR.y[1], solL.y[1]) && subSol.y[2] > min(solR.y[2], solL.y[2])
                push!(S, subSol)
                push!(consecutiveSet, (solR, subSol))
                push!(consecutiveSet, (subSol, solL))

                indFinIndSuppr += 1
                indSuppr[indFinIndSuppr] = iter
            end
        end
        for iter = 1:indFinIndSuppr
            deleteat!(consecutiveSet, indSuppr[iter]-iter+1)
        end
        indSuppr = Vector{Int}(undef, length(consecutiveSet))
        indFinIndSuppr = 0
    end
end

# return a tuple of the two vectors : assignments for the two subproblems
function newAssignments(A::Vector{Int},i::Int)
    copyA = A[1:end]
    copyA[i] = 0
    A[i] = 1
    return copyA, A
end

"""

    En cours de Travaux

"""

function computeBoundDicho(prob::Problem, assignment::Vector{Int}, indAssignment::Int, assignmentWeight::Float64, assignmentProfit::Vector{Float64}, ϵ::Float64; verbose = false)

    XSEm = Vector{Solution}()
    consecutiveSet = Vector{Tuple{Solution, Solution}}()
    S = Vector{Tuple{Solution, Solution}}()
    #J'en suis là pour le moment
    sol1 = solve1OKP(weightedScalarRelax(prob, [1., ϵ]), assignment, indAssignment, assignmentWeight, sum([1., ϵ] .* assignmentProfit), verbose = verbose)
    sol2 = solve1OKP(weightedScalarRelax(prob, [ϵ, 1.]), assignment, indAssignment, assignmentWeight, sum([ϵ, 1.] .* assignmentProfit), verbose = verbose)

    sol1 = evaluate(prob, sol1.x)
    sol2 = evaluate(prob, sol2.x)

    max1 = sol1.y[1]
    max2 = sol2.y[2]

    verbose && println("On créer les solution lexico : $(sol1.y) et $(sol2.y)")

    if sol1.y == sol2.y
        push!(XSEm, sol1)
    else
        push!(S, (sol1, sol2))
        push!(XSEm, sol1, sol2)

        indFunc = 1
        while length(S) != 0

            solR, solL = pop!(S)
            verbose && println("On étudie la paire de solution : $(solR.y) et $(solL.y)")
            λ = [solL.y[2]-solR.y[2], solR.y[1]-solL.y[1]]
            solE = solve1OKP(weightedScalarRelax(prob, λ), assignment, indAssignment, assignmentWeight, sum(λ .* assignmentProfit), verbose = false)

            solE = evaluate(prob, solE.x)

            if sum(λ .* solE.y) > sum(λ .* solR.y)
                push!(XSEm, solE)
                push!(S, (solR, solE), (solE, solL))
                verbose && println("On a trouvé la solution : $(solE.y)")
            else
                push!(consecutiveSet, (solR, solL))
                verbose && println("On a rien trouvé dans cette direction")
            end
            verbose && println()

            indFunc += 1
        end
    end

    A = Array{Float64, 2}(undef, length(consecutiveSet) + 2, 2)
    B = Vector{Float64}(undef, length(consecutiveSet)+2)

    for iter = 1:length(consecutiveSet)
        a, b = consecutiveSet[iter]
        a, b = a.y, b.y
        A[iter, 1] = b[2] - a[2]
        A[iter, 2] = a[1] - b[1]

        B[iter] = (b[2] - a[2]) * a[1] - (b[1] - a[1]) * a[2]
    end

    A[end-1, 1] = 1
    A[end-1, 2] = 0
    B[end-1] = max1

    A[end, 1] = 0
    A[end, 2] = 1
    B[end] = max2

    return XSEm, consecutiveSet, DualSet(A, B)

end

function branchAndBound(prob::Problem, assignment::Vector{Int}, assignmentWeight::Float64, assignmentProfit::Vector{Float64}, S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, indAssignment::Int = 0, ϵ::Float64 =0.01; verbose = false)

    #Arranger pour un sous problème
    lowerBoundSub, consecutivePointSub, upperBoundSub = computeBoundDicho(prob, assignment, indAssignment, assignmentWeight, assignmentProfit, ϵ, verbose = verbose)

    fathomed::Fathomed = whichFathomed(upperBoundSub, lowerBoundSub, S, consecutiveSet)

    if fathomed != dominance && fathomed != infeasibility
        updateBounds!(S, consecutiveSet, lowerBoundSub)
    end
    if fathomed == none && i<prob.nbVar
        A0, A1 = newAssignments(assignment,indAssignment+1) # creating the two assignments for the subproblems : A0 is a copy, A1 == assignment
        verbose && println("Branch and Bound sur la variable $(indAssignment+1), on la fixe à 0")
        branchAndBound(prob, A0, assignmentWeight, assignmentProfit, S, consecutiveSet, indAssignment+1, ϵ, verbose = verbose) # exploring the first subproblem
        verbose && println()
        verbose && println("Branch and Bound sur la variable $(i+1), on la fixe à 1")

        variableProfit = broadcast(obj->obj.profits[indAssignment+1], prob.objs)

        branchAndBound(prob, A1, assignmentWeight + prob.constraint.weights[indAssignment+1], assignmentProfit + variableProfit, S, consecutiveSet, indAssignment+1, ϵ, verbose = verbose) # exploring the second subproblem
    end
end

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

function main_BranchandBound(prob::Problem, orderName = "random", ϵ::Float64 = 0.01 ; verbose = false)

    permVect, revPermVect = permOrder(prob, orderName)
    auxProb = reorderVariable(prob, permVect)

    S, consecutivePoint, weDontNeedItHere = computeBoundDicho(auxProb, ϵ, verbose = verbose)

    assignment = Vector{Int}(undef, prob.nbVar)
    for iter=1:prob.nbVar
        assignment[iter] = -1
    end

    branchAndBound(auxProb, assignment, S, consecutivePoint, 0, ϵ, verbose = verbose)

    broadcast!(sol->Solution(sol.x[revPerm], sol.y), S)

    return S
end
