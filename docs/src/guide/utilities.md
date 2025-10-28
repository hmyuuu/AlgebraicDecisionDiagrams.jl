# Utilities

This guide covers utility functions for analyzing, debugging, and managing decision diagrams.

## Counting Functions

### Count Nodes

Count the number of nodes in a decision diagram:

```julia
using AlgebraicDecisionDiagrams

mgr = DDManager(5)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# Simple variable: 1 node
count = count_nodes(mgr, x1)
println("Nodes in x1: ", count)  # 1

# AND of two variables: 2 nodes
f = bdd_and(mgr, x1, x2)
count = count_nodes(mgr, f)
println("Nodes in x1 ∧ x2: ", count)  # 2

# More complex formula
g = bdd_or(mgr, bdd_and(mgr, x1, x2), x3)
count = count_nodes(mgr, g)
println("Nodes in (x1 ∧ x2) ∨ x3: ", count)  # 3
```

### Count Paths

Count the number of paths from root to true terminal:

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# x1 ∧ x2: one path (both must be true)
f = bdd_and(mgr, x1, x2)
paths = count_paths(mgr, f)
println("Paths in x1 ∧ x2: ", paths)  # 1

# x1 ∨ x2: three paths (x1 true, x2 true, or both)
g = bdd_or(mgr, x1, x2)
paths = count_paths(mgr, g)
println("Paths in x1 ∨ x2: ", paths)  # 3

# x1 ⊕ x2: two paths (exactly one true)
h = bdd_xor(mgr, x1, x2)
paths = count_paths(mgr, h)
println("Paths in x1 ⊕ x2: ", paths)  # 2
```

### Count Minterms

Count the number of satisfying assignments (minterms):

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# x1 ∧ x2: 2 minterms out of 8 (x3 can be 0 or 1)
f = bdd_and(mgr, x1, x2)
minterms = count_minterms(mgr, f, 3)
println("Minterms in x1 ∧ x2: ", minterms)  # 2.0

# x1 ∨ x2: 6 minterms out of 8
g = bdd_or(mgr, x1, x2)
minterms = count_minterms(mgr, g, 3)
println("Minterms in x1 ∨ x2: ", minterms)  # 6.0

# Calculate probability (uniform distribution)
prob = count_minterms(mgr, g, 3) / 2^3
println("P(x1 ∨ x2): ", prob)  # 0.75
```

### ZDD Count

Count the number of sets in a ZDD family:

```julia
mgr = DDManager(4)

sets = [[1, 2], [2, 3], [1, 3], [4]]
family = zdd_from_sets(mgr, sets)

count = zdd_count(mgr, family)
println("Number of sets: ", count)  # 4
```

## Manager Information

### Node Statistics

Get information about the manager's state:

```julia
mgr = DDManager(10)

# Create some nodes
for i in 1:10
    x = ith_var(mgr, i)
end

# Total nodes in manager
total_nodes = length(mgr.nodes)
println("Total nodes: ", total_nodes)

# Cache statistics
cache_size = length(mgr.cache.entries)
println("Cache size: ", cache_size)

# Unique table statistics
for (level, table) in enumerate(mgr.unique_tables)
    if !isempty(table.slots)
        println("Level $level: ", length(table.slots), " slots")
    end
end
```

### Constants

Access special constants:

```julia
mgr = DDManager(5)

# BDD constants
true_node = mgr.one
false_node = mgr.zero

println("True node: ", true_node)
println("False node: ", false_node)

# Check if a node is a constant
is_true = (x == mgr.one)
is_false = (x == mgr.zero)
is_constant = is_true || is_false
```

## Debugging and Inspection

### Node Information

Inspect individual nodes:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)

# Get node ID (includes complement bit)
node_id = x1

# Check if complemented
is_complemented = (node_id.id & 1) == 1

# Get actual node index
node_index = node_id.id >> 1

