using Test
using AlgebraicDecisionDiagrams

@testset "AlgebraicDecisionDiagrams.jl" begin
    include("test_bdd.jl")
    include("test_add.jl")
    include("test_zdd.jl")
    include("test_utils.jl")
end
