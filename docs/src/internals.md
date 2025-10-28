# Internals

This page describes the internal implementation details of AlgebraicDecisionDiagrams.jl.

## Architecture Overview

The implementation follows CUDD's architecture with three main components:

1. **Unique Table**: Hash consing for canonical representation
2. **Computed Table**: Direct-mapped cache for operation memoization
3. **Node Storage**: Compact node representation with complement edges

## Data Structures

### Node Representation

```julia
struct DDNode
    index::UInt32      # Variable index (0 for terminal)
    then_child::NodeId # High/then child
    else_child::NodeId # Low/else child
    value::Float64     # Terminal value (for ADDs)
end
```

**Design decisions:**
- `UInt32` for index: Supports up to 4 billion variables
- `NodeId` for children: Includes complement bit
- `Float64` for value: Used only for ADD terminals
- Total size: ~32 bytes per node

### Node ID with Complement Edges

```julia
struct NodeId
    id::UInt64
end
```

The `id` field encodes both the node index and complement bit:
- **Bits 1-63**: Node index (shifted left by 1)
- **Bit 0 (LSB)**: Complement bit (1 = complemented, 0 = regular)

**Operations:**
```julia
# Extract node index
node_index = node_id.id >> 1

# Check if complemented
is_complemented = (node_id.id & 1) == 1

# Create complemented node
complemented = NodeId(node_id.id ⊕ 1)
```

**Benefits:**
- NOT operation is O(1) (just flip LSB)
- Reduces BDD size by ~2x
- No additional memory overhead

### Unique Table

```julia
struct UniqueTable
    slots::Vector{Vector{NodeId}}
end
```

One unique table per variable level:
- Hash-based lookup for canonical nodes
- Collision resolution via chaining
- Ensures unique representation

**Hash function:**
```julia
function unique_hash(var_index::Int, then_child::NodeId, else_child::NodeId, table_size::Int)
    h = UInt64(var_index) * HASH_P1 + then_child.id * HASH_P2 + else_child.id * HASH_P1
    return Int(((h - 1) % table_size) + 1)
end
```

### Computed Table

```julia
struct CacheEntry
    op::UInt64
    f::NodeId
    g::NodeId
    h::NodeId
    result::NodeId
end

struct ComputedTable
    entries::Vector{CacheEntry}
end
```

Direct-mapped cache:
- Fixed-size cache (default: 1M entries)
- Hash-based indexing
- Stores operation results for memoization

**Hash function:**
```julia
function cache_hash(op::UInt64, f::NodeId, g::NodeId, h::NodeId, cache_size::Int)
    hash_val = op * HASH_P1 + f.id * HASH_P2 + g.id * HASH_P1 + h.id * HASH_P2
    return Int(((hash_val - 1) % cache_size) + 1)
end
```

**Operation codes:**
```julia
const OP_AND = UInt64(1)
const OP_OR = UInt64(2)
const OP_XOR = UInt64(3)
const OP_ITE = UInt64(4)
# ... etc
```

## Core Algorithms

### ITE (If-Then-Else)

The fundamental operation for BDDs:

```julia
function bdd_ite(mgr::DDManager, f::NodeId, g::NodeId, h::NodeId) -> NodeId
    # Terminal cases
    if f == mgr.one
        return g
    end
    if f == mgr.zero
        return h
    end
    if g == h
        return g
    end
    if g == mgr.one && h == mgr.zero
        return f
    end

    # Check cache
    cache_idx = cache_hash(OP_ITE, f, g, h, length(mgr.cache.entries))
    entry = mgr.cache.entries[cache_idx]
    if entry.op == OP_ITE && entry.f == f && entry.g == g && entry.h == h
        return entry.result
    end

    # Find top variable
    top_var = min(get_var(mgr, f), get_var(mgr, g), get_var(mgr, h))

    # Compute cofactors
    f_then, f_else = cofactor(mgr, f, top_var)
    g_then, g_else = cofactor(mgr, g, top_var)
    h_then, h_else = cofactor(mgr, h, top_var)

    # Recursive calls
    then_result = bdd_ite(mgr, f_then, g_then, h_then)
    else_result = bdd_ite(mgr, f_else, g_else, h_else)

    # Reduction rule
    if then_result == else_result
        result = then_result
    else
        result = unique_lookup(mgr, top_var, then_result, else_result)
    end

    # Cache result
    mgr.cache.entries[cache_idx] = CacheEntry(OP_ITE, f, g, h, result)

    return result
end
```

