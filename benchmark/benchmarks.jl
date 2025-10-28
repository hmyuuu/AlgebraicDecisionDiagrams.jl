using BenchmarkTools
using AlgebraicDecisionDiagrams
using Printf

include("cudd_wrapper.jl")

# Benchmark results structure
struct BenchmarkResult
    name::String
    julia_time::Float64
    cudd_time::Float64
    julia_memory::Int
    cudd_memory::Int
    julia_nodes::Int
    cudd_nodes::Int
end

function print_results(results::Vector{BenchmarkResult})
    println("\n" * "="^80)
    println("BENCHMARK RESULTS: AlgebraicDecisionDiagrams.jl vs CUDD")
    println("="^80)
    println()

    @printf("%-30s %12s %12s %10s %12s %12s\n",
            "Benchmark", "Julia (ms)", "CUDD (ms)", "Speedup", "Julia Nodes", "CUDD Nodes")
    println("-"^80)

    for r in results
        speedup = r.cudd_time / r.julia_time
        speedup_str = speedup >= 1.0 ? @sprintf("%.2fx", speedup) : @sprintf("%.2fx", speedup)

        @printf("%-30s %12.3f %12.3f %10s %12d %12d\n",
                r.name, r.julia_time, r.cudd_time, speedup_str, r.julia_nodes, r.cudd_nodes)
    end

    println("-"^80)

    # Summary statistics
    avg_julia = sum(r.julia_time for r in results) / length(results)
    avg_cudd = sum(r.cudd_time for r in results) / length(results)
    avg_speedup = avg_cudd / avg_julia

    println()
    @printf("Average Julia time:  %.3f ms\n", avg_julia)
    @printf("Average CUDD time:   %.3f ms\n", avg_cudd)
    @printf("Average speedup:     %.2fx %s\n", avg_speedup,
            avg_speedup >= 1.0 ? "(Julia faster)" : "(CUDD faster)")
    println()
end

# BDD Benchmarks
function benchmark_bdd_chain(n::Int)
    println("Running BDD chain benchmark (n=$n)...")

    # Julia implementation
    julia_time = @elapsed begin
        mgr = DDManager(n)
        vars = [ith_var(mgr, i) for i in 1:n]
        result = vars[1]
        for i in 2:n
            result = bdd_and(mgr, result, vars[i])
        end
        julia_nodes = count_nodes(mgr, result)
    end

    # CUDD implementation
    cudd_time = cudd_nodes = 0
    if check_cudd_available()
        cudd_time = @elapsed begin
            mgr_cudd = Cudd_Init(n, 0, 256, 262144, 0)
            vars = [Cudd_bddIthVar(mgr_cudd, i-1) for i in 1:n]
            result = vars[1]
            Cudd_Ref(result)
            for i in 2:n
                new_result = Cudd_bddAnd(mgr_cudd, result, vars[i])
                Cudd_Ref(new_result)
                Cudd_RecursiveDeref(mgr_cudd, result)
                result = new_result
            end
            cudd_nodes = Cudd_DagSize(result)
            Cudd_Quit(mgr_cudd)
        end
    end

    return BenchmarkResult("BDD AND chain (n=$n)", julia_time * 1000, cudd_time * 1000,
                          0, 0, julia_nodes, cudd_nodes)
end

