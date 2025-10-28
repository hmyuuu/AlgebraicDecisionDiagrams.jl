# Binary Decision Diagrams (BDDs)

Binary Decision Diagrams (BDDs) are canonical representations of Boolean functions. They are widely used in formal verification, logic synthesis, and combinatorial optimization.

## What are BDDs?

A BDD is a directed acyclic graph (DAG) where:
- Each non-terminal node represents a Boolean variable
- Each node has two children: `then` (high) and `else` (low)
- Terminal nodes represent Boolean values (true/false)
- The graph is reduced and ordered for canonical representation

## Creating BDDs

### Variables

Create Boolean variables using `ith_var`:

```julia
using AlgebraicDecisionDiagrams

mgr = DDManager(5)

# Create variables x1, x2, x3, x4, x5
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)
x4 = ith_var(mgr, 4)
x5 = ith_var(mgr, 5)
```

### Constants

Access Boolean constants directly from the manager:

```julia
true_node = mgr.one   # Constant true
false_node = mgr.zero # Constant false
```

## Boolean Operations

### Basic Operations

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# AND: x1 ∧ x2
f_and = bdd_and(mgr, x1, x2)

# OR: x1 ∨ x2
f_or = bdd_or(mgr, x1, x2)

# XOR: x1 ⊕ x2
f_xor = bdd_xor(mgr, x1, x2)

# NOT: ¬x1
f_not = bdd_not(mgr, x1)

# NAND: ¬(x1 ∧ x2)
f_nand = bdd_not(mgr, bdd_and(mgr, x1, x2))

# NOR: ¬(x1 ∨ x2)
f_nor = bdd_not(mgr, bdd_or(mgr, x1, x2))

# XNOR: ¬(x1 ⊕ x2) (equivalence)
f_xnor = bdd_not(mgr, bdd_xor(mgr, x1, x2))

# IMPLIES: x1 → x2 = ¬x1 ∨ x2
f_implies = bdd_or(mgr, bdd_not(mgr, x1), x2)
```

### If-Then-Else (ITE)

The ITE operation is fundamental: `ITE(f, g, h) = (f ∧ g) ∨ (¬f ∧ h)`

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# If x1 then x2 else x3
result = bdd_ite(mgr, x1, x2, x3)

# Equivalent to: (x1 ∧ x2) ∨ (¬x1 ∧ x3)
equivalent = bdd_or(mgr,
    bdd_and(mgr, x1, x2),
    bdd_and(mgr, bdd_not(mgr, x1), x3))

# They are the same
@assert result == equivalent
```

### Complex Formulas

Build complex Boolean formulas by composing operations:

```julia
mgr = DDManager(4)
x1, x2, x3, x4 = [ith_var(mgr, i) for i in 1:4]

# Majority function: at least 2 of 3 variables are true
# maj(x1, x2, x3) = (x1 ∧ x2) ∨ (x1 ∧ x3) ∨ (x2 ∧ x3)
majority = bdd_or(mgr,
    bdd_or(mgr,
        bdd_and(mgr, x1, x2),
        bdd_and(mgr, x1, x3)),
    bdd_and(mgr, x2, x3))

# Full adder carry: c_out = (a ∧ b) ∨ (a ∧ c_in) ∨ (b ∧ c_in)
carry = bdd_or(mgr,
    bdd_or(mgr,
        bdd_and(mgr, x1, x2),
        bdd_and(mgr, x1, x3)),
    bdd_and(mgr, x2, x3))

# Full adder sum: s = a ⊕ b ⊕ c_in
sum = bdd_xor(mgr, bdd_xor(mgr, x1, x2), x3)

# Parity: odd number of true variables
parity = bdd_xor(mgr, bdd_xor(mgr, bdd_xor(mgr, x1, x2), x3), x4)
```

## Quantification

### Existential Quantification

`∃x. f(x, y)` returns true if f is true for at least one value of x:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# f = x1 ∧ x2 ∧ x3
f = bdd_and(mgr, bdd_and(mgr, x1, x2), x3)

