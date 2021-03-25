
"""
    calculateUtility(weights::Vector{Float64}, objs::Vector{Obj})

    returns the utility "profit/weight" for both the objectives, for the variables
"""
function calculateUtility(weights::Vector{Float64}, objs::Vector{Obj})
    utility1 = zeros(length(weights))
    utility2 = zeros(length(weights))

    for iter = 1:length(weights)
        utility1[iter] = objs[1].profits[iter]/weights[iter]
        utility2[iter] = objs[2].profits[iter]/weights[iter]
    end

    return(utility1, utility2)
end

"""
    permOrder(prob::Problem, order::String = "random")

    returns the permutation vector to order variables according to the given order. A reverse permutation vector is returned too.
"""
function permOrder(prob::Problem, order::String = "random"; verbose = false)

    @assert prob.nbObj == 2 "This problem is 20KP"
    @assert order in ("averageUtility", "bestMin", "rankSum", "random") "Unknown criteria for order the variables"

    u1, u2 = calculateUtility(prob.constraint.weights, prob.objs)

    if order == "bestMin"

        worst = zeros(prob.nbVar)

        for iter in 1:prob.nbVar
            worst[iter] = min(u1[iter], u2[iter])
        end
        verbose && println(worst)

        perm = sortperm(worst, rev=true)
        verbose && println(perm)

    elseif order == "averageUtility"

        avg = zeros(prob.nbVar)
        for iter = 1:prob.nbVar
            avg[iter] = (u1[iter] + u2[iter])/2
        end

        perm = sortperm(avg, rev=true)

    elseif order == "rankSum"

        rank1 = sortperm(u1)
        rank2 = sortperm(u2)

        meanRank = zeros(prob.nbVar)

        for iter in 1:prob.nbVar
            meanRank[iter] = (rank1[iter] + rank2[iter])
        end

        perm = sortperm(meanRank)

    else #random
        perm = Random.shuffle(1:prob.nbVar)
    end

    revPerm = Vector{Int}(undef, prob.nbVar)
    for iter = 1:prob.nbVar
        revPerm[perm[iter]] = iter
    end

    return(perm, revPerm)
end
