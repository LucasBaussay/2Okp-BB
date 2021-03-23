import Random

@enum Fathomed none dominance infeasibility optimality


#Léane's algorithm

try
    include("../1OKP_Leane/structKP.jl")
catch end
include("../1OKP_Leane/projetFinal.jl")


#Jules' Algorithm


include("dataStruct.jl")
include("pretrait.jl")
include("branchAndBound.jl")



"""

    New part : Trying to be iterative and mutable to other method !

"""

function solve1Okp(prob::Problem, id::Int = -1; verbose = false)

    @assert prob.nbObj == 1 "This problem is no 1OKP"
    weightSum = sum(prob.constraint.weights)

    resPretrait = true
    for iter = 1:prob.nbVar
        resPretrait = resPretrait && prob.constraint.weights[iter] > prob.constraint.maxWeight
    end

    if weightSum < prob.constraint.maxWeight
        return Solution(trues(prob.nbVar), [sum(prob.objs[1].profits)], weightSum, id)
    elseif resPretrait
        return Solution(falses(prob.nbVar), [0], 0, id)
    else
        # verbose && println("On solve avec l'algo de Léane : $prob")

        ListObj = [Objet(prob.objs[1].profits[iter], prob.constraint.weights[iter], iter) for iter = 1:prob.nbVar]

        sol = main1Okp(ListObj, prob.constraint.maxWeight)

        # verbose && println("On obtient : $sol")

        return Solution(Bool.(sol.X), [sol.z], sum(sol.X .* prob.constraint.weights), id)
    end

end

function weightedScalarRelax(prob::Problem, λ::Vector{Int})
    @assert length(λ) == prob.nbObj "Le vecteur λ ne convient pas"

    obj = Vector{Int}(undef, prob.nbVar) # new merged objective
    # GOAL : compute the coef of each variable in the new objective by merging all the objectives
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

function evaluate(prob::Problem, x::Vector{Bool})
    y = zeros(Int, prob.nbObj)
    w = 0
    # GOAL : computing the image of x by prob
    for iterObj = 1:prob.nbObj
        for iter = 1:prob.nbVar
            if x[iter]
                y[iterObj] += prob.objs[iterObj].profits[iter]
                w += prob.constraint.weights[iter]
            end
        end
    end
    for iter = 1:prob.nbVar
        if x[iter]
            w += prob.constraint.weights[iter]
        end
    end
    # the resulting point
    return Solution(x, y, w)
end

function evaluateLinear(prob::Problem, x::Vector{Float64})
    y = zeros(Float64, prob.nbObj)
    weight = 0
    # GOAL : computing the image of x by prob
    for iterObj = 1:prob.nbObj
        for iter = 1:prob.nbVar
            if x[iter] > 0
                y[iterObj] += prob.objs[iterObj].profits[iter] * x[iter]
                weight += prob.constraint.weights[iter] * x[iter]
            end
        end
    end
    # the resulting point
    return Solution(x, y, weight/2, 1)
end

function whichFathomed(upperBound::DualSet, lowerBound::Vector{Solution}, consecutiveSet::Vector{PairOfSolution})

    noNadirUnderUB = true

    nadirPointToStudy = Vector{PairOfSolution}()

    if length(lowerBound) == 0 # no solutions supported
        return infeasibility, Vector{Solution}()
    elseif length(lowerBound) == 1 # only one feasible solution
        return optimality, Vector{Solution}()
    else
        for iter = 1:length(consecutiveSet) # going through the consecutive points
            testOneNadir = true # becomes false the nadir point is under the upperBound
            pair = consecutiveSet[iter]

            nadirPoint = [min(pair.sol1.y[ind], pair.sol2.y[ind]) for ind = 1:length(pair.sol1.y)] # constructing the nadir point
            # projection of the nadir point on the constraints of the upper bound
            Ax = upperBound.A * nadirPoint
            # verifying that the nadir point is under each constraint of the upperBound
            indexConstr = 0
            while testOneNadir && indexConstr < length(upperBound.b)
                indexConstr += 1
                testOneNadir = testOneNadir && Ax[indexConstr] > upperBound.b[indexConstr]
            end
            if !testOneNadir
                push!(nadirPointToStudy, pair)
            end

            noNadirUnderUB = noNadirUnderUB && testOneNadir
        end
        # conclusion on the type of pruning
        if noNadirUnderUB
            return dominance, Vector{Solution}()
        else
            return none, nadirPointToStudy
        end
    end
end

function subProb(prob::Problem, assignment::Assignment)

    return Problem(
        prob.nbObj,
        prob.nbVar - assignment.indEndAssignment,
        Obj.(broadcast(obj -> obj.profits[(assignment.indEndAssignment+1):end], prob.objs)),
        Const(prob.constraint.maxWeight - assignment.weight, prob.constraint.weights[(assignment.indEndAssignment+1):end])
    )

