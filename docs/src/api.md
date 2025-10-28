# API Reference

Complete API documentation for AlgebraicDecisionDiagrams.jl.

## Manager

```@docs
DDManager
```

### Constructor

```julia
DDManager(num_vars::Int)
```

Create a decision diagram manager for up to `num_vars` variables.

**Arguments:**
- `num_vars::Int`: Maximum number of variables

**Returns:**
- `DDManager`: A new manager instance

**Example:**
```julia
mgr = DDManager(10)  # Manager for up to 10 variables
```

## Binary Decision Diagrams (BDDs)

### Variable Creation

```julia
ith_var(mgr::DDManager, i::Int) -> NodeId
```

Create a BDD variable for the i-th variable.

**Arguments:**
- `mgr::DDManager`: The manager
- `i::Int`: Variable index (1-based)

**Returns:**
- `NodeId`: BDD representing the variable

**Example:**
```julia
mgr = DDManager(5)
x1 = ith_var(mgr, 1)
x2 = ith_var(mgr, 2)
```

### Boolean Operations

```julia
bdd_and(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Compute the conjunction (AND) of two BDDs.

**Arguments:**
- `mgr::DDManager`: The manager
- `f::NodeId`: First BDD
- `g::NodeId`: Second BDD

**Returns:**
- `NodeId`: BDD representing f ∧ g

**Example:**
```julia
result = bdd_and(mgr, x1, x2)  # x1 ∧ x2
```

---

```julia
bdd_or(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Compute the disjunction (OR) of two BDDs.

**Returns:**
- `NodeId`: BDD representing f ∨ g

---

```julia
bdd_xor(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Compute the exclusive OR (XOR) of two BDDs.

**Returns:**
- `NodeId`: BDD representing f ⊕ g

---

```julia
bdd_not(mgr::DDManager, f::NodeId) -> NodeId
```

Compute the negation (NOT) of a BDD. This is an O(1) operation using complement edges.

**Returns:**
- `NodeId`: BDD representing ¬f

---

```julia
bdd_ite(mgr::DDManager, f::NodeId, g::NodeId, h::NodeId) -> NodeId
```

Compute the if-then-else operation: (f ∧ g) ∨ (¬f ∧ h).

**Arguments:**
- `f::NodeId`: Condition BDD
- `g::NodeId`: Then BDD
- `h::NodeId`: Else BDD

**Returns:**
- `NodeId`: BDD representing ITE(f, g, h)

### Quantification

```julia
bdd_exists(mgr::DDManager, f::NodeId, var::Int) -> NodeId
```

Existential quantification: ∃var. f

**Arguments:**
- `f::NodeId`: BDD to quantify
- `var::Int`: Variable to quantify over

**Returns:**
- `NodeId`: BDD representing ∃var. f

---

```julia
bdd_forall(mgr::DDManager, f::NodeId, var::Int) -> NodeId
```

Universal quantification: ∀var. f

**Returns:**
- `NodeId`: BDD representing ∀var. f

### Restriction

```julia
bdd_restrict(mgr::DDManager, f::NodeId, var::Int, value::Bool) -> NodeId
```

Restrict a variable to a specific value (cofactoring).

**Arguments:**
- `f::NodeId`: BDD to restrict
- `var::Int`: Variable to restrict
- `value::Bool`: Value to assign (true or false)

**Returns:**
- `NodeId`: BDD representing f|var=value

### Evaluation

```julia
bdd_eval(mgr::DDManager, f::NodeId, assignment::Dict{Int,Bool}) -> Bool
```

Evaluate a BDD with a specific variable assignment.

**Arguments:**
- `f::NodeId`: BDD to evaluate
- `assignment::Dict{Int,Bool}`: Variable assignments

**Returns:**
- `Bool`: Result of evaluation

**Example:**
```julia
assignment = Dict(1 => true, 2 => false, 3 => true)
result = bdd_eval(mgr, f, assignment)
```

## Algebraic Decision Diagrams (ADDs)

### Variable Creation

```julia
add_ith_var(mgr::DDManager, i::Int) -> NodeId
```

Create an ADD variable (0-1 indicator function).

**Returns:**
- `NodeId`: ADD representing the variable

---

```julia
add_const(mgr::DDManager, value::Float64) -> NodeId
```

Create a constant ADD.

**Arguments:**
- `value::Float64`: Constant value

**Returns:**
- `NodeId`: ADD representing the constant

### Arithmetic Operations

```julia
add_plus(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Addition: f + g

---

```julia
add_minus(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Subtraction: f - g

---

```julia
add_times(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Multiplication: f × g

---

```julia
add_divide(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Division: f ÷ g

### Min/Max Operations

```julia
add_min(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Minimum: min(f, g)

---

```julia
add_max(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Maximum: max(f, g)

### Evaluation

```julia
add_eval(mgr::DDManager, f::NodeId, assignment::Dict{Int,Float64}) -> Float64
```

Evaluate an ADD with a specific variable assignment.

**Arguments:**
- `f::NodeId`: ADD to evaluate
- `assignment::Dict{Int,Float64}`: Variable assignments

**Returns:**
- `Float64`: Result of evaluation

## Zero-suppressed Decision Diagrams (ZDDs)

### Set Creation

```julia
zdd_singleton(mgr::DDManager, element::Int) -> NodeId
```

Create a ZDD representing a singleton set {element}.

**Arguments:**
- `element::Int`: Element in the set

**Returns:**
- `NodeId`: ZDD representing {{element}}

---

```julia
zdd_from_sets(mgr::DDManager, sets::Vector{Vector{Int}}) -> NodeId
```

Create a ZDD from a collection of sets.

**Arguments:**
- `sets::Vector{Vector{Int}}`: Collection of sets

**Returns:**
- `NodeId`: ZDD representing the set family

**Example:**
```julia
sets = [[1, 2], [2, 3], [1, 3]]
family = zdd_from_sets(mgr, sets)
```

---

```julia
zdd_to_sets(mgr::DDManager, f::NodeId) -> Vector{Vector{Int}}
```

Convert a ZDD to a collection of sets.

**Returns:**
- `Vector{Vector{Int}}`: Collection of sets

### Set Operations

```julia
zdd_union(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Union of two set families: F ∪ G

---

```julia
zdd_intersection(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Intersection of two set families: F ∩ G

---

```julia
zdd_difference(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Set difference: F \ G

---

```julia
zdd_product(mgr::DDManager, f::NodeId, g::NodeId) -> NodeId
```

Cartesian product: F × G = {A ∪ B | A ∈ F, B ∈ G}

### Counting

```julia
zdd_count(mgr::DDManager, f::NodeId) -> Int
```

Count the number of sets in a ZDD family.

**Returns:**
- `Int`: Number of sets

## Conversion Functions

```julia
bdd_to_add(mgr::DDManager, f::NodeId) -> NodeId
```

Convert a BDD to an ADD (0-1 function).

---

```julia
add_to_bdd(mgr::DDManager, f::NodeId) -> NodeId
```

Convert an ADD to a BDD (threshold at 0).

---

```julia
bdd_to_zdd(mgr::DDManager, f::NodeId) -> NodeId
```

Convert a BDD to a ZDD.

---

```julia
zdd_to_bdd(mgr::DDManager, f::NodeId) -> NodeId
```

Convert a ZDD to a BDD.

## Utility Functions

### Counting

```julia
count_nodes(mgr::DDManager, f::NodeId) -> Int
```

Count the number of nodes in a decision diagram.

**Returns:**
- `Int`: Number of nodes

---

```julia
count_paths(mgr::DDManager, f::NodeId) -> Int
```

Count the number of paths from root to true terminal.

**Returns:**
- `Int`: Number of paths

---

```julia
count_minterms(mgr::DDManager, f::NodeId, num_vars::Int) -> Float64
```

Count the number of satisfying assignments.

**Arguments:**
- `f::NodeId`: BDD to count
- `num_vars::Int`: Total number of variables

**Returns:**
- `Float64`: Number of minterms

## Types

### NodeId

```julia
struct NodeId
    id::UInt64
end
```

Represents a node in a decision diagram. The LSB encodes complement edge for BDDs.

### DDNode

```julia
struct DDNode
    index::UInt32      # Variable index (0 for terminal)
    then_child::NodeId # High/then child
    else_child::NodeId # Low/else child
    value::Float64     # Terminal value (for ADDs)
end
```

Internal node structure.

### DDManager

```julia
mutable struct DDManager
    nodes::Vector{DDNode}
    unique_tables::Vector{UniqueTable}
    cache::ComputedTable
    zero::NodeId
    one::NodeId
end
```

Manager for decision diagrams.

**Fields:**
- `nodes`: Vector of all nodes
- `unique_tables`: Hash tables for canonical representation
- `cache`: Operation cache
- `zero`: Constant false/empty
- `one`: Constant true/base set

## Performance Notes

- All operations use caching for O(1) repeated operations
- BDD NOT is O(1) using complement edges
- Most operations are zero-allocation for cached results
- Variable ordering significantly affects BDD size

## See Also

- [Getting Started](@ref): Basic usage examples
- [User Guide](@ref): Detailed guides
- [Performance](@ref): Performance characteristics