# ∃x2. f = x1 ∧ x3 (true if x1 and x3 are true, regardless of x2)
exists_x2 = bdd_exists(mgr, f, 2)

# Verify: should be equivalent to x1 ∧ x3
expected = bdd_and(mgr, x1, x3)
@assert exists_x2 == expected
```

### Universal Quantification

`∀x. f(x, y)` returns true if f is true for all values of x:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# f = x1 ∨ x2
f = bdd_or(mgr, x1, x2)

# ∀x2. f = x1 (true only if x1 is true, since x2 could be false)
forall_x2 = bdd_forall(mgr, f, 2)

# Verify: should be equivalent to x1
@assert forall_x2 == x1
```

### Multiple Variables

Quantify over multiple variables:

```julia
mgr = DDManager(4)
x1, x2, x3, x4 = [ith_var(mgr, i) for i in 1:4]

# f = (x1 ∧ x2) ∨ (x3 ∧ x4)
f = bdd_or(mgr,
    bdd_and(mgr, x1, x2),
    bdd_and(mgr, x3, x4))

# ∃x2, x4. f = x1 ∨ x3
result = bdd_exists(mgr, bdd_exists(mgr, f, 2), 4)
```

## Restriction (Cofactoring)

Restriction fixes a variable to a specific value:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# f = (x1 ∧ x2) ∨ x3
f = bdd_or(mgr, bdd_and(mgr, x1, x2), x3)

# Restrict x2 = true: f|x2=1 = x1 ∨ x3
f_x2_true = bdd_restrict(mgr, f, 2, true)

# Restrict x2 = false: f|x2=0 = x3
f_x2_false = bdd_restrict(mgr, f, 2, false)

# Verify Shannon expansion: f = (x2 ∧ f|x2=1) ∨ (¬x2 ∧ f|x2=0)
shannon = bdd_or(mgr,
    bdd_and(mgr, x2, f_x2_true),
    bdd_and(mgr, bdd_not(mgr, x2), f_x2_false))
@assert shannon == f
```

## Evaluation

Evaluate a BDD with a specific variable assignment:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# f = (x1 ∧ x2) ∨ x3
f = bdd_or(mgr, bdd_and(mgr, x1, x2), x3)

# Evaluate with x1=true, x2=true, x3=false
assignment = Dict(1 => true, 2 => true, 3 => false)
result = bdd_eval(mgr, f, assignment)  # true

# Evaluate with x1=true, x2=false, x3=false
assignment = Dict(1 => true, 2 => false, 3 => false)
result = bdd_eval(mgr, f, assignment)  # false

# Evaluate with x1=false, x2=false, x3=true
assignment = Dict(1 => false, 2 => false, 3 => true)
result = bdd_eval(mgr, f, assignment)  # true
```

## Counting and Analysis

### Count Nodes

Count the number of nodes in the BDD:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)

# Simple AND: 2 nodes (x1 and x2)
f = bdd_and(mgr, x1, x2)
println("Nodes: ", count_nodes(mgr, f))  # 2
```

### Count Paths

Count the number of paths from root to true terminal:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)

# x1 ∧ x2: one path (both true)
f = bdd_and(mgr, x1, x2)
println("Paths: ", count_paths(mgr, f))  # 1

# x1 ∨ x2: three paths (x1 true, x2 true, or both)
g = bdd_or(mgr, x1, x2)
println("Paths: ", count_paths(mgr, g))  # 3
```

### Count Minterms

Count the number of satisfying assignments:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# x1 ∧ x2: 2 minterms out of 8 (x3 can be 0 or 1)
f = bdd_and(mgr, x1, x2)
println("Minterms: ", count_minterms(mgr, f, 3))  # 2.0

# x1 ∨ x2: 6 minterms out of 8
g = bdd_or(mgr, x1, x2)
println("Minterms: ", count_minterms(mgr, g, 3))  # 6.0

# Probability (assuming uniform distribution)
prob = count_minterms(mgr, g, 3) / 2^3  # 0.75
```

## Complement Edges

BDDs in this implementation use complement edges for efficiency:

- The least significant bit (LSB) of a node pointer indicates negation
- NOT operation is O(1) - just flip the LSB
- Reduces node count by approximately 2x

```julia
mgr = DDManager(2)
x1 = ith_var(mgr, 1)

