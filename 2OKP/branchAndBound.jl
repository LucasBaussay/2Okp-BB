
function testBandB(P::Problem)
    print(P)
    A = [-1,-1,-1]
    branchAndBound(P,A,1,[])
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

function branchAndBound(P::Problem,A::Vector{Int},i::Int,S::Vector{Int})
    if isFathomedByOptimality()
        updateBounds()
        addSolution(S)
    elseif !isFathomedByDominance() && !isFathomedByInfeasibility()
        
    end
end