**Key points:**
- Terminal cases for early termination
- Cache lookup before recursion
- Shannon expansion on top variable
- Reduction rule eliminates redundant nodes
- Result cached for future use

### Unique Lookup

Ensures canonical representation:

```julia
function unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId) -> NodeId
    # Reduction rule: if both children same, return child
    if then_child == else_child
        return then_child
    end

    # Complement edge normalization (BDDs only)
    complement = false
    if is_complemented(else_child)
        complement = true
        then_child = NodeId(then_child.id ⊕ 1)
        else_child = NodeId(else_child.id ⊕ 1)
    end

    # Hash lookup
    table = mgr.unique_tables[var_index]
    h = unique_hash(var_index, then_child, else_child, length(table.slots))
    slot = table.slots[h]

    # Check existing nodes
    for node_id in slot
        node_idx = node_id.id >> 1
        node = mgr.nodes[node_idx]
        if node.index == var_index &&
           node.then_child == then_child &&
           node.else_child == else_child
            return complement ? NodeId(node_id.id ⊕ 1) : node_id
        end
    end

    # Create new node
    new_node = DDNode(UInt32(var_index), then_child, else_child, 0.0)
    push!(mgr.nodes, new_node)
    new_id = NodeId(UInt64(length(mgr.nodes)) << 1)
    push!(slot, new_id)

    return complement ? NodeId(new_id.id ⊕ 1) : new_id
end
```

**Key points:**
- Reduction rule eliminates redundant nodes
- Complement edge normalization (else-child regular)
- Hash-based lookup for existing nodes
- Creates new node if not found

### ZDD Reduction Rule

ZDDs use a different reduction rule:

```julia
function zdd_unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId) -> NodeId
    # ZDD reduction: if then-child is empty, return else-child
    if then_child == mgr.zero
        return else_child
    end

    # Standard unique lookup
    # (No complement edge normalization for ZDDs)
    # ...
end
```

**Difference from BDD:**
- BDD: Eliminate if `then_child == else_child`
- ZDD: Eliminate if `then_child == empty`

This makes ZDDs compact for sparse sets.

## Performance Optimizations

### 1. Inline Functions

Critical functions are marked `@inline`:

```julia
@inline function is_complemented(node_id::NodeId)
    return (node_id.id & 1) == 1
end

@inline function get_node_index(node_id::NodeId)
    return node_id.id >> 1
end
```

### 2. Type Stability

All functions are type-stable:

```julia
# Good: Type-stable
function bdd_and(mgr::DDManager, f::NodeId, g::NodeId)::NodeId
    # ...
end

# Bad: Not type-stable (would be slower)
function bdd_and(mgr, f, g)
    # ...
end
```

### 3. Cache Efficiency

Direct-mapped cache for O(1) lookup:
- No collision resolution needed
- Cache line friendly
- Predictable performance

### 4. Complement Edge Optimization

NOT operation is O(1):

```julia
@inline function bdd_not(mgr::DDManager, f::NodeId)::NodeId
    return NodeId(f.id ⊕ 1)  # Just flip LSB
end
```

### 5. Early Termination

Terminal cases checked first:

```julia
function bdd_and(mgr::DDManager, f::NodeId, g::NodeId)::NodeId
    # Terminal cases (fast path)
    if f == mgr.zero || g == mgr.zero
        return mgr.zero
    end
    if f == mgr.one
        return g
    end
    if g == mgr.one
        return f
    end
    if f == g
        return f
    end

    # General case (slower path)
    return bdd_ite(mgr, f, g, mgr.zero)
end
```

## Memory Management

### Reference Counting

Currently uses simple reference counting:

```julia
struct DDNode
    # ...
    ref_count::Int  # Not yet implemented
end
```

**Future work:**
- Implement reference counting
- Garbage collection for unused nodes
- Memory compaction

