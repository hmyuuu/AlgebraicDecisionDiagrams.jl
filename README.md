# AlgebraicDecisionDiagrams.jl

[![CI](https://github.com/hmyuuu/AlgebraicDecisionDiagrams.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/hmyuuu/AlgebraicDecisionDiagrams.jl/actions/workflows/CI.yml)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://hmyuuu.github.io/AlgebraicDecisionDiagrams.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://hmyuuu.github.io/AlgebraicDecisionDiagrams.jl/dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Julia Version](https://img.shields.io/badge/julia-v1.0+-blue.svg)](https://julialang.org/)

> **Note**: This project is under active development.

A Julia implementation of Binary Decision Diagrams (BDDs) and Algebraic Decision Diagrams (ADDs), inspired by the CUDD library.

## Features

- **Binary Decision Diagrams (BDDs)**: Efficient representation of Boolean functions
  - Complement edges for compact representation
  - Standard operations: AND, OR, XOR, NOT, ITE
  - Quantification: existential and universal
  - Restriction and cofactoring

- **Algebraic Decision Diagrams (ADDs)**: Extension to real-valued functions
  - Arithmetic operations: addition, subtraction, multiplication, division
  - Min/max operations
  - Threshold conversion to BDDs

- **Zero-suppressed Decision Diagrams (ZDDs)**: Efficient representation of sparse sets
  - Specialized for combinatorial problems and set families
  - Set operations: union, intersection, difference
  - Subset operations and counting
  - Conversion to/from explicit set representations

- **Optimizations**:
  - Hash consing (unique table) for canonical representation
  - Operation caching (computed table) for memoization
  - Efficient memory management with garbage collection

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/yourusername/AlgebraicDecisionDiagrams.jl")
```

## Quick Start

### Binary Decision Diagrams (BDDs)

```julia
using AlgebraicDecisionDiagrams

# Create a manager for 3 variables
mgr = DDManager(3)

# Create variables
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
x3 = ith_var(mgr, 3)

# Boolean operations
f = bdd_and(mgr, x1, x2)           # x1 ∧ x2
g = bdd_or(mgr, x1, x3)            # x1 ∨ x3
h = bdd_not(mgr, f)                # ¬(x1 ∧ x2)

# If-Then-Else
result = bdd_ite(mgr, x1, x2, x3)  # if x1 then x2 else x3

# Restriction (cofactor)
f_x1_true = bdd_restrict(mgr, f, 1, true)   # f with x1 = 1

# Quantification
exists_x1 = bdd_exists(mgr, f, [1])         # ∃x1. f
forall_x2 = bdd_forall(mgr, f, [2])         # ∀x2. f

# Count nodes and paths
println("Nodes: ", count_nodes(mgr, f))
println("Paths: ", count_paths(mgr, f))
println("Minterms: ", count_minterms(mgr, f, 3))
```

### Algebraic Decision Diagrams (ADDs)

```julia
using AlgebraicDecisionDiagrams

# Create a manager
mgr = DDManager(3)

# Create ADD variables (0-1 valued)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# Create constants
c1 = add_const(mgr, 5.0)
c2 = add_const(mgr, 10.0)

# Arithmetic operations
sum = add_plus(mgr, x1, x2)              # x1 + x2
product = add_times(mgr, x1, c1)         # x1 * 5.0
scaled = add_scalar_multiply(mgr, sum, 2.0)  # (x1 + x2) * 2.0

# Min/max operations
maximum = add_max(mgr, c1, c2)           # max(5.0, 10.0)
minimum = add_min(mgr, c1, c2)           # min(5.0, 10.0)

# Evaluate ADD with variable assignment
assignment = Dict(1 => true, 2 => false)
value = add_eval(mgr, sum, assignment)
println("Value: ", value)

# Find extrema
max_val = add_find_max(mgr, sum)
min_val = add_find_min(mgr, sum)

# Convert ADD to BDD by thresholding
bdd = add_threshold(mgr, sum, 1.0)  # BDD where sum >= 1.0
```

### Zero-suppressed Decision Diagrams (ZDDs)

```julia
using AlgebraicDecisionDiagrams

# Create a manager
mgr = DDManager(4)

# Create a family of sets from explicit representation
sets = [[1, 2], [2, 3], [1, 3], [4]]
family = zdd_from_sets(mgr, sets)

println("Number of sets: ", zdd_count(mgr, family))

# Set operations
sets2 = [[1, 2], [1, 4]]
family2 = zdd_from_sets(mgr, sets2)

# Union, intersection, difference
union_result = zdd_union(mgr, family, family2)
intersect_result = zdd_intersection(mgr, family, family2)
diff_result = zdd_difference(mgr, family, family2)

# Convert back to explicit sets
result_sets = zdd_to_sets(mgr, intersect_result)
println("Intersection: ", result_sets)

# Subset operations
sets_with_1 = zdd_subset1(mgr, family, 1)  # Sets containing element 1
sets_without_1 = zdd_subset0(mgr, family, 1)  # Sets not containing element 1
```

## Visualization

Export decision diagrams to DOT format for visualization with Graphviz:

```julia
# Create a BDD
mgr = DDManager(3)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
f = bdd_and(mgr, x1, x2)

# Export to DOT file
to_dot(mgr, f, "diagram.dot")

# Visualize with Graphviz (in terminal)
# dot -Tpng diagram.dot -o diagram.png
```

## Architecture

The implementation follows the CUDD architecture:

- **Nodes**: Internal representation with variable index and children
- **Unique Table**: Hash table ensuring canonical representation (one per variable level)
- **Computed Table**: Cache for memoizing operation results
- **Complement Edges**: BDDs use complement edges for compact representation
- **Variable Ordering**: Supports custom variable orderings (identity by default)

## Performance Tips

1. **Variable Ordering**: The order of variables significantly affects BDD size. Consider reordering for better performance.

2. **Garbage Collection**: Call `garbage_collect!(mgr)` periodically to reclaim unused nodes.

3. **Cache Size**: Adjust cache size when creating the manager:
   ```julia
   mgr = DDManager(num_vars, cache_size=1048576)  # Larger cache
   ```

4. **Reference Counting**: The package uses automatic garbage collection, but you can manually manage references with `ref!` and `deref!` for fine-grained control.

## Examples

### Example 1: Boolean Function Simplification

```julia
mgr = DDManager(4)
x1, x2, x3, x4 = [ith_var(mgr, i) for i in 1:4]

# (x1 ∧ x2) ∨ (x3 ∧ x4)
f = bdd_or(mgr, bdd_and(mgr, x1, x2), bdd_and(mgr, x3, x4))

println("Nodes in f: ", count_nodes(mgr, f))
```

### Example 2: Satisfiability Counting

```julia
mgr = DDManager(3)
x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

# x1 ⊕ x2 ⊕ x3 (odd parity)
f = bdd_xor(mgr, bdd_xor(mgr, x1, x2), x3)

# Count satisfying assignments
num_solutions = count_minterms(mgr, f, 3)
println("Number of satisfying assignments: ", num_solutions)
```

### Example 3: Probabilistic Reasoning with ADDs

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)  # Event 1 (0 or 1)
x2 = add_ith_var(mgr, 2)  # Event 2 (0 or 1)

# Probability weights
p1 = add_const(mgr, 0.7)
p2 = add_const(mgr, 0.3)

# Weighted sum: 0.7*x1 + 0.3*x2
weighted = add_plus(mgr, add_times(mgr, x1, p1), add_times(mgr, x2, p2))

# Evaluate for different scenarios
println("Both false: ", add_eval(mgr, weighted, Dict(1=>false, 2=>false)))
println("Both true: ", add_eval(mgr, weighted, Dict(1=>true, 2=>true)))
```

### Example 4: Combinatorial Sets with ZDDs

```julia
mgr = DDManager(4)

# Create a family of sets: {{1,2}, {2,3}, {1,3}, {4}}
sets = [[1, 2], [2, 3], [1, 3], [4]]
family = zdd_from_sets(mgr, sets)

println("Number of sets: ", zdd_count(mgr, family))

# Create another family: {{1,2}, {1,4}}
sets2 = [[1, 2], [1, 4]]
family2 = zdd_from_sets(mgr, sets2)

# Intersection: sets in both families
intersect = zdd_intersection(mgr, family, family2)
result = zdd_to_sets(mgr, intersect)
println("Intersection: ", result)  # Should be [[1, 2]]

# Union: all sets from both families
union = zdd_union(mgr, family, family2)
println("Union size: ", zdd_count(mgr, union))

# Subset operations: sets containing element 1
subset_with_1 = zdd_subset1(mgr, family, 1)
println("Sets containing 1: ", zdd_to_sets(mgr, subset_with_1))
```

### Example 5: Path Enumeration with ZDDs

```julia
# Represent all paths in a graph as sets of edges
mgr = DDManager(6)

# Graph edges: 1-2, 2-3, 1-3, 3-4, 2-4
# Paths from 1 to 4:
# Path 1: edges {1,2,4} (1->2->4)
# Path 2: edges {1,3,4} (1->3->4)
# Path 3: edges {1,2,3,4} (1->2->3->4)

paths = [
    [1, 2, 4],      # 1->2->4
    [1, 3, 4],      # 1->3->4
    [1, 2, 3, 4]    # 1->2->3->4
]

all_paths = zdd_from_sets(mgr, paths)
println("Total paths: ", zdd_count(mgr, all_paths))

# Find paths using edge 2 (edge 1->2)
paths_via_edge2 = zdd_subset1(mgr, all_paths, 2)
println("Paths via edge 2: ", zdd_to_sets(mgr, paths_via_edge2))
```

## References

- [CUDD](https://github.com/cuddorg/cudd)

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