# Access node (if not terminal)
if node_index > 0 && node_index <= length(mgr.nodes)
    node = mgr.nodes[node_index]
    println("Variable index: ", node.index)
    println("Then child: ", node.then_child)
    println("Else child: ", node.else_child)
end
```

### Traversal

Traverse a decision diagram:

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]
f = bdd_and(mgr, bdd_and(mgr, x1, x2), x3)

function traverse(mgr, node_id, visited=Set())
    # Avoid revisiting nodes
    if node_id in visited
        return
    end
    push!(visited, node_id)

    # Check if terminal
    if node_id == mgr.zero
        println("Terminal: false")
        return
    elseif node_id == mgr.one
        println("Terminal: true")
        return
    end

    # Get node index (remove complement bit)
    is_complemented = (node_id.id & 1) == 1
    node_index = node_id.id >> 1

    if node_index > 0 && node_index <= length(mgr.nodes)
        node = mgr.nodes[node_index]
        println("Node: var=", node.index,
                " complemented=", is_complemented)

        # Traverse children
        traverse(mgr, node.then_child, visited)
        traverse(mgr, node.else_child, visited)
    end
end

traverse(mgr, f)
```

## Conversion Functions

### BDD ↔ ADD

Convert between BDDs and ADDs:

```julia
mgr = DDManager(2)

# BDD to ADD
x1_bdd = ith_var(mgr, 1)
x2_bdd = ith_var(mgr, 2)
f_bdd = bdd_and(mgr, x1_bdd, x2_bdd)

f_add = bdd_to_add(mgr, f_bdd)
println("BDD converted to ADD")

# ADD to BDD (threshold at 0)
x1_add = add_ith_var(mgr, 1)
x2_add = add_ith_var(mgr, 2)
g_add = add_plus(mgr, x1_add, x2_add)

g_bdd = add_to_bdd(mgr, g_add)
println("ADD converted to BDD")
```

### BDD ↔ ZDD

Convert between BDDs and ZDDs:

```julia
mgr = DDManager(3)

# BDD to ZDD
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
f_bdd = bdd_and(mgr, x1, x2)

f_zdd = bdd_to_zdd(mgr, f_bdd)
println("BDD converted to ZDD")

# ZDD to BDD
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
g_zdd = zdd_product(mgr, s1, s2)

g_bdd = zdd_to_bdd(mgr, g_zdd)
println("ZDD converted to BDD")
```

### ZDD ↔ Sets

Convert between ZDDs and set representations:

```julia
mgr = DDManager(4)

# Sets to ZDD
sets = [[1, 2], [2, 3], [1, 3], [4]]
family = zdd_from_sets(mgr, sets)
println("Created ZDD from sets")

# ZDD to sets
recovered = zdd_to_sets(mgr, family)
println("Recovered sets: ", recovered)

# Verify
@assert sort(sort.(sets)) == sort(sort.(recovered))
```

## Performance Monitoring

### Benchmarking Operations

Measure operation performance:

```julia
using BenchmarkTools

mgr = DDManager(10)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)

# Benchmark AND operation
@benchmark bdd_and($mgr, $x1, $x2)

# Benchmark with larger formulas
vars = [ith_var(mgr, i) for i in 1:10]
@benchmark begin
    result = $vars[1]
    for i in 2:10
        result = bdd_and($mgr, result, $vars[i])
    end
end
```

### Memory Usage

Monitor memory usage:

```julia
mgr = DDManager(100)

# Create many nodes
for i in 1:100
    x = ith_var(mgr, i)
end

# Check memory usage
node_memory = sizeof(mgr.nodes[1]) * length(mgr.nodes)
cache_memory = sizeof(mgr.cache.entries[1]) * length(mgr.cache.entries)

println("Node memory: ", node_memory, " bytes")
println("Cache memory: ", cache_memory, " bytes")
println("Total: ", node_memory + cache_memory, " bytes")
```

## Helper Functions

### Variable Creation

Create multiple variables at once:

