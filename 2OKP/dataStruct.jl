
struct Obj
    profits::Vector{Int}
end

struct Const
    maxWeight::Int
    weights::Vector{Float64}
end

struct Problem
    nbObj::Int
    nbVar::Int
    objs::Vector{Obj}
    constraint::Const
end

struct Solution
    x::Vector{Bool}
    y::Vector{Int}
    weight::Int
end

struct DualSet
    A::Array{Int, 2}
    b::Vector{Int}
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

function Solution()
    return Solution(
        Vector{Bool}(),
        Vector{Int}(),
        0
    )
end

function DualSet()
    return DualSet(
        Array{Int, 2}(),
        Vector{Int}()
    )
end
