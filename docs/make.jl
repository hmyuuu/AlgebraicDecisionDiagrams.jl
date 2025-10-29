using Documenter

# Load the package from parent directory
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using AlgebraicDecisionDiagrams

makedocs(
    modules=[AlgebraicDecisionDiagrams],
    authors="Huai-Ming Yu <hmyuuus@gmail.com>",
    sitename="AlgebraicDecisionDiagrams.jl",
    format=Documenter.HTML(
        canonical="https://hmyuuu.github.io/AlgebraicDecisionDiagrams.jl",
        prettyurls=get(ENV, "CI", nothing) == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "User Guide" => [
            "Binary Decision Diagrams (BDDs)" => "guide/bdds.md",
            "Algebraic Decision Diagrams (ADDs)" => "guide/adds.md",
            "Zero-suppressed Decision Diagrams (ZDDs)" => "guide/zdds.md",
            "Utilities" => "guide/utilities.md",
        ],
        "Performance" => "performance.md",
        "Comparison with CUDD" => "comparison.md",
        "API Reference" => "api.md",
        "Internals" => "internals.md",
    ],
    checkdocs=:exports,
)

deploydocs(
    repo="github.com/hmyuuu/AlgebraicDecisionDiagrams.jl",
    devbranch="main",
)
