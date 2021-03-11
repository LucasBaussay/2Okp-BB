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
    # GOAL : computing the image of x by prob
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
    Concordance des structures de données ?!
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

function computeLowerBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, prob::Problem; M::Int = 1000, verbose = false)
    S = Vector{Tuple{Solution, Solution}}()

    # computing the two first points, sol1 is the best for the only the objective number 1, and sol2 for the objective number 2.
    sol1 = solve1Okp(weightedScalarRelax(prob, [M, 1]))
    sol2 = solve1Okp(weightedScalarRelax(prob, [1, M]))

    # evaluating the two sols and constructing the associated solutions
    sol1 = evaluate(prob, sol1.x)
    sol2 = evaluate(prob, sol2.x)

    verbose && println("On crée les solution lexico : $(sol1.y) et $(sol2.y)")

    if sol1.y == sol2.y # solutions are identicals
        push!(XSEm, sol1)
    else # solutions are different
        push!(S, (sol1, sol2)) # we'll need to study (sol1,sol2)
        push!(lowerBound, sol1, sol2) # sol1 and sol2 are supported efficient and extreme solutions

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
                push!(XSEm, solE) # solE is solution we want
                push!(S, (solR, solE), (solE, solL)) # now we need to study (solR, solE) and (solE, solL)
                verbose && println("On a trouvé la solution : $(solE.y)")
            else # solE is equal to solR according to λ, so we didn't find new solutions
                push!(consecutiveSet, (solR, solL)) # we know we won't find solutions between solR, solL, so we memorize the tuple
                verbose && println("On a rien trouvé dans cette direction")
            end
        end
    end
end

function computeUpperBound(consecutiveSet::vector{PairOfSolution})

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

function branchAndBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, prob::Problem, withConvex::Bool; M = 1000, verbose = false)

    """
        Initalisation of the variables
    """
    listOfAssignment = Vector{Assignment}()
    push!(listOfAssignment, Assignment([1], consecutiveSet, prob.nbVar))
    push!(listOfAssignment, Assignment([0], consecutiveSet, prob.nbVar))

    while length(listOfAssignment) != 0
        subExtremPoints = Vector{Solution}()
        subConsecutiveSet = Vector{PairOfSolution}()
        subUpperBound = DualSet()

        if withConvex
            computeLowerBound!(subExtremPoints, subConsecutiveSet, prob, M = M, verbose = verbose)
            subUpperBound = computeUpperBound(subConsecutiveSet)


        else

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
    consecutiveSet = Vector{Tuple{Solution, Solution}}()

    """
        Call from the different functions
    """

    # Calculate the Primal and Dual Set
    computeLowerBound!(lowerBoundSet, consecutiveSet, prob)

    withHeuristic ? algoJules!(lowerBoundSet, consecutiveSet, prob) : nothing

    branchAndBound!(lowerBoundSet, consecutiveSet, prob, withConvex)

    return lowerBoundSet

end
