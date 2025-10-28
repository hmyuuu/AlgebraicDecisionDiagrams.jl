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

```@docs
ith_var
```

### Boolean Operations

```@docs
bdd_and
bdd_or
bdd_xor
bdd_not
bdd_ite
```

### Quantification

```@docs
bdd_exists
bdd_forall
```

### Restriction

```@docs
bdd_restrict
```

## Algebraic Decision Diagrams (ADDs)

### Variable Creation

```@docs
add_ith_var
add_const
```

### Arithmetic Operations

```@docs
add_plus
add_minus
add_times
add_divide
add_negate
add_scalar_multiply
```

### Min/Max Operations

```@docs
add_min
add_max
add_threshold
add_find_min
add_find_max
```

### Restriction

```@docs
add_restrict
```

### Evaluation

```@docs
add_eval
```

## Zero-suppressed Decision Diagrams (ZDDs)

### Set Creation

```@docs
zdd_singleton
zdd_from_sets
zdd_to_sets
zdd_empty
zdd_base
```

### Set Operations

```@docs
zdd_union
zdd_intersection
zdd_difference
```

### ZDD-Specific Operations

```@docs
zdd_subset0
zdd_subset1
zdd_change
```

### Counting

```@docs
zdd_count
```

## Utility Functions

### Counting

```@docs
count_nodes
count_paths
count_minterms
```

### Visualization and Debugging

```@docs
print_dd
to_dot
```

### Memory Management

```@docs
garbage_collect!
check_gc
```

## Types

```@docs
NodeId
```

## Performance Notes

- All operations use caching for O(1) repeated operations
- BDD NOT is O(1) using complement edges
- Most operations are zero-allocation for cached results
- Variable ordering significantly affects BDD size

## See Also

- [Getting Started](@ref): Basic usage examples
- [BDD Guide](guide/bdds.md): Binary Decision Diagrams
- [ADD Guide](guide/adds.md): Algebraic Decision Diagrams
- [ZDD Guide](guide/zdds.md): Zero-suppressed Decision Diagrams
- [Performance](@ref): Performance characteristics
