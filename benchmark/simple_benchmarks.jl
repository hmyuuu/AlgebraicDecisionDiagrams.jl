using BenchmarkTools
using AlgebraicDecisionDiagrams
using Printf

println("\n" * "="^80)
println("AlgebraicDecisionDiagrams.jl Performance Benchmarks")
println("="^80)
println()

# BDD Benchmarks
println("--- BDD Operations ---\n")

@printf("%-40s %12s %12s %12s\n", "Operation", "Time (ns)", "Allocs", "Memory")
println("-"^80)

# Variable creation
mgr = DDManager(20)
b = @benchmark ith_var($mgr, 10)
@printf("%-40s %12.0f %12d %12s\n", "Create variable",
        median(b.times), b.allocs, Base.format_bytes(b.memory))

# AND operation
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
b = @benchmark bdd_and($mgr, $x1, $x2)
@printf("%-40s %12.0f %12d %12s\n", "BDD AND",
        median(b.times), b.allocs, Base.format_bytes(b.memory))

# OR operation
b = @benchmark bdd_or($mgr, $x1, $x2)
@printf("%-40s %12.0f %12d %12s\n", "BDD OR",
        median(b.times), b.allocs, Base.format_bytes(b.memory))

# XOR operation
b = @benchmark bdd_xor($mgr, $x1, $x2)
@printf("%-40s %12.0f %12d %12s\n", "BDD XOR",
        median(b.times), b.allocs, Base.format_bytes(b.memory))

# NOT operation
b = @benchmark bdd_not($mgr, $x1)
@printf("%-40s %12.0f %12d %12s\n", "BDD NOT",
        median(b.times), b.allocs, Base.format_bytes(b.memory))

# ITE operation
x3 = ith_var(mgr, 3)
b = @benchmark bdd_ite($mgr, $x1, $x2, $x3)
@printf("%-40s %12.0f %12d %12s\n", "BDD ITE",
        median(b.times), b.allocs, Base.format_bytes(b.memory))

# Chain of ANDs (Warm/Cached)
println()
println("Warm/Cached (variables pre-created):")
for n in [5, 10, 20, 50]
    mgr_local = DDManager(n)
    vars = [ith_var(mgr_local, i) for i in 1:n]
    b = @benchmark begin
        result = $vars[1]
        for i in 2:$n
            result = bdd_and($mgr_local, result, $vars[i])
        end
        result
    end
    nodes = let
        result = vars[1]
        for i in 2:n
            result = bdd_and(mgr_local, result, vars[i])
        end
        count_nodes(mgr_local, result)
    end
    @printf("%-40s %12.2f %12s %12d\n", "BDD AND chain (n=$n)",
            median(b.times) / 1000, "-", nodes)
end

# Chain of ANDs (Cold - with initialization)
println()
println("Cold (with manager initialization):")
for n in [5, 10, 20, 50]
    b = @benchmark begin
        mgr_cold = DDManager($n)
        vars_cold = [ith_var(mgr_cold, i) for i in 1:$n]
        result = vars_cold[1]
        for i in 2:$n
            result = bdd_and(mgr_cold, result, vars_cold[i])
        end
        result
    end
    mgr_temp = DDManager(n)
    vars_temp = [ith_var(mgr_temp, i) for i in 1:n]
    result_temp = vars_temp[1]
    for i in 2:n
        result_temp = bdd_and(mgr_temp, result_temp, vars_temp[i])
    end
    nodes = count_nodes(mgr_temp, result_temp)
    @printf("%-40s %12.2f %12s %12d\n", "BDD AND chain (n=$n)",
            median(b.times) / 1000, "-", nodes)
end

# ADD Benchmarks
println("\n--- ADD Operations ---\n")

@printf("%-40s %12s %12s %12s\n", "Operation", "Time (μs)", "Memory", "Nodes")
println("-"^80)

mgr = DDManager(20)

# Constant creation
b = @benchmark add_const($mgr, 5.0)
@printf("%-40s %12.2f %12s %12s\n", "Create constant",
        median(b.times) / 1000, "-", "-")

# Variable creation
b = @benchmark add_ith_var($mgr, 10)
@printf("%-40s %12.2f %12s %12s\n", "Create ADD variable",
        median(b.times) / 1000, "-", "-")

# Arithmetic operations
a1 = add_ith_var(mgr, 1)
a2 = add_ith_var(mgr, 2)

b = @benchmark add_plus($mgr, $a1, $a2)
@printf("%-40s %12.2f %12s %12s\n", "ADD plus",
        median(b.times) / 1000, "-", "-")

