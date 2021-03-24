
struct Obj
    profits::Vector{T} where T<:Real
end

struct Const
    maxWeight::Int
    weights::Vector{Int}
end

struct Problem
    nbObj::Int
    nbVar::Int
    objs::Vector{Obj}
    constraint::Const
end

struct Solution
    x::Vector{Float64}
    y::Vector{T} where T<:Real
    weight::W where W<:Real
    id::Int
end

struct PairOfSolution
    sol1::Solution
    sol2::Solution
    id::Int
end

struct DualSet
    A::Array{Union{Int, Float64}, 2}
    b::Vector{Union{Int, Float64}}
end

struct Assignment
    assignment::Vector{T} where T<:Real
    indEndAssignment::Int

    profit::Vector{Int}
    weight::Int

    nadirPoints::Vector{PairOfSolution}
end

import Base.show

function Base.show(io::IO, prob::Problem)
    if prob.nbVar != 0
        println(io, "Knapsack problem with $(prob.nbObj) objectives\n")
        for iterObj = 1:prob.nbObj
            print(io, "max z_$iterObj(x) = ")
            for iterVar = 1:prob.nbVar-1
                if prob.objs[iterObj].profits[iterVar] != 1
                    print(io, "$(prob.objs[iterObj].profits[iterVar])x_$iterVar + ")
                else
                    print(io, "x_$iterVar + ")
                end
            end
            if prob.objs[iterObj].profits[end] != 1
                println(io, "$(prob.objs[iterObj].profits[end])x_$(prob.nbVar)")
            else
                println(io, "x_$(prob.nbVar)")
            end
        end
        println(io, " ")
        print(io, "s.t.     ")
        for iterVar = 1:prob.nbVar-1
            if prob.constraint.weights[iterVar] != 1
                print(io, "$(prob.constraint.weights[iterVar])x_$iterVar + ")
            else
                print(io, "x_$iterVar + ")
            end
        end
        if prob.constraint.weights[end] != 1
            println(io, "$(prob.constraint.weights[end])x_$(prob.nbVar) ≤ $(prob.constraint.maxWeight)")
        else
            println(io, "x_$(prob.nbVar) ≤ $(prob.constraint.maxWeight)")
        end
    else
        print(io, "Empty Knapsack ! ")
    end
end


function parser(fname::String)
    f = open("Data/"*fname)
    nbObjs = parse(Int, readline(f))
    nbVar, maxWeight = parse.(Int, split(readline(f), " "))
    nbVar = Int(nbVar)

    objs = Vector{Vector{Int}}(undef, nbObjs)

    for iterObj = 1:nbObjs
        objs[iterObj] = parse.(Int, split(readline(f), " "))
    end

    return Problem(
        nbObjs,
        nbVar,
        Obj.(objs),
        Const(maxWeight, parse.(Int, split(readline(f), " ")))
    )
end

function initEmptyAssignment(nbVar)
    assignment = zeros(Real, nbVar)
    for iter = 1:nbVar
        assignment[iter] = -1
    end
    return assignment
end

function Solution()
    return Solution(
        Vector{Bool}(),
        Vector{Int}(),
        0
    )
end

function Solution(x::Vector{T}, y::Vector{S}, weight::Int) where T<:Real where S<:Real
    return Solution(
        x,
        y,
        weight,
        -1
    )
end

function PairOfSolution()
    return PairOfSolution(
        Solution(),
        Solution(),
        -1
    )
end

function PairOfSolution(sol1::Solution, sol2::Solution)
    return PairOfSolution(
        sol1,
        sol2,
        0
    )
end

function DualSet()
    return DualSet(
        Array{Union{Int, Float64}, 2}(undef, 0, 0),
        Vector{Union{Int, Float64}}()
    )
end

function Assignment()
    return Assignment(
        Vector{Real}(),
        0,
        Vector{Int}(),
        0,
        Vector{PairOfSolution}()
    )
end

function Assignment(subAssignment::Vector{Int}, nadirPoints::Vector{PairOfSolution}, prob::Problem)
    indEndAssignment = length(subAssignment)
    assignment = initEmptyAssignment(prob.nbVar)
    assignment[1:indEndAssignment] = subAssignment

    profits = zeros(Int, prob.nbObj)
    weight = 0

    for iter = 1:indEndAssignment
        profits += subAssignment[iter] * broadcast(obj -> obj.profits[iter], prob.objs)
        weight += subAssignment[iter] * prob.constraint.weights[iter]
    end

    return Assignment(
        assignment,
        indEndAssignment,

        profits,
        weight,

        nadirPoints
    )
end


import Base.>

function greaterSol(sol1::Solution, sol2::Solution)
    res = true
    for iter = 1:length(sol1.y)
        res = res && sol1.y[iter] > sol2.y[iter]
    end
    return res
end

function greaterNadir(sol::Solution, pair::PairOfSolution)
    res = true

    for iter = 1:length(sol.y)
        res = res && sol.y[iter] > min(pair.sol1.y[iter], pair.sol2.y[iter])
    end

    return res
end

>(sol1::Solution, sol2::Solution) = greaterSol(sol1, sol2)

>(sol::Solution, pair::PairOfSolution) = greaterNadir(sol, pair)
