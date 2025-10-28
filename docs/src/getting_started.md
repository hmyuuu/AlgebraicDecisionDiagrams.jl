# Getting Started

This guide will help you get started with AlgebraicDecisionDiagrams.jl.

## Installation

Install the package using Julia's package manager:

```julia
using Pkg
Pkg.add("AlgebraicDecisionDiagrams")
```

For development:

```julia
Pkg.develop(url="https://github.com/yourusername/AlgebraicDecisionDiagrams.jl")
```

## Basic Concepts

### Decision Diagrams

Decision diagrams are directed acyclic graphs (DAGs) used to represent functions over discrete variables. They provide:

- **Canonical representation**: Unique representation for each function
- **Efficient operations**: Boolean/arithmetic operations in polynomial time
- **Compact storage**: Often exponentially smaller than truth tables

### Manager

All operations require a `DDManager` that manages the unique table and operation cache:

```julia
using AlgebraicDecisionDiagrams

# Create a manager for up to 10 variables
mgr = DDManager(10)
```

The manager maintains:
- Unique table for canonical node representation
- Computed table for operation memoization
- Reference counting for memory management

## Your First BDD

Let's create a simple Boolean function: `f(x₁, x₂) = x₁ ∧ x₂`

```julia
using AlgebraicDecisionDiagrams

# Create manager
mgr = DDManager(2)

# Create variables
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)

# Create function: x1 AND x2
f = bdd_and(mgr, x1, x2)

# Count nodes
println("Nodes: ", count_nodes(mgr, f))  # 2

# Count satisfying assignments
println("Minterms: ", count_minterms(mgr, f, 2))  # 1.0 (only 11 satisfies)

# Evaluate
assignment = Dict(1 => true, 2 => true)
println("f(1,1) = ", bdd_eval(mgr, f, assignment))  # true

assignment = Dict(1 => true, 2 => false)
println("f(1,0) = ", bdd_eval(mgr, f, assignment))  # false
```

## Your First ADD

ADDs extend BDDs to real-valued functions:

```julia
using AlgebraicDecisionDiagrams

mgr = DDManager(2)

# Create ADD variables (0-1 functions)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# Create constants
c1 = add_const(mgr, 5.0)
c2 = add_const(mgr, 3.0)

# Arithmetic: f = 5*x1 + 3*x2
f = add_plus(mgr,
    add_times(mgr, c1, x1),
    add_times(mgr, c2, x2))

# Evaluate
assignment = Dict(1 => 1.0, 2 => 1.0)
println("f(1,1) = ", add_eval(mgr, f, assignment))  # 8.0

assignment = Dict(1 => 1.0, 2 => 0.0)
println("f(1,0) = ", add_eval(mgr, f, assignment))  # 5.0
```

## Your First ZDD

ZDDs are optimized for representing sparse sets:

```julia
using AlgebraicDecisionDiagrams

mgr = DDManager(4)

# Create sets
sets = [
    [1, 2],    # {1, 2}
    [2, 3],    # {2, 3}
    [1, 3],    # {1, 3}
    [4]        # {4}
]

# Create ZDD representing this family of sets
family = zdd_from_sets(mgr, sets)

# Count sets in family
println("Number of sets: ", zdd_count(mgr, family))  # 4

# Convert back to sets
recovered = zdd_to_sets(mgr, family)
println("Sets: ", recovered)

# Set operations
s1 = zdd_singleton(mgr, 1)  # {1}
s2 = zdd_singleton(mgr, 2)  # {2}

# Union: {{1}, {2}}
union = zdd_union(mgr, s1, s2)

# Product: {{1,2}}
product = zdd_product(mgr, s1, s2)
```

## Common Patterns

### Building Complex Formulas

```julia
mgr = DDManager(4)
x1, x2, x3, x4 = [ith_var(mgr, i) for i in 1:4]

# (x1 ∧ x2) ∨ (x3 ∧ x4)
f = bdd_or(mgr,
    bdd_and(mgr, x1, x2),
    bdd_and(mgr, x3, x4))

# ¬(x1 ⊕ x2)  (XNOR)
g = bdd_not(mgr, bdd_xor(mgr, x1, x2))
```

### Quantification

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# f = x1 ∧ x2 ∧ x3
f = bdd_and(mgr, bdd_and(mgr, x1, x2), x3)

# ∃x2. f = x1 ∧ x3
exists_x2 = bdd_exists(mgr, f, 2)

# ∀x2. f = false (not true for all x2)
forall_x2 = bdd_forall(mgr, f, 2)
```

### Restriction

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# f = x1 ∧ x2 ∧ x3
f = bdd_and(mgr, bdd_and(mgr, x1, x2), x3)

# Restrict x2 = true: f|x2=1 = x1 ∧ x3
restricted = bdd_restrict(mgr, f, 2, true)
```

## Performance Tips

### 1. Reuse Managers

Creating a manager has overhead (~900μs). Reuse managers when possible:

```julia
# Good: One manager for all operations
mgr = DDManager(10)
for i in 1:1000
    x = ith_var(mgr, i % 10 + 1)
    # ... operations ...
end

# Bad: Creating manager in loop
for i in 1:1000
    mgr = DDManager(10)  # Expensive!
    x = ith_var(mgr, 1)
end
```

### 2. Variable Ordering Matters

Variable ordering significantly affects BDD size:

```julia
mgr = DDManager(4)

# Good ordering for (x1 ∧ x2) ∨ (x3 ∧ x4)
x1, x2, x3, x4 = [ith_var(mgr, i) for i in 1:4]
f = bdd_or(mgr, bdd_and(mgr, x1, x2), bdd_and(mgr, x3, x4))
println("Nodes: ", count_nodes(mgr, f))  # Small

# Bad ordering can lead to exponential blowup
# (Variable reordering not yet implemented)
```

### 3. Use Appropriate DD Type

- **BDDs**: Boolean functions, logic circuits
- **ADDs**: Functions with numeric values, probabilities
- **ZDDs**: Sparse sets, combinatorial problems

### 4. Monitor Memory Usage

```julia
mgr = DDManager(10)

# ... many operations ...

# Check statistics
println("Total nodes: ", length(mgr.nodes))
println("Cache size: ", length(mgr.cache.entries))

# Garbage collection (if needed)
# gc_collect(mgr)  # Not yet implemented
```

## Next Steps

- [BDD Guide](guide/bdds.md): Detailed guide to Binary Decision Diagrams
- [ADD Guide](guide/adds.md): Detailed guide to Algebraic Decision Diagrams
- [ZDD Guide](guide/zdds.md): Detailed guide to Zero-suppressed Decision Diagrams
- [Performance](@ref): Performance optimization and benchmarking
- [API Reference](@ref): Complete API documentation
