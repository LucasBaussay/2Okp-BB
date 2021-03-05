
include("1okp.jl")


function weightedScalarRelax(prob::Problem, λ::Vector{Float64})
    @assert length(λ) == prob.nbObj "Le vecteur λ ne convient pas"

    obj       = Vector{Float64}(undef, prob.nbVar)
    sumLambda = sum(λ)

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

# return res the point associated with the solution x and the problem prob
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

# temporary test function
function testBandB(P::Problem)
    print(P)
    A = [-1,-1,-1]
    branchAndBound(P,A,1,[0])
    print("end")
end

function whichFathomed(upperBound::DualSet, lowerBound::Vector{Solution}, S::Vector{Solution}, consecutivePoint::Vector{Tuple{Solution, Solution}})

    test = true
    iter = 0

    if length(upperBound.b) == 0
        return infeasible
    elseif length(lowerBound) == 1
        return optimality
    else
        while test && iter < length(consecutivePoint)
            iter += 1
            solR, solL = consecutivePoint[iter]
            nadirPoint = [min(solR.y[ind], solL.y[ind]) for ind = 1:length(solR.y)]

            Ax = upperBound.A * nadirPoint

            for ind = 1:length(upperBound.b)
                test = test && Ax[ind] <= upperBound.b[ind] #Sur du <= ?
            end
        end
        if test
            return dominated
        else
            return none
        end
    end
end

# update upper et lower bound sets according to the new feasible subproblem
function updateBounds!(S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, lowerBoundSub::Vector{Solution})

    indSuppr = Vector{Int}(undef, length(consecutiveSet))
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
    end

    for iter = 1:indFinIndSuppr
        deleteat!(consecutiveSet, indSuppr[iter]-iter)
    end

end

# return a tuple of the two vectors : assignments for the two subproblems
function newAssignments(A::Vector{Int},i::Int)
    copyA = A[1:end]
    copyA[i] = 0
    A[i] = 1
    return copyA, A
end

function computeBoundDicho(prob::Problem, params...)

    @assert length(params)==1 "The parameters must exactly one : ϵ"

    ϵ = params[1]
    XSEm = Vector{Solution}()
    consecutiveSet = Vector{Tuple{Solution, Solution}}()
    S = Vector{Tuple{Solution, Solution}}()
    x1 = solve1OKP(weightedScalarRelax(prob, [1., ϵ]))
    x2 = solve1OKP(weightedScalarRelax(prob, [ϵ, 1.]))

    zx1 = evaluate(prob, x1)
    zx2 = evaluate(prob, x2)

    sol1 = Solution(x1, zx1)
    sol2 = Solution(x2, zx2)

    if zx1 == zx2
        push!(XSEm, sol1)
    else
        push!(S, (sol1, sol2))
        push!(XSEm, sol1, sol2)
        while length(S) != 0
            solR, solL = pop!(S)
            λ = [solL.y[2]-solR.y[2], solR.y[1]-solL.y[1]]
            xe = solve1OKP(weightedScalarRelax(prob, λ))

            zxe = evaluate(prob, xe)

            solE = Solution(xe, zxe)

            if sum(λ .* solE.y) > sum(λ .* solR.y)
                push!(XSEm, solE)
                push!(S, (solR, solE), (solE, solL))
            else
                push!(consecutiveSet, (solR, solL))
            end
        end
    end

    A = Array{Float64, 2}(undef, length(consecutiveSet), 2)
    B = Vector{Float64}(undef, length(consecutiveSet))

    for iter = 1:length(consecutiveSet)
        b, a = consecutiveSet[iter]
        b, a = b.y, a.y
        A[iter, 1] = b[2] - a[2]
        A[iter, 2] = a[1] - b[1]

        B[iter] = (b[2] - a[2]) * a[1] - (b[1] - a[1]) * a[2]
    end

    return XSEm, consecutiveSet, DualSet(A, B)

end

function branchAndBound(prob::Problem, assignment::Vector{Int}, S::Vector{Solution}, consecutiveSet::Vector{Tuple{Solution, Solution}}, i::Int = 0; ϵ::Float64 =0.01)

    #Arranger pour un sous problème
    lowerBoundSub, consecutivePointSub, upperBoundSub::DualSet = computeBoundDicho(subProblem(prob, assignment, i), ϵ)

    fathomed::Fathomed = whichFathomed(upperBoundSub, lowerBoundSub, S, consecutiveSet)

    if fathomed != dominated && fathomed != infeasible
        updateBounds!(S, consecutiveSet, lowerBoundSub)
    end
    if fathomed == none
        AO,A1 = newAssignments(assignment,i) # creating the two assignments for the subproblems : A0 is a copy, A1 == assignment
        branchAndBound(prob,A0,i+1,S) # exploring the first subproblem
        branchAndBound(prob,A1,i+1,S) # exploring the second subproblem
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

function main_BranchandBound(prob::Problem, orderName = "Random", ϵ::Float64 = 0.01)

    permVect = Random.shuffle(1:prob.nbVar)
    auxProb = reorderVariable(prob, permVect)

    S, consecutivePoint, weDontNeedItHere = computeBoundDicho(auxProb, ϵ)

    assignment = Vector{Int}(undef, prob.nbVar)
    for iter=1:prob.nbVar
        assignment[iter] = -1
    end

    branchAndBound(auxProb, assignment, S, consecutivePoint, 0, ϵ = ϵ)
end
