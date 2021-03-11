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

function branchAndBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{Tuple{Int, Int}}, prob::Problem, withConvex::Bool) end

function algoJules!(lowerBound::Vector{Solution}, consecutiveSet::Vector{Tuple{Int, Int}}, prob::Problem) end

function computeLowerBound!(lowerBound::Vector{Solution}, consecutiveSet::Vector{Tuple{Int, Int}}, prob::Problem)

end

function main(fname::String = "test.dat"; withHeuristic::Bool = false, withConvex::Bool = false, verbose::Bool = false)

    @assert (!withHeuristic && !withConvex) "Still under construction !"

    """
        Init Variables
    """

    prob = parser(fname)

    lowerBoundSet = Vector{Solution}()
    consecutiveSet = Vector{Tuple{Int, Int}}()

    """
        Call from the different functions
    """

    # Calculate the Primal and Dual Set
    computeLowerBound!(lowerBoundSet, consecutiveSet, prob)

    withHeuristic ? algoJules!(lowerBoundSet, consecutiveSet, prob) : nothing

    branchAndBound!(lowerBoundSet, consecutiveSet, prob, withConvex)

    return lowerBoundSet

end
