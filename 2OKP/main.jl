import Random

@enum Fathomed none dominance infeasibility optimality

try
    include("../1OKP/structKP.jl")
catch end
include("../1OKP/projetFinal.jl")

include("dataStruct.jl")
include("pretrait.jl")
include("branchAndBound.jl")



"""

    New part : Trying to be iterative and mutable to other method !

"""

function solve1Okp(prob::Problem)

    @assert prob.nbObj == 1 "This problem is no 1OKP"

    ListObj = [Objet(prob.objs[1].profits[iter], prob.constraint.weights[iter], iter) for iter = 1:prob.nbVar]

    sol = main1Okp(ListObj, prob.constraint.maxWeight)

    return Solution(Bool.(sol.X), sol.y, sum(sol.X .* prob.constraint.weights))

end

function weightedScalarRelax(prob::Problem, λ::Vector{Float64})
    @assert length(λ) == prob.nbObj "Le vecteur λ ne convient pas"

    obj = Vector{Float64}(undef, prob.nbVar) # new merged objective
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
    y = zeros(Float64, prob.nbObj)
    weight = 0
    # GOAL : computing the image of x by prob
    for iterObj = 1:prob.nbObj
        for iter = 1:prob.nbVar
            if x[iter]
                y[iterObj] += prob.objs[iterObj].profits[iter]
                weight += prob.constraint.weights[iter]
            end
        end
    end
    # the resulting point
    return Solution(x, y, weight/2, 1)
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
        Obj.(prob.objs[(assignment.indEndAssignment+1):end]),
        Const(prob.maxWeight - assignment.weight, prob.constraint.weights[(assignment.indEndAssignment+1):end])
    )

end

function createSuperSol(sol::Solution, assignment::Assignment, id::Int)

    return Solution(
        append!(assignment.assignment[1:assignment.indEndAssignment], sol.x),
        sol.y + assignment.profits,
        sol.weight + assignment.weight,
        id
    )

end

function createSuperSol(sol::Solution, assignment::Assignment)
    return createSuperSol(sol, assignment, sol.id)
end

function linearRelax(prob::Problem, assign::Assignment, indEndAssignment::Int = 0, obj::Int=1, verbose = true)

    # INITIALIZATION OF THE PROBLEM
    assignment = assign.assignment
    # sorts the variable from the best utility to the worst
    permList = sortperm(prob.objs[obj].profits ./ prob.constraint.weights, rev = true)
    verbose && println("liste de permut : ", permList)
    # stocks the perm order to reverse the problem at the end
    revPermList = sortperm(permList)
    verbose && println("rev perm list : ", revPermList)

    # if the assignement is empty, fills it with -1, meaning the variable is not assigned yet
    if assignment == []
        assignment  = ones(prob.nbVar, 1) * -1.
    else
        assignment = assignment * 1.
    end

    # Weight left given the variables' assignement
    primLeftWeight = prob.constraint.maxWeight - assign.weight
    verbose && println("poids restant init : ", primLeftWeight)

    heurSol = zeros(Float64, prob.nbVar)
    iterLastOne = 0

    for iter = 1:prob.nbVar
        iterOrdered = permList[iter]
        println("index : ", assignment, " et ", assignment[iterOrdered])
        if assignment[iterOrdered] != -1
            heurSol[iter] = assignment[iterOrdered]
            if assignment[iterOrdered] == 1
                iterLastOne = iterOrdered
            end
        end
    end

    verbose && println("iter last one : ", iterLastOne)

    it = indEndAssignment + 1

    # UPPER BOUND COMPUTATION

    # adds all possible objects given the limit weight
    while primLeftWeight >= prob.constraint.weights[permList[it]]
        heurSol[it] = 1
        primLeftWeight -= prob.constraint.weights[permList[it]]
        it += 1
        verbose && println("current sol : ", heurSol , " and weight : ", primLeftWeight)
    end

    # add fragments of the next best object according to the utility
    # iter corresponds to the limiting object
    if primLeftWeight != 0
        heurSol[it] = primLeftWeight / prob.constraint.weights[it]
        primLeftWeight -= prob.constraint.weights[permList[it]] * primLeftWeight / prob.constraint.weights[it]
        verbose && println("final assign : ", assignment, " and remaining weight : ", primLeftWeight)
        # ub = lb + primLeftWeight / prob.constraint.weight[it]*prob.objs[1].profits[permList[it]]
    end

    sol = evaluateLinear(prob, heurSol[revPermList])
    return (heurSol[revPermList], sol)
end

function updateBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{PairOfSolution}, subExtremPoints::Vector{Solution})

