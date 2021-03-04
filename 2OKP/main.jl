include("dataStruct.jl")
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

function evaluate(prob::Problem, x::Vector{Int})
    res = zeros(Float64, prob.nbObj)
    for iterObj = 1:prob.nbObj
        for iter in x
            res[iterObj] += prob.objs[iterObj].profits[iter]
        end
    end

    return res

end

function firstPhase(prob::Problem, params...)

    @assert length(params)==1 "The parameters must exactly one : ϵ"

    ϵ = params[1]
    XSEm = []
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
            end
        end
    end
    return XSEm

end

function secondPhase(prob::Problem, params...)

    @assert length(params) == 1 "There must be 1 parameters to secondPhase : Name of the order"



end

function main(fname::String = "test.dat", methodName::String = "TwoPhases", params...)

    prob = parser(fname)

    if methodName == "TwoPhases"
        @assert length(params) == 0 #A modifier suivant la structure des paramètres

        return firstPhase(prob, 0.1)

    end



end
