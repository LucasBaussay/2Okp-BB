
include("1okp.jl")

function weightedScalarRelax(prob::Problem, λ::Vector{Float64})
    @assert length(λ) == prob.nbObj "Le vecteur λ ne convient pas"

    obj = Vector{Float64}(undef, prob.nbVar)
    sumLambda= sum(λ)
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

function evaluate(prob::Problem, x::Vector{Bool})
    res = zeros(Float64, prob.nbObj)
    for iterObj = 1:prob.nbObj
        for iter in 1:prob.nbVar
            if x[iter]
                res[iterObj] += prob.objs[iterObj].profits[iter]
            end
        end
    end

    return res

end

function testBandB(P::Problem)
    print(P)
    A = [-1,-1,-1]
    branchAndBound(P,A,1,[0])
    print("end")
end

# test wether the subproblem is optimal or not
function isFathomedByOptimality()
    return true
end

# test wether the subproblem is dominated by another subproblem
function isFathomedByDominance()
    return true
end

# test wether the subproblem is infeasible
function isFathomedByInfeasibility()
    return true
end

# update upper et lower bound sets according to the new feasible subproblem
function updateBounds()
end

# add the newly found solution to the vector of solutions
function addSolution(S::Vector{Int})
end

# return a tuple of the two vectors : assignements for the two subproblems
function newAssignments(A::Vector{Int},i::Int)
    return [0],[0]
end

function computBoundDicho(prob::Problem, params...)

    @assert length(params)==1 "The parameters must exactly one : ϵ"

    ϵ = params[1]
    XSEm = []
    consecutiveSet = Vector{Tuple{Int, Int}}()
    S = []
    x1 = solve1OKP(weightedScalarRelax(prob, [1., ϵ]))
    x2 = solve1OKP(weightedScalarRelax(prob, [ϵ, 1.]))

    zx1 = evaluate(prob, x1)
    zx2 = evaluate(prob, x2)

    if zx1 == zx2
        push!(XSEm, x1)
    else
        push!(S, (zx1, zx2))
        push!(XSEm, x1, x2)
        while length(S) != 0
            yr, yl = pop!(S)
            λ = [yl[2]-yr[2], yr[1]-yl[1]]
            xe = solve1OKP(weightedScalarRelax(prob, λ))

            zxe = evaluate(prob, xe)

            if sum(λ .* zxe) > sum(λ .* yr)
                push!(XSEm, xe)
                push!(S, (yr, zxe), (zxe, yl))
            else
                push!(consecutiveSet, (yr, yl))
            end
        end
    end



end

function branchAndBound(prob::Problem, assignement::Vector{Int},S::Vector{Vector{Bool}}, i::Int = 1; ϵ::Float64 =0.01)

    upperBound, lowerBound = computeBoundDicho(prob, ϵ)

    if isFathomedByOptimality()
        updateBounds()
        addSolution(S)
    elseif !isFathomedByDominance() && !isFathomedByInfeasibility()
        AO,A1 = newAssignments(A,i) # creating the two assignements for the subproblems
        branchAndBound(P,A0,i+1,S) # exploring the first subproblem
        branchAndBound(P,A1,i+1,S) # exploring the second subproblem
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

function main_BranchandBound(prob::Problem, S::Vector{Vector{Bool}}, orderName = "Random", ϵ::Float64 = 0.01)

    permVect = Random.shuffle(1:prob.nbVar)
    auxProb = reorderVariable(prob, permVect)

    # S is ma primal Set
    auxS = [S[iter][permVect] for iter = 1:length(S)]

    assignement = Vector{Int}(undef, prob.nbVar)
    for iter=1:prob.nbVar
        assignement[iter] = -1
    end

    branchAndBound(auxProb, assignment, auxS, ϵ = ϵ)
end