```julia
mgr = DDManager(10)

# Create all variables
vars = [ith_var(mgr, i) for i in 1:10]

# Or for ADDs
add_vars = [add_ith_var(mgr, i) for i in 1:10]

# Or for ZDDs
zdd_singletons = [zdd_singleton(mgr, i) for i in 1:10]
```

### Formula Building

Build complex formulas:

```julia
mgr = DDManager(5)
vars = [ith_var(mgr, i) for i in 1:5]

# Conjunction of all variables
conjunction = reduce((acc, v) -> bdd_and(mgr, acc, v), vars)

# Disjunction of all variables
disjunction = reduce((acc, v) -> bdd_or(mgr, acc, v), vars)

# Parity (XOR of all variables)
parity = reduce((acc, v) -> bdd_xor(mgr, acc, v), vars)

# At least k variables true
function at_least_k(mgr, vars, k)
    n = length(vars)
    if k == 0
        return mgr.one
    end
    if k > n
        return mgr.zero
    end

    # Recursive: include first var or not
    with_first = bdd_and(mgr, vars[1],
                         at_least_k(mgr, vars[2:end], k-1))
    without_first = at_least_k(mgr, vars[2:end], k)

    return bdd_or(mgr, with_first, without_first)
end

at_least_3 = at_least_k(mgr, vars, 3)
```

## Validation and Testing

### Equivalence Checking

Check if two formulas are equivalent:

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# Two ways to express the same formula
f1 = bdd_or(mgr, bdd_and(mgr, x1, x2), x3)
f2 = bdd_and(mgr,
    bdd_or(mgr, x1, x3),
    bdd_or(mgr, x2, x3))

# Check equivalence (should be different)
are_equivalent = (f1 == f2)
println("Equivalent: ", are_equivalent)

# De Morgan's law: ¬(x1 ∧ x2) = ¬x1 ∨ ¬x2
lhs = bdd_not(mgr, bdd_and(mgr, x1, x2))
rhs = bdd_or(mgr, bdd_not(mgr, x1), bdd_not(mgr, x2))
@assert lhs == rhs
```

### Satisfiability Checking

Check if a formula is satisfiable:

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# Satisfiable formula
f = bdd_and(mgr, x1, x2)
is_sat = (f != mgr.zero)
println("Satisfiable: ", is_sat)  # true

# Unsatisfiable formula
g = bdd_and(mgr, x1, bdd_not(mgr, x1))
is_unsat = (g == mgr.zero)
println("Unsatisfiable: ", is_unsat)  # true

# Tautology
h = bdd_or(mgr, x1, bdd_not(mgr, x1))
is_tautology = (h == mgr.one)
println("Tautology: ", is_tautology)  # true
```

## Best Practices

### 1. Reuse Managers

```julia
# Good: One manager for related operations
mgr = DDManager(10)
results = []
for i in 1:100
    x = ith_var(mgr, i % 10 + 1)
    push!(results, x)
end

# Bad: Creating managers repeatedly
for i in 1:100
    mgr = DDManager(10)  # Expensive!
    x = ith_var(mgr, 1)
end
```

### 2. Check for Constants

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)

# Check before expensive operations
f = bdd_and(mgr, x1, mgr.zero)
if f == mgr.zero
    println("Result is false, skip further operations")
end
```

### 3. Use Appropriate Counting

```julia
mgr = DDManager(10)
x1, x2 = [ith_var(mgr, i) for i in 1:2]
f = bdd_and(mgr, x1, x2)

# For node count (diagram size)
nodes = count_nodes(mgr, f)

# For satisfying assignments
minterms = count_minterms(mgr, f, 2)

# For paths to true
paths = count_paths(mgr, f)

# Choose based on what you need to measure
```

## See Also

- [BDD Guide](@ref): Binary Decision Diagrams
- [ADD Guide](@ref): Algebraic Decision Diagrams
- [ZDD Guide](@ref): Zero-suppressed Decision Diagrams
- [API Reference](@ref): Complete API documentation