### Node Allocation

Nodes are allocated in a vector:

```julia
mgr.nodes = Vector{DDNode}()
push!(mgr.nodes, terminal_node)
```

**Benefits:**
- Fast allocation
- Good cache locality
- Simple indexing

**Drawbacks:**
- No deallocation (yet)
- Memory grows monotonically

## Hash Functions

### Prime Numbers

```julia
const HASH_P1 = UInt64(0x9e3779b97f4a7c15)  # Golden ratio
const HASH_P2 = UInt64(0xbf58476d1ce4e5b9)  # Another large prime
```

**Properties:**
- Good distribution
- Minimal collisions
- Fast computation

### Collision Resolution

Unique table uses chaining:

```julia
struct UniqueTable
    slots::Vector{Vector{NodeId}}  # Each slot is a chain
end
```

Computed table uses direct mapping (no collision resolution):

```julia
# Overwrite on collision
mgr.cache.entries[cache_idx] = new_entry
```

## File Organization

```
src/
├── AlgebraicDecisionDiagrams.jl  # Main module
├── types.jl                       # Data structures
├── unique.jl                      # Hash consing
├── cache.jl                       # Operation caching
├── bdd.jl                         # BDD operations
├── add.jl                         # ADD operations
├── zdd.jl                         # ZDD operations
└── utils.jl                       # Utility functions
```

### Module Structure

```julia
module AlgebraicDecisionDiagrams

# Include files in order
include("types.jl")
include("unique.jl")
include("cache.jl")
include("bdd.jl")
include("add.jl")
include("zdd.jl")
include("utils.jl")

# Export public API
export DDManager, NodeId
export ith_var, bdd_and, bdd_or, bdd_xor, bdd_not, bdd_ite
export add_ith_var, add_const, add_plus, add_times, add_min, add_max
export zdd_singleton, zdd_union, zdd_intersection, zdd_product
export count_nodes, count_paths, count_minterms

end
```

## Testing Strategy

### Unit Tests

Each operation has dedicated tests:

```julia
@testset "BDD AND" begin
    mgr = DDManager(3)
    x1 = ith_var(mgr, 1)
    x2 = ith_var(mgr, 2)

    # Test basic AND
    result = bdd_and(mgr, x1, x2)
    @test result != mgr.zero
    @test result != mgr.one

    # Test terminal cases
    @test bdd_and(mgr, x1, mgr.zero) == mgr.zero
    @test bdd_and(mgr, x1, mgr.one) == x1

    # Test commutativity
    @test bdd_and(mgr, x1, x2) == bdd_and(mgr, x2, x1)
end
```

### Property-Based Tests

Test algebraic properties:

```julia
@testset "Boolean Algebra Laws" begin
    mgr = DDManager(3)
    x1, x2, x3 = [ith_var(mgr, i) for i in 1:3]

    # Commutativity
    @test bdd_and(mgr, x1, x2) == bdd_and(mgr, x2, x1)
    @test bdd_or(mgr, x1, x2) == bdd_or(mgr, x2, x1)

    # Associativity
    @test bdd_and(mgr, bdd_and(mgr, x1, x2), x3) ==
          bdd_and(mgr, x1, bdd_and(mgr, x2, x3))

    # De Morgan's laws
    @test bdd_not(mgr, bdd_and(mgr, x1, x2)) ==
          bdd_or(mgr, bdd_not(mgr, x1), bdd_not(mgr, x2))
end
```

## Future Improvements

### 1. Variable Reordering

Implement SIFT algorithm:
- Swap adjacent variables
- Measure BDD size
- Keep best ordering

### 2. Garbage Collection

Implement mark-and-sweep:
- Mark reachable nodes
- Sweep unreachable nodes
- Compact node vector

### 3. Multi-threading

Thread-safe operations:
- Per-thread caches
- Lock-free unique tables
- Parallel apply operations

### 4. Additional Optimizations

- SIMD operations
- Custom allocators
- Profile-guided optimization

## See Also

- [API Reference](@ref): Complete API documentation
- [Performance](@ref): Performance characteristics
- [Comparison with CUDD](comparison.md): Implementation comparison