end

function createSuperSol(sol::Solution, assignment::Assignment, id::Int)
    if assignment.indEndAssignment != 0
        return Solution(
            append!(assignment.assignment[1:assignment.indEndAssignment], sol.x),
            sol.y + assignment.profit,
            sol.weight + assignment.weight,
            id
        )
    else
        return Solution(
            sol.x,
            sol.y,
            sol.weight,
            id
        )
    end
end

function createSuperSol(sol::Solution, assignment::Assignment)
    return createSuperSol(sol, assignment, sol.id)
end

function linearRelax(prob::Problem, assign::Assignment, indEndAssignment::Int = 0, obj::Int=1, verbose = true)

    for sol in subExtremPoints

        #Tout d'abord on check la domination d'un point
        iter = 1
        foundSolDom = false
        while iter <= length(lowerBound) && !foundSolDom
            anotherSol = lowerBound[iter]

            if sol > anotherSol
                foundSolDom = true
                nbPair = 0
                iterPair = 1
                while iterPair <= length(consecutiveSet) && nbPair < 2
                    pair = consecutiveSet[iterPair]
                    if pair.sol1 == anotherSol
                        consecutiveSet[iterPair] = PairOfSolution(sol, pair.sol2)
                        nbPair += 1
                    elseif pair.sol2 == anotherSol
                        consecutiveSet[iterPair] = PairOfSolution(pair.sol1, sol)
                        nbPair += 1
                    end
                    iterPair += 1
                end
            end
            iter += 1
        end

        if !foundSolDom
            iter = 1
            foundNadirDom = false

            while iter < length(consecutiveSet) && !foundNadirDom
                 pair = consecutiveSet[iter]
                 if sol > pair
                     foundNadirDom = true

                     consecutiveSet[iter] = PairOfSolution(pair.sol1, sol)
                     push!(consecutiveSet, PairOfSolution(sol, pair.sol2))
                     push!(lowerBound, sol)
                 end
                 iter += 1
             end
        end
    end

end

function computeLowerBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{PairOfSolution}, mainProb::Problem, assignment::Assignment = Assignment(); M::Int = 1000, verbose = false)

    verbose && println("On calcul la lowerbound pour l'assignement : $(assignment.assignment)")

    prob = subProb(mainProb, assignment)
    verbose && println("Le problème auxiliaire équivaut à $prob ")

    assignment.indEndAssignment == 0 ? assignment = Assignment(Vector{Int}(), 0, zeros(Int, mainProb.nbObj), 0, Vector{PairOfSolution}()) : nothing

    S = Vector{Tuple{Solution, Solution}}()

    # computing the two first points, sol1 is the best for the only the objective number 1, and sol2 for the objective number 2.
    sol1 = solve1Okp(weightedScalarRelax(prob, [M, 1]), 1, verbose = verbose)
    sol2 = solve1Okp(weightedScalarRelax(prob, [1, M]), 2, verbose = verbose)

    # evaluating the two sols and constructing the associated solutions
    sol1 = evaluate(prob, sol1.x)
    sol2 = evaluate(prob, sol2.x)

    verbose && println("On crée les solution lexico : $(sol1.y .+ assignment.profit) et $(sol2.y .+ assignment.profit)")

    if sol1.y == sol2.y # solutions are identicals
        push!(lowerBound, createSuperSol(sol1, assignment))
    else # solutions are different
        push!(S, (sol1, sol2)) # we'll need to study (sol1,sol2)
        superSol1 = createSuperSol(sol1, assignment)
        superSol2 = createSuperSol(sol2, assignment)
        push!(lowerBound, superSol1, superSol2) # sol1 and sol2 are supported efficient and extreme solutions

        # goal : compute the dichotomy
        while length(S) != 0 # while we have solutions to study
            solR, solL = pop!(S) # get the two consecutive points from the queue of tuples to study

            verbose && println("On étudie la paire de solution : $(solR.y .+ assignment.profit) et $(solL.y .+ assignment.profit)")
            # computing the direction of the search
            λ = [solL.y[2]-solR.y[2], solR.y[1]-solL.y[1]]
            # computing the resulting solution
            solE = solve1Okp(weightedScalarRelax(prob, λ), length(lowerBound)+1, verbose = verbose)
            solE = evaluate(prob, solE.x)

            if sum(λ .* solE.y) > sum(λ .* solR.y) # solE is better than solR according to λ
                push!(lowerBound, createSuperSol(solE, assignment)) # solE is solution we want
                push!(S, (solR, solE), (solE, solL)) # now we need to study (solR, solE) and (solE, solL)
                verbose && println("On a trouvé la solution : $(solE.y .+ assignment.profit)")
            else # solE is equal to solR according to λ, so we didn't find new solutions
                push!(consecutiveSet, PairOfSolution(createSuperSol(solR, assignment), createSuperSol(solL, assignment), length(consecutiveSet)+1)) # we know we won't find solutions between solR, solL, so we memorize the tuple
                verbose && println("On a rien trouvé dans cette direction")
            end
        end
    end