function benchmark_bdd_tree(depth::Int)
    println("Running BDD tree benchmark (depth=$depth)...")

    n = 2^depth

    # Julia implementation
    julia_time = @elapsed begin
        mgr = DDManager(n)
        vars = [ith_var(mgr, i) for i in 1:n]

        # Build balanced tree
        current_level = vars
        while length(current_level) > 1
            next_level = []
            for i in 1:2:length(current_level)-1
                push!(next_level, bdd_and(mgr, current_level[i], current_level[i+1]))
            end
            if length(current_level) % 2 == 1
                push!(next_level, current_level[end])
            end
            current_level = next_level
        end
        result = current_level[1]
        julia_nodes = count_nodes(mgr, result)
    end

    # CUDD implementation
    cudd_time = cudd_nodes = 0
    if check_cudd_available()
        cudd_time = @elapsed begin
            mgr_cudd = Cudd_Init(n, 0, 256, 262144, 0)
            vars = [Cudd_bddIthVar(mgr_cudd, i-1) for i in 1:n]

            current_level = vars
            for v in current_level
                Cudd_Ref(v)
            end

            while length(current_level) > 1
                next_level = []
                for i in 1:2:length(current_level)-1
                    new_node = Cudd_bddAnd(mgr_cudd, current_level[i], current_level[i+1])
                    Cudd_Ref(new_node)
                    push!(next_level, new_node)
                end
                if length(current_level) % 2 == 1
                    push!(next_level, current_level[end])
                end
                current_level = next_level
            end
            result = current_level[1]
            cudd_nodes = Cudd_DagSize(result)
            Cudd_Quit(mgr_cudd)
        end
    end

    return BenchmarkResult("BDD AND tree (depth=$depth)", julia_time * 1000, cudd_time * 1000,
                          0, 0, julia_nodes, cudd_nodes)
end

function benchmark_bdd_xor_chain(n::Int)
    println("Running BDD XOR chain benchmark (n=$n)...")

    # Julia implementation
    julia_time = @elapsed begin
        mgr = DDManager(n)
        vars = [ith_var(mgr, i) for i in 1:n]
        result = vars[1]
        for i in 2:n
            result = bdd_xor(mgr, result, vars[i])
        end
        julia_nodes = count_nodes(mgr, result)
    end

    # CUDD implementation
    cudd_time = cudd_nodes = 0
    if check_cudd_available()
        cudd_time = @elapsed begin
            mgr_cudd = Cudd_Init(n, 0, 256, 262144, 0)
            vars = [Cudd_bddIthVar(mgr_cudd, i-1) for i in 1:n]
            result = vars[1]
            Cudd_Ref(result)
            for i in 2:n
                new_result = Cudd_bddXor(mgr_cudd, result, vars[i])
                Cudd_Ref(new_result)
                Cudd_RecursiveDeref(mgr_cudd, result)
                result = new_result
            end
            cudd_nodes = Cudd_DagSize(result)
            Cudd_Quit(mgr_cudd)
        end
    end

    return BenchmarkResult("BDD XOR chain (n=$n)", julia_time * 1000, cudd_time * 1000,
                          0, 0, julia_nodes, cudd_nodes)
end

# ADD Benchmarks
function benchmark_add_arithmetic(n::Int)
    println("Running ADD arithmetic benchmark (n=$n)...")

    # Julia implementation
    julia_time = @elapsed begin
        mgr = DDManager(n)
        vars = [add_ith_var(mgr, i) for i in 1:n]
        result = vars[1]
        for i in 2:n
            result = add_plus(mgr, result, vars[i])
        end
        julia_nodes = count_nodes(mgr, result)
    end

    # CUDD implementation
    cudd_time = cudd_nodes = 0
    if check_cudd_available()
        cudd_time = @elapsed begin
            mgr_cudd = Cudd_Init(n, 0, 256, 262144, 0)
            vars = [Cudd_addIthVar(mgr_cudd, i-1) for i in 1:n]
            result = vars[1]
            Cudd_Ref(result)
            for i in 2:n
                new_result = Cudd_addPlus(mgr_cudd, result, vars[i])
                Cudd_Ref(new_result)
                Cudd_RecursiveDeref(mgr_cudd, result)
                result = new_result
            end
            cudd_nodes = Cudd_DagSize(result)
            Cudd_Quit(mgr_cudd)
        end
    end

    return BenchmarkResult("ADD plus chain (n=$n)", julia_time * 1000, cudd_time * 1000,
                          0, 0, julia_nodes, cudd_nodes)
end

