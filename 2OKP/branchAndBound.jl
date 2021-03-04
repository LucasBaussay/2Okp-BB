
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

function branchAndBound(P::Problem,A::Vector{Int},i::Int,S::Vector{Int})
    if isFathomedByOptimality()
        updateBounds()
        addSolution(S)
    elseif !isFathomedByDominance() && !isFathomedByInfeasibility()
        AO,A1 = newAssignments(A,i) # creating the two assignements for the subproblems
        branchAndBound(P,A0,i+1,S) # exploring the first subproblem
        branchAndBound(P,A1,i+1,S) # exploring the second subproblem
    end
end