end

function computeLowerBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, mainProb::Problem, assignment::Assignment; M::Int = 1000, verbose = false)

    prob = subProb(prob, assignment)

    S = Vector{Tuple{Solution, Solution}}()

    # computing the two first points, sol1 is the best for the only the objective number 1, and sol2 for the objective number 2.
    sol1 = solve1Okp(weightedScalarRelax(prob, [M, 1]))
    sol2 = solve1Okp(weightedScalarRelax(prob, [1, M]))

    # evaluating the two sols and constructing the associated solutions
    sol1 = evaluate(prob, sol1.x)
    sol2 = evaluate(prob, sol2.x)

    verbose && println("On crée les solution lexico : $(sol1.y) et $(sol2.y)")

    if sol1.y == sol2.y # solutions are identicals
        push!(lowerBound, createSuperSol(sol1, assignment, length(lowerBound)+1))
    else # solutions are different
        push!(S, (sol1, sol2)) # we'll need to study (sol1,sol2)
        push!(lowerBound, createSuperSol(sol1, assignment, length(lowerBound)+1), createSuperSol(sol2, assignment, length(lowerBound)+2)) # sol1 and sol2 are supported efficient and extreme solutions

        # goal : compute the dichotomy
        while length(S) != 0 # while we have solutions to study
            solR, solL = pop!(S) # get the two consecutive points from the queue of tuples to study

            verbose && println("On étudie la paire de solution : $(solR.y) et $(solL.y)")
            # computing the direction of the search
            λ = [solL.y[2]-solR.y[2], solR.y[1]-solL.y[1]]
            # computing the resulting solution
            solE = solve1Okp(weightedScalarRelax(prob, λ))
            solE = evaluate(prob, solE.x)

            if sum(λ .* solE.y) > sum(λ .* solR.y) # solE is better than solR according to λ
                push!(lowerBound, createSuperSol(solE, assignment, length(lowerBound)+1)) # solE is solution we want
                push!(S, (solR, solE), (solE, solL)) # now we need to study (solR, solE) and (solE, solL)
                verbose && println("On a trouvé la solution : $(solE.y)")
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

    """
        Initalisation of the variables
    """
    listOfAssignment = Vector{Assignment}()
    push!(listOfAssignment, Assignment([1], consecutiveSet, prob))
    push!(listOfAssignment, Assignment([0], consecutiveSet, prob))

    while length(listOfAssignment) != 0

        assignment = pop!(listOfAssignment)

        subExtremPoints = Vector{Solution}()
        subConsecutiveSet = Vector{PairOfSolution}()
        subUpperBound = DualSet()

        if withConvex
            computeLowerBound!(subExtremPoints, subConsecutiveSet, prob, assignment, M = M, verbose = verbose)
            subUpperBound = computeUpperBound(subConsecutiveSet)

            updateBound!(lowerBound, consecutiveSet, subExtremPoints)

            fathomed, nadirPointsToStudy = wichFathomed(subUpperBound, subExtremPoints, assignment.nadirPoints)

            if fathomed == none && assignment.indEndAssignment < prob.nbVar
                push!(listOfAssignment, Assignment(
                                                append!(assignment.assignment[1:assignment.indEndAssignment], [1]),
                                                assignment.indEndAssignment+1,
                                                assignment.profits + broadcast(obj->obj.profits[assignment.indEndAssignment+1], prob.objs),
                                                assignment.weight + prob.constraint.weights[assignment.indEndAssignment+1],
                                                nadirPointsToStudy))
                push!(listOfAssignment, Assignment(
                                                append!(assignment.assignment[1:assignment.indEndAssignment], [0]),
                                                assignment.indEndAssignment+1,
                                                assignment.profits,
                                                assignment.weight,
                                                nadirPointsToStudy))
            end
        else

        end
    end
end

function algoJules!(lowerBound::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, prob::Problem) end

function main(fname::String = "test.dat"; withHeuristic::Bool = false, withConvex::Bool = false, verbose::Bool = false)

    @assert (!withHeuristic && !withConvex) "Still under construction !"

    """
        Init Variables
    """

    prob = parser(fname)

    lowerBoundSet = Vector{Solution}()
    consecutiveSet = Vector{PairOfSolution}()

    """
        Call from the different functions
    """

    # Calculate the Primal and Dual Set
    computeLowerBound!(lowerBoundSet, consecutiveSet, prob)

    withHeuristic ? algoJules!(lowerBoundSet, consecutiveSet, prob) : nothing

    branchAndBound!(lowerBoundSet, consecutiveSet, prob, withConvex)

    return lowerBoundSet

end
