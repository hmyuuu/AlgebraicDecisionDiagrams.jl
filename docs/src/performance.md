# Performance

This page provides detailed information about the performance characteristics of AlgebraicDecisionDiagrams.jl and how to optimize your code.

## Performance Overview

### Benchmark Results

AlgebraicDecisionDiagrams.jl achieves excellent performance compared to CUDD:

| Metric | Julia | CUDD | Advantage |
|--------|-------|------|-----------|
| **BDD AND (warm)** | 5 ns | 27 ns | Julia 5.5x faster |
| **BDD OR (warm)** | 5 ns | 26 ns | Julia 5.2x faster |
| **BDD XOR (warm)** | 5 ns | 15 ns | Julia 3.0x faster |
| **BDD ITE (warm)** | 6 ns | 16 ns | Julia 2.7x faster |
| **Memory allocations** | 0 | N/A | Julia |
| **Cold start** | ~900 μs | ~900 μs | Comparable |

### Warm vs Cold Performance

**Warm Performance** (cached operations):
- Measures steady-state performance after initialization
- Relevant for long-running applications, REPL usage, servers
- Julia: 3-1100x faster than CUDD

**Cold Performance** (with initialization):
- Includes manager creation and setup overhead
- Relevant for short-lived scripts
- Julia and CUDD: Comparable (~1x)

## Zero Allocations

All hot-path operations achieve zero allocations:

```julia
using BenchmarkTools

mgr = DDManager(10)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)

# Check allocations
@benchmark bdd_and($mgr, $x1, $x2)
# Memory estimate: 0 bytes
# Allocs estimate: 0
```

This is achieved through:
- Careful use of `@inline` directives
- Stack-allocated temporaries
- Efficient caching strategies
- Type-stable code

## Performance Characteristics

### Operation Complexity

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| **Variable creation** | O(1) | O(1) |
| **NOT** | O(1) | O(1) |
| **AND/OR/XOR** | O(\|f\| × \|g\|) worst case | O(\|f\| × \|g\|) worst case |
| **ITE** | O(\|f\| × \|g\| × \|h\|) worst case | O(\|f\| × \|g\| × \|h\|) worst case |
| **Exists/Forall** | O(\|f\|²) worst case | O(\|f\|²) worst case |
| **Restrict** | O(\|f\|) | O(\|f\|) |

Note: With caching, repeated operations are O(1).

### Caching Impact

Operations are automatically cached:

```julia
mgr = DDManager(10)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)

# First call: computes and caches
@time result1 = bdd_and(mgr, x1, x2)  # ~5 ns

# Second call: cache hit
@time result2 = bdd_and(mgr, x1, x2)  # ~5 ns (from cache)

@assert result1 == result2
```

Cache hit rate typically exceeds 90% for realistic workloads.

## Optimization Techniques

### 1. Variable Ordering

Variable ordering dramatically affects BDD size:

```julia
mgr = DDManager(6)

# Good ordering: related variables together
# f = (x1 ∧ x2) ∨ (x3 ∧ x4) ∨ (x5 ∧ x6)
# Order: x1, x2, x3, x4, x5, x6
vars = [ith_var(mgr, i) for i in 1:6]
f_good = bdd_or(mgr,
    bdd_or(mgr,
        bdd_and(mgr, vars[1], vars[2]),
        bdd_and(mgr, vars[3], vars[4])),
    bdd_and(mgr, vars[5], vars[6]))

nodes_good = count_nodes(mgr, f_good)
println("Good ordering: ", nodes_good, " nodes")

# Bad ordering: interleaved variables
# Order: x1, x3, x5, x2, x4, x6
# Would result in larger BDD
```

**Tips:**
- Group related variables together
- Put frequently-used variables near the top
- Consider problem structure when assigning indices
- Dynamic reordering not yet implemented

### 2. Reuse Managers

Manager creation has overhead (~900μs):

```julia
using BenchmarkTools

# Good: Reuse manager
mgr = DDManager(10)
@benchmark begin
    x = ith_var($mgr, 1)
    y = ith_var($mgr, 2)
    bdd_and($mgr, x, y)
end
# Fast: ~15 ns

# Bad: Create manager each time
@benchmark begin
    mgr = DDManager(10)
    x = ith_var(mgr, 1)
    y = ith_var(mgr, 2)
    bdd_and(mgr, x, y)
end
# Slow: ~900 μs
```

### 3. Build Bottom-Up

Build complex formulas incrementally:

```julia
mgr = DDManager(10)
vars = [ith_var(mgr, i) for i in 1:10]

# Good: Incremental construction
result = vars[1]
for i in 2:10
    result = bdd_and(mgr, result, vars[i])
end

# Also good: Use reduce
result = reduce((acc, v) -> bdd_and(mgr, acc, v), vars)

# Bad: Deeply nested calls (harder to optimize)
result = bdd_and(mgr, vars[1],
    bdd_and(mgr, vars[2],
        bdd_and(mgr, vars[3],
            # ... many levels deep
        )))
```

### 4. Choose Appropriate DD Type

Use the right tool for the job:

```julia
# BDDs: Boolean functions
mgr = DDManager(10)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
f = bdd_and(mgr, x1, x2)  # Fast, compact

# ADDs: Numeric functions
a1 = add_ith_var(mgr, 1)
a2 = add_ith_var(mgr, 2)
g = add_plus(mgr, a1, a2)  # Appropriate for arithmetic

# ZDDs: Sparse sets
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
h = zdd_union(mgr, s1, s2)  # Efficient for set operations
```

### 5. Avoid Unnecessary Conversions

Conversions have overhead:

```julia
mgr = DDManager(3)

# Good: Work in one domain
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
result = bdd_and(mgr, x1, x2)

# Bad: Unnecessary conversions
x1_bdd = ith_var(mgr, 1)
x1_add = bdd_to_add(mgr, x1_bdd)  # Conversion overhead
x1_back = add_to_bdd(mgr, x1_add)  # More overhead
```

## Profiling

### Using BenchmarkTools

```julia
using BenchmarkTools
using AlgebraicDecisionDiagrams

mgr = DDManager(10)
vars = [ith_var(mgr, i) for i in 1:10]

# Benchmark a complex operation
@benchmark begin
    result = $vars[1]
    for i in 2:10
        result = bdd_and($mgr, result, $vars[i])
    end
end
```

### Using Profile

```julia
using Profile
using AlgebraicDecisionDiagrams

mgr = DDManager(100)

# Profile a workload
@profile begin
    for i in 1:1000
        x = ith_var(mgr, i % 100 + 1)
        y = ith_var(mgr, (i+1) % 100 + 1)
        result = bdd_and(mgr, x, y)
    end
end

# View results
Profile.print()
```

## Memory Usage

### Node Memory

Each node uses minimal memory:

```julia
mgr = DDManager(10)

# Create nodes
for i in 1:10
    x = ith_var(mgr, i)
end

# Check memory
node_size = sizeof(mgr.nodes[1])
total_nodes = length(mgr.nodes)
node_memory = node_size * total_nodes

println("Node size: ", node_size, " bytes")
println("Total nodes: ", total_nodes)
println("Node memory: ", node_memory, " bytes")
```

### Cache Memory

The computed table uses direct-mapped caching:

```julia
mgr = DDManager(10)

cache_size = length(mgr.cache.entries)
entry_size = sizeof(mgr.cache.entries[1])
cache_memory = cache_size * entry_size

println("Cache size: ", cache_size, " entries")
println("Cache memory: ", cache_memory, " bytes")
```

## Scalability

### Problem Size

Performance scales well with problem size:

```julia
using BenchmarkTools

for n in [10, 20, 50, 100]
    mgr = DDManager(n)
    vars = [ith_var(mgr, i) for i in 1:n]

    b = @benchmark begin
        result = $vars[1]
        for i in 2:$n
            result = bdd_and($mgr, result, $vars[i])
        end
    end

    println("n=$n: ", median(b.times) / 1000, " μs")
end
```

Expected output:
```
n=10: 0.05 μs
n=20: 0.14 μs
n=50: 0.40 μs
n=100: 0.90 μs
```

Linear scaling for chain operations.

### Node Count Growth

BDD size depends on function complexity and variable ordering:

```julia
mgr = DDManager(10)
vars = [ith_var(mgr, i) for i in 1:10]

# Linear growth: AND chain
result = vars[1]
for i in 2:10
    result = bdd_and(mgr, result, vars[i])
end
println("AND chain nodes: ", count_nodes(mgr, result))  # 10

# Exponential growth: bad ordering
# (Some functions can have exponential blowup)
```

## Comparison with CUDD

### Detailed Benchmarks

See `benchmark/cudd_comparison/RESULTS.md` for comprehensive benchmarks.

**Key findings:**
- Warm operations: Julia 3-1100x faster
- Cold operations: Comparable
- Zero allocations: Julia advantage
- Variable reordering: CUDD advantage (not yet in Julia)
- Multi-threading: CUDD advantage (not yet in Julia)

### When to Use Each

**Use Julia when:**
- Interactive development (REPL, notebooks)
- Long-running applications
- Performance is critical
- Type safety matters
- Integration with Julia ecosystem

**Use CUDD when:**
- Variable reordering is essential
- Multi-threading required
- Very large problems (>10M nodes) with reordering
- Integration with C/C++ code

## Future Optimizations

### Planned Improvements

1. **Variable Reordering** (High Priority)
   - SIFT algorithm
   - Dynamic reordering
   - Expected: 10-100x improvement for large problems

2. **Multi-threading** (Medium Priority)
   - Parallel operations
   - Thread-safe caching
   - Expected: 2-8x improvement on multi-core

3. **SIMD Operations** (Low Priority)
   - Vectorized operations where applicable
   - Expected: 1.5-2x improvement for specific operations

## Best Practices Summary

1. ✅ Reuse managers across operations
2. ✅ Choose good variable ordering
3. ✅ Build formulas bottom-up
4. ✅ Use appropriate DD type (BDD/ADD/ZDD)
5. ✅ Avoid unnecessary conversions
6. ✅ Profile before optimizing
7. ✅ Leverage caching (automatic)
8. ✅ Monitor memory usage for large problems

## See Also

- [Comparison with CUDD](@ref): Detailed benchmark comparison
- [API Reference](@ref): Complete API documentation
- [Internals](@ref): Implementation details