function benchmark_add_multiply(n::Int)
    println("Running ADD multiply benchmark (n=$n)...")

    # Julia implementation
    julia_time = @elapsed begin
        mgr = DDManager(n)
        vars = [add_ith_var(mgr, i) for i in 1:n]
        result = vars[1]
        for i in 2:n
            result = add_times(mgr, result, vars[i])
        end
        julia_nodes = count_nodes(mgr, result)
    end

    # CUDD implementation
    cudd_time = cudd_nodes = 0
    if check_cudd_available()
        cudd_time = @elapsed begin
            mgr_cudd = Cudd_Init(n, 0, 256, 262144, 0)
            vars = [Cudd_addIthVar(mgr_cudd, i-1) for i in 1:n]
            result = vars[1]
            Cudd_Ref(result)
            for i in 2:n
                new_result = Cudd_addTimes(mgr_cudd, result, vars[i])
                Cudd_Ref(new_result)
                Cudd_RecursiveDeref(mgr_cudd, result)
                result = new_result
            end
            cudd_nodes = Cudd_DagSize(result)
            Cudd_Quit(mgr_cudd)
        end
    end

    return BenchmarkResult("ADD times chain (n=$n)", julia_time * 1000, cudd_time * 1000,
                          0, 0, julia_nodes, cudd_nodes)
end

# ZDD Benchmarks
function benchmark_zdd_union(n::Int)
    println("Running ZDD union benchmark (n=$n)...")

    # Julia implementation
    julia_time = @elapsed begin
        mgr = DDManager(n)
        singletons = [zdd_singleton(mgr, i) for i in 1:n]
        result = singletons[1]
        for i in 2:n
            result = zdd_union(mgr, result, singletons[i])
        end
        julia_nodes = count_nodes(mgr, result)
    end

    # CUDD implementation
    cudd_time = cudd_nodes = 0
    if check_cudd_available()
        cudd_time = @elapsed begin
            mgr_cudd = Cudd_Init(0, n, 256, 262144, 0)
            singletons = [Cudd_zddIthVar(mgr_cudd, i-1) for i in 1:n]
            result = singletons[1]
            Cudd_Ref(result)
            for i in 2:n
                new_result = Cudd_zddUnion(mgr_cudd, result, singletons[i])
                Cudd_Ref(new_result)
                Cudd_RecursiveDeref(mgr_cudd, result)
                result = new_result
            end
            cudd_nodes = Cudd_DagSize(result)
            Cudd_Quit(mgr_cudd)
        end
    end

    return BenchmarkResult("ZDD union chain (n=$n)", julia_time * 1000, cudd_time * 1000,
                          0, 0, julia_nodes, cudd_nodes)
end

# Main benchmark suite
function run_benchmarks()
    println("\n" * "="^80)
    println("STARTING BENCHMARK SUITE")
    println("="^80)
    println()

    if !check_cudd_available()
        println("⚠ CUDD not available - running Julia-only benchmarks")
        println()
    end

    results = BenchmarkResult[]

    # BDD benchmarks
    println("\n--- BDD Benchmarks ---\n")
    push!(results, benchmark_bdd_chain(10))
    push!(results, benchmark_bdd_chain(20))
    push!(results, benchmark_bdd_tree(4))
    push!(results, benchmark_bdd_tree(5))
    push!(results, benchmark_bdd_xor_chain(10))
    push!(results, benchmark_bdd_xor_chain(15))

    # ADD benchmarks
    println("\n--- ADD Benchmarks ---\n")
    push!(results, benchmark_add_arithmetic(10))
    push!(results, benchmark_add_arithmetic(15))
    push!(results, benchmark_add_multiply(8))
    push!(results, benchmark_add_multiply(10))

    # ZDD benchmarks
    println("\n--- ZDD Benchmarks ---\n")
    push!(results, benchmark_zdd_union(10))
    push!(results, benchmark_zdd_union(20))

    # Print results
    print_results(results)

    return results
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmarks()
end
