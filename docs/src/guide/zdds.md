# Zero-suppressed Decision Diagrams (ZDDs)

Zero-suppressed Decision Diagrams (ZDDs) are a variant of BDDs optimized for representing sparse sets and combinatorial objects. They are particularly efficient for set families where most elements are absent.

## What are ZDDs?

ZDDs differ from BDDs in their reduction rule:
- **BDD reduction**: If both children are the same, eliminate the node
- **ZDD reduction**: If the then-child is empty (⊥), eliminate the node and return the else-child

This makes ZDDs ideal for:
- Sparse set families
- Combinatorial structures (paths, cuts, matchings)
- Power set operations
- Constraint satisfaction problems

## Creating ZDDs

### Empty Set and Base Set

```julia
using AlgebraicDecisionDiagrams

mgr = DDManager(5)

# Empty family: ∅
empty = mgr.zero

# Family containing only the empty set: {∅}
base = mgr.one
```

### Singletons

Create a family containing a single element:

```julia
mgr = DDManager(5)

# Family containing {1}: {{1}}
s1 = zdd_singleton(mgr, 1)

# Family containing {2}: {{2}}
s2 = zdd_singleton(mgr, 2)

# Family containing {5}: {{5}}
s5 = zdd_singleton(mgr, 5)
```

### From Sets

Create a ZDD from a collection of sets:

```julia
mgr = DDManager(4)

# Family of sets: {{1, 2}, {2, 3}, {1, 3}, {4}}
sets = [
    [1, 2],
    [2, 3],
    [1, 3],
    [4]
]

family = zdd_from_sets(mgr, sets)

# Count sets in family
count = zdd_count(mgr, family)  # 4

# Convert back to sets
recovered = zdd_to_sets(mgr, family)
println(recovered)  # [[1, 2], [2, 3], [1, 3], [4]]
```

## Set Operations

### Union

Union of two set families:

```julia
mgr = DDManager(3)

# F1 = {{1}, {2}}
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
f1 = zdd_union(mgr, s1, s2)

# F2 = {{2}, {3}}
s3 = zdd_singleton(mgr, 3)
f2 = zdd_union(mgr, s2, s3)

# F1 ∪ F2 = {{1}, {2}, {3}}
union = zdd_union(mgr, f1, f2)

sets = zdd_to_sets(mgr, union)
println(sets)  # [[1], [2], [3]]
```

### Intersection

Intersection of two set families:

```julia
mgr = DDManager(3)

# F1 = {{1}, {2}}
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
f1 = zdd_union(mgr, s1, s2)

# F2 = {{2}, {3}}
s3 = zdd_singleton(mgr, 3)
f2 = zdd_union(mgr, s2, s3)

# F1 ∩ F2 = {{2}}
intersection = zdd_intersection(mgr, f1, f2)

sets = zdd_to_sets(mgr, intersection)
println(sets)  # [[2]]
```

### Difference

Set difference:

```julia
mgr = DDManager(3)

# F1 = {{1}, {2}, {3}}
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
s3 = zdd_singleton(mgr, 3)
f1 = zdd_union(mgr, zdd_union(mgr, s1, s2), s3)

# F2 = {{2}}
f2 = s2

# F1 \ F2 = {{1}, {3}}
difference = zdd_difference(mgr, f1, f2)

sets = zdd_to_sets(mgr, difference)
println(sets)  # [[1], [3]]
```

### Product (Cartesian Product)

Cartesian product of set families:

```julia
mgr = DDManager(4)

# F1 = {{1}, {2}}
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
f1 = zdd_union(mgr, s1, s2)

# F2 = {{3}, {4}}
s3 = zdd_singleton(mgr, 3)
s4 = zdd_singleton(mgr, 4)
f2 = zdd_union(mgr, s3, s4)

# F1 × F2 = {{1,3}, {1,4}, {2,3}, {2,4}}
product = zdd_product(mgr, f1, f2)

sets = zdd_to_sets(mgr, product)
println(sets)  # [[1,3], [1,4], [2,3], [2,4]]
```

## Counting

### Count Sets

Count the number of sets in a family:

```julia
mgr = DDManager(4)

sets = [[1, 2], [2, 3], [1, 3], [4]]
family = zdd_from_sets(mgr, sets)

count = zdd_count(mgr, family)
println("Number of sets: ", count)  # 4
```