# NOT is extremely fast (just bit flip)
not_x1 = bdd_not(mgr, x1)

# Double negation returns original
@assert bdd_not(mgr, not_x1) == x1

# Complement edges are transparent to users
# All operations handle them automatically
```

## Performance Tips

### 1. Variable Ordering

Variable ordering significantly affects BDD size:

```julia
# Good: Related variables close together
# f = (x1 ∧ x2) ∨ (x3 ∧ x4)
# Order: x1, x2, x3, x4 → small BDD

# Bad: Interleaved variables
# Order: x1, x3, x2, x4 → larger BDD

# Note: Dynamic reordering not yet implemented
```

### 2. Operation Caching

Operations are automatically cached:

```julia
mgr = DDManager(10)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)

# First call: computes and caches
result1 = bdd_and(mgr, x1, x2)  # ~5 ns

# Second call: cache hit
result2 = bdd_and(mgr, x1, x2)  # ~5 ns (from cache)

@assert result1 == result2
```

### 3. Build Bottom-Up

Build BDDs bottom-up for better performance:

```julia
mgr = DDManager(4)
vars = [ith_var(mgr, i) for i in 1:4]

# Good: Build incrementally
result = vars[1]
for i in 2:4
    result = bdd_and(mgr, result, vars[i])
end

# Also good: Use reduce
result = reduce((acc, v) -> bdd_and(mgr, acc, v), vars)
```

## Common Patterns

### Encoding Constraints

```julia
mgr = DDManager(4)
x1, x2, x3, x4 = [ith_var(mgr, i) for i in 1:4]

# At least one variable is true
at_least_one = bdd_or(mgr, bdd_or(mgr, bdd_or(mgr, x1, x2), x3), x4)

# Exactly one variable is true
exactly_one = bdd_and(mgr,
    at_least_one,
    bdd_and(mgr,
        bdd_not(mgr, bdd_and(mgr, x1, x2)),
        bdd_and(mgr,
            bdd_not(mgr, bdd_and(mgr, x1, x3)),
            bdd_and(mgr,
                bdd_not(mgr, bdd_and(mgr, x1, x4)),
                bdd_and(mgr,
                    bdd_not(mgr, bdd_and(mgr, x2, x3)),
                    bdd_and(mgr,
                        bdd_not(mgr, bdd_and(mgr, x2, x4)),
                        bdd_not(mgr, bdd_and(mgr, x3, x4))))))))

# At most two variables are true
at_most_two = bdd_not(mgr,
    bdd_or(mgr,
        bdd_and(mgr, bdd_and(mgr, x1, x2), x3),
        bdd_or(mgr,
            bdd_and(mgr, bdd_and(mgr, x1, x2), x4),
            bdd_or(mgr,
                bdd_and(mgr, bdd_and(mgr, x1, x3), x4),
                bdd_and(mgr, bdd_and(mgr, x2, x3), x4)))))
```

### SAT Solving

Check if a formula is satisfiable:

```julia
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# Formula: (x1 ∨ x2) ∧ (¬x1 ∨ x3) ∧ (¬x2 ∨ ¬x3)
clause1 = bdd_or(mgr, x1, x2)
clause2 = bdd_or(mgr, bdd_not(mgr, x1), x3)
clause3 = bdd_or(mgr, bdd_not(mgr, x2), bdd_not(mgr, x3))

formula = bdd_and(mgr, bdd_and(mgr, clause1, clause2), clause3)

# Check satisfiability
is_sat = formula != mgr.zero
println("Satisfiable: ", is_sat)

# Count solutions
num_solutions = count_minterms(mgr, formula, 3)
println("Number of solutions: ", num_solutions)
```

## See Also

- [ADD Guide](@ref): Algebraic Decision Diagrams
- [ZDD Guide](@ref): Zero-suppressed Decision Diagrams
- [API Reference](@ref): Complete API documentation