b = @benchmark add_times($mgr, $a1, $a2)
@printf("%-40s %12.2f %12s %12s\n", "ADD times",
        median(b.times) / 1000, "-", "-")

b = @benchmark add_max($mgr, $a1, $a2)
@printf("%-40s %12.2f %12s %12s\n", "ADD max",
        median(b.times) / 1000, "-", "-")

# Chain of additions
println()
for n in [5, 10, 20, 50]
    mgr_local = DDManager(n)
    vars = [add_ith_var(mgr_local, i) for i in 1:n]
    b = @benchmark begin
        result = $vars[1]
        for i in 2:$n
            result = add_plus($mgr_local, result, $vars[i])
        end
        result
    end
    nodes = let
        result = vars[1]
        for i in 2:n
            result = add_plus(mgr_local, result, vars[i])
        end
        count_nodes(mgr_local, result)
    end
    @printf("%-40s %12.2f %12s %12d\n", "ADD plus chain (n=$n)",
            median(b.times) / 1000, "-", nodes)
end

# ZDD Benchmarks
println("\n--- ZDD Operations ---\n")

@printf("%-40s %12s %12s %12s\n", "Operation", "Time (μs)", "Memory", "Nodes")
println("-"^80)

mgr = DDManager(20)

# Singleton creation
b = @benchmark zdd_singleton($mgr, 10)
@printf("%-40s %12.2f %12s %12s\n", "Create singleton",
        median(b.times) / 1000, "-", "-")

# Set operations
z1 = zdd_singleton(mgr, 1)
z2 = zdd_singleton(mgr, 2)

b = @benchmark zdd_union($mgr, $z1, $z2)
@printf("%-40s %12.2f %12s %12s\n", "ZDD union",
        median(b.times) / 1000, "-", "-")

b = @benchmark zdd_intersection($mgr, $z1, $z2)
@printf("%-40s %12.2f %12s %12s\n", "ZDD intersection",
        median(b.times) / 1000, "-", "-")

b = @benchmark zdd_difference($mgr, $z1, $z2)
@printf("%-40s %12.2f %12s %12s\n", "ZDD difference",
        median(b.times) / 1000, "-", "-")

# From/to sets conversion
sets = [[1, 2], [2, 3], [1, 3], [4]]
b = @benchmark zdd_from_sets($mgr, $sets)
@printf("%-40s %12.2f %12s %12s\n", "ZDD from sets (4 sets)",
        median(b.times) / 1000, "-", "-")

family = zdd_from_sets(mgr, sets)
b = @benchmark zdd_to_sets($mgr, $family)
@printf("%-40s %12.2f %12s %12s\n", "ZDD to sets (4 sets)",
        median(b.times) / 1000, "-", "-")

# Chain of unions
println()
for n in [5, 10, 20, 50]
    mgr_local = DDManager(n)
    singletons = [zdd_singleton(mgr_local, i) for i in 1:n]
    b = @benchmark begin
        result = $singletons[1]
        for i in 2:$n
            result = zdd_union($mgr_local, result, $singletons[i])
        end
        result
    end
    nodes = let
        result = singletons[1]
        for i in 2:n
            result = zdd_union(mgr_local, result, singletons[i])
        end
        count_nodes(mgr_local, result)
    end
    @printf("%-40s %12.2f %12s %12d\n", "ZDD union chain (n=$n)",
            median(b.times) / 1000, "-", nodes)
end

# Utility Benchmarks
println("\n--- Utility Operations ---\n")

@printf("%-40s %12s %12s %12s\n", "Operation", "Time (μs)", "Memory", "Result")
println("-"^80)

mgr_util = DDManager(10)
vars_util = [ith_var(mgr_util, i) for i in 1:10]
f_util = vars_util[1]
for i in 2:10
    global f_util = bdd_and(mgr_util, f_util, vars_util[i])
end

b = @benchmark count_nodes($mgr_util, $f_util)
@printf("%-40s %12.2f %12s %12d\n", "Count nodes",
        median(b.times) / 1000, "-", count_nodes(mgr_util, f_util))

b = @benchmark count_paths($mgr_util, $f_util)
@printf("%-40s %12.2f %12s %12d\n", "Count paths",
        median(b.times) / 1000, "-", count_paths(mgr_util, f_util))

b = @benchmark count_minterms($mgr_util, $f_util, 10)
@printf("%-40s %12.2f %12s %12.0f\n", "Count minterms",
        median(b.times) / 1000, "-", count_minterms(mgr_util, f_util, 10))

println("\n" * "="^80)
println("Benchmark complete!")
println("="^80)
println()