### Count Nodes

Count nodes in the ZDD:

```julia
mgr = DDManager(4)

sets = [[1, 2], [2, 3], [1, 3], [4]]
family = zdd_from_sets(mgr, sets)

nodes = count_nodes(mgr, family)
println("Number of nodes: ", nodes)
```

## Converting Between BDDs and ZDDs

### BDD to ZDD

Convert a BDD to a ZDD (characteristic function to set family):

```julia
mgr = DDManager(3)

# BDD: x1 ∧ x2 (true when both x1 and x2 are true)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
bdd = bdd_and(mgr, x1, x2)

# Convert to ZDD: family of sets where x1 and x2 are present
zdd = bdd_to_zdd(mgr, bdd)

# Should contain sets with both 1 and 2
sets = zdd_to_sets(mgr, zdd)
println(sets)  # [[1, 2], [1, 2, 3]]
```

### ZDD to BDD

Convert a ZDD to a BDD:

```julia
mgr = DDManager(3)

# ZDD: {{1, 2}}
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
zdd = zdd_product(mgr, s1, s2)

# Convert to BDD
bdd = zdd_to_bdd(mgr, zdd)

# BDD should be true when x1=1, x2=1, x3=0
assignment = Dict(1 => true, 2 => true, 3 => false)
result = bdd_eval(mgr, bdd, assignment)
println(result)  # true
```

## Applications

### Power Set

Generate all subsets of a set:

```julia
mgr = DDManager(3)

# Start with {∅}
result = mgr.one

# Add each element optionally
for i in 1:3
    singleton = zdd_singleton(mgr, i)
    # For each existing set, add version with and without element i
    with_i = zdd_product(mgr, result, singleton)
    result = zdd_union(mgr, result, with_i)
end

# Result: all subsets of {1, 2, 3}
sets = zdd_to_sets(mgr, result)
println("Power set: ", sets)
# [[], [1], [2], [1,2], [3], [1,3], [2,3], [1,2,3]]
```

### Combinations

Generate all k-combinations:

```julia
mgr = DDManager(5)

# Generate all 3-combinations of {1, 2, 3, 4, 5}
function combinations(mgr, n, k)
    if k == 0
        return mgr.one  # {∅}
    end
    if k > n
        return mgr.zero  # ∅
    end

    # Recursive: combinations with element n, or without
    with_n = zdd_product(mgr,
        combinations(mgr, n-1, k-1),
        zdd_singleton(mgr, n))
    without_n = combinations(mgr, n-1, k)

    return zdd_union(mgr, with_n, without_n)
end

c_3_5 = combinations(mgr, 5, 3)
sets = zdd_to_sets(mgr, c_3_5)
println("3-combinations of {1,2,3,4,5}: ", length(sets))  # 10
```

### Graph Paths

Represent all paths in a graph:

```julia
mgr = DDManager(6)

# Graph edges: 1-2, 2-3, 1-3, 3-4, 2-4
# Represent each edge as a number
edges = Dict(
    (1,2) => 1,
    (2,3) => 2,
    (1,3) => 3,
    (3,4) => 4,
    (2,4) => 5
)

# Paths from 1 to 4:
# Path 1: 1->2->4 (edges 1, 5)
path1 = zdd_product(mgr,
    zdd_singleton(mgr, edges[(1,2)]),
    zdd_singleton(mgr, edges[(2,4)]))

# Path 2: 1->3->4 (edges 3, 4)
path2 = zdd_product(mgr,
    zdd_singleton(mgr, edges[(1,3)]),
    zdd_singleton(mgr, edges[(3,4)]))

# Path 3: 1->2->3->4 (edges 1, 2, 4)
path3 = zdd_product(mgr,
    zdd_product(mgr,
        zdd_singleton(mgr, edges[(1,2)]),
        zdd_singleton(mgr, edges[(2,3)])),
    zdd_singleton(mgr, edges[(3,4)]))

# All paths
all_paths = zdd_union(mgr, zdd_union(mgr, path1, path2), path3)

paths = zdd_to_sets(mgr, all_paths)
println("Paths from 1 to 4: ", paths)
```

### Constraint Satisfaction

Represent solutions to constraints:

```julia
mgr = DDManager(4)

# Variables: x1, x2, x3, x4
# Constraint 1: At least one of x1, x2 must be selected
# Constraint 2: If x1 is selected, x3 must be selected
# Constraint 3: x2 and x4 cannot both be selected

# Start with all possible subsets
all_subsets = mgr.one
for i in 1:4
    singleton = zdd_singleton(mgr, i)
    with_i = zdd_product(mgr, all_subsets, singleton)
    all_subsets = zdd_union(mgr, all_subsets, with_i)
end

# Apply constraints by filtering
# (This is a simplified example - real implementation would be more efficient)

solutions = zdd_to_sets(mgr, all_subsets)

# Filter: at least one of x1, x2
solutions = filter(s -> 1 in s || 2 in s, solutions)

# Filter: if x1 then x3
solutions = filter(s -> !(1 in s) || (3 in s), solutions)

# Filter: not both x2 and x4
solutions = filter(s -> !(2 in s && 4 in s), solutions)

println("Valid solutions: ", solutions)
```

## Performance Tips

### 1. ZDDs vs BDDs for Sparse Sets

```julia
mgr = DDManager(100)

# For sparse sets (few elements), ZDDs are much more efficient
sparse_sets = [
    [1, 50],
    [25, 75],
    [10, 90]
]

# ZDD: Very compact
zdd = zdd_from_sets(mgr, sparse_sets)
zdd_nodes = count_nodes(mgr, zdd)

# BDD would be much larger for the same representation
println("ZDD nodes: ", zdd_nodes)  # Small
```

### 2. Build Incrementally

```julia
mgr = DDManager(10)

# Good: Build incrementally
result = mgr.one
for i in 1:10
    singleton = zdd_singleton(mgr, i)
    result = zdd_union(mgr, result, singleton)
end

# Result: {{1}, {2}, ..., {10}}
```

### 3. Use Product for Set Construction

```julia
mgr = DDManager(5)

# Good: Use product to build sets
s1 = zdd_singleton(mgr, 1)
s2 = zdd_singleton(mgr, 2)
s3 = zdd_singleton(mgr, 3)

# {{1, 2, 3}}
set_123 = zdd_product(mgr, zdd_product(mgr, s1, s2), s3)

# More efficient than converting from array
```

## ZDD Reduction Rule

Understanding the ZDD reduction rule:

```julia
# BDD reduction: if then_child == else_child, return child
# ZDD reduction: if then_child == ⊥ (empty), return else_child

# Example: Representing {{2}}
# Variable 1: else-child points to node for variable 2
#            then-child would be ⊥, so node is eliminated
# Variable 2: then-child is ⊤ (base set)
#            else-child is ⊥ (empty)
#            Node is kept because then-child ≠ ⊥

# This makes ZDDs compact for sparse sets
```

## Common Patterns

### Set Family Operations

```julia
mgr = DDManager(5)

# Create families
f1 = zdd_from_sets(mgr, [[1, 2], [3]])
f2 = zdd_from_sets(mgr, [[2, 3], [4]])

# Union: all sets from either family
union = zdd_union(mgr, f1, f2)

# Intersection: sets in both families
intersection = zdd_intersection(mgr, f1, f2)

# Difference: sets in f1 but not f2
difference = zdd_difference(mgr, f1, f2)

# Product: combine sets from both families
product = zdd_product(mgr, f1, f2)
```

### Filtering Sets

```julia
mgr = DDManager(5)

# Start with a family
family = zdd_from_sets(mgr, [[1], [1, 2], [2, 3], [3, 4, 5]])

# Filter: keep only sets containing element 2
s2 = zdd_singleton(mgr, 2)

# Sets containing 2 are those that intersect with {2}
# (More complex filtering would require custom operations)

sets = zdd_to_sets(mgr, family)
filtered = filter(s -> 2 in s, sets)
result = zdd_from_sets(mgr, filtered)
```

## Limitations

### No Complement Edges

ZDDs don't use complement edges:
- All operations must be explicit
- May result in larger diagrams than BDDs for dense sets

### Element Ordering

Like BDDs, element ordering matters:
- Different orderings can lead to different sizes
- No dynamic reordering yet implemented

### Conversion Overhead

Converting between sets and ZDDs has overhead:
- Use native ZDD operations when possible
- Avoid repeated conversions

## See Also

- [BDD Guide](@ref): Binary Decision Diagrams
- [ADD Guide](@ref): Algebraic Decision Diagrams
- [API Reference](@ref): Complete API documentation