end

function computeUpperBound(consecutiveSet::Vector{PairOfSolution})

    A = Array{Union{Int, Float64}, 2}(undef, length(consecutiveSet) + 2, 2)
    B = Vector{Union{Int, Float64}}(undef, length(consecutiveSet)+2)

    max1 = 0
    max2 = 0
    # construction of the maxtrix A and the vector B
    for iter = 1:length(consecutiveSet)
        pair = consecutiveSet[iter]
        a, b = pair.sol1.y, pair.sol2.y
        A[iter, 1] = b[2] - a[2]
        A[iter, 2] = a[1] - b[1]

        B[iter] = (b[2] - a[2]) * a[1] - (b[1] - a[1]) * a[2]

        if a[1] > b[1]
            if a[1] > max1
                max1 = a[1]
            end
        else
            if b[1] > max1
                max1 = b[1]
            end
        end
        if a[2] > b[2]
            if a[2] > max2
                max2 = a[2]
            end
        else
            if b[2] > max2
                max2 = b[2]
            end
        end
    end

    # finishing the computation by adding the max1, max2 values
    A[end-1, 1] = 1
    A[end-1, 2] = 0
    B[end-1] = max1

    A[end, 1] = 0
    A[end, 2] = 1
    B[end] = max2

    return DualSet(A, B)
end

function branchAndBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{PairOfSolution}, prob::Problem, withConvex::Bool; M = 1000, verbose = false)

    verbose && println("On commence les itérations sur le B&B\n")

    """
        Initalisation of the variables
    """
    listOfAssignment = Vector{Assignment}()
    push!(listOfAssignment, Assignment([1], consecutiveSet, prob))
    push!(listOfAssignment, Assignment([0], consecutiveSet, prob))

    while length(listOfAssignment) != 0

        assignment = pop!(listOfAssignment)
        verbose && println("On étudie l'assignment : $(assignment.assignment)")

        subExtremPoints = Vector{Solution}()
        subConsecutiveSet = Vector{PairOfSolution}()
        subUpperBound = DualSet()

        if withConvex
            computeLowerBound!(subExtremPoints, subConsecutiveSet, prob, assignment, M = M, verbose = verbose)
            subUpperBound = computeUpperBound(subConsecutiveSet)

            updateBound!(lowerBound, consecutiveSet, subExtremPoints)

            fathomed, nadirPointsToStudy = whichFathomed(subUpperBound, subExtremPoints, assignment.nadirPoints)
            verbose && println("L'état de ce sous-arbre est : $fathomed")

            if fathomed == none && assignment.indEndAssignment < prob.nbVar
                verbose && println("On rajoute l'assignement : $(append!(assignment.assignment[1:assignment.indEndAssignment], [1])) et $(append!(assignment.assignment[1:assignment.indEndAssignment], [0]))")
                push!(listOfAssignment, Assignment(
                                                append!(assignment.assignment[1:assignment.indEndAssignment], [1]),
                                                assignment.indEndAssignment+1,
                                                assignment.profit + broadcast(obj->obj.profits[assignment.indEndAssignment+1], prob.objs),
                                                assignment.weight + prob.constraint.weights[assignment.indEndAssignment+1],
                                                nadirPointsToStudy))
                push!(listOfAssignment, Assignment(
                                                append!(assignment.assignment[1:assignment.indEndAssignment], [0]),
                                                assignment.indEndAssignment+1,
                                                assignment.profit,
                                                assignment.weight,
                                                nadirPointsToStudy))
            end

        else




        end
    end

end

function algoJules!(lowerBound::Vector{Solution}, consecutiveSet::Vector{PairOfSolution}, prob::Problem) end

function main(fname::String = "test.dat"; withHeuristic::Bool = false, withConvex::Bool = true, verbose::Bool = false)

    verbose && println("On commence le B&B\n")

    @assert (!withHeuristic && withConvex) "Still under construction !"

    """
        Init Variables
    """

    prob = parser(fname)

    verbose && println("Notre problème est : $prob\n")

    lowerBoundSet = Vector{Solution}()
    consecutiveSet = Vector{PairOfSolution}()

    """
        Call from the different functions
    """

    # Calculate the Primal and Dual Set
    computeLowerBound!(lowerBoundSet, consecutiveSet, prob, Assignment(), verbose = verbose)

    withHeuristic ? algoJules!(lowerBoundSet, consecutiveSet, prob) : nothing

    branchAndBound!(lowerBoundSet, consecutiveSet, prob, withConvex, verbose = verbose)

    return lowerBoundSet

end
