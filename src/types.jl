# Core data structures for BDDs and ADDs

"""
    NodeId

A node identifier that encodes both the node reference and complement bit.
The LSB is used for complement edges (BDD only).
"""
const NodeId = UInt64

# Bit manipulation for complement edges
@inline is_complemented(id::NodeId) = (id & 0x01) != 0
@inline regular(id::NodeId) = id & ~UInt64(0x01)
@inline complement(id::NodeId) = id ⊻ UInt64(0x01)

# Special node IDs
const INVALID_NODE = typemax(NodeId)
const ZERO_NODE = UInt64(0)
const ONE_NODE = UInt64(2)  # Regular pointer to terminal 1

"""
    DDNode

Internal representation of a decision diagram node.
For terminal nodes, stores a value. For internal nodes, stores children.
"""
mutable struct DDNode
    index::UInt32           # Variable index (MAXUINT32 for terminals)
    ref::UInt32             # Reference count
    then_child::NodeId      # High/Then child
    else_child::NodeId      # Low/Else child
    value::Float64          # Terminal value (for ADDs)
    next::UInt64            # Next node in unique table collision chain (node index)
end

# Constructor for internal nodes
DDNode(index::Integer, then_child::NodeId, else_child::NodeId) =
    DDNode(UInt32(index), UInt32(0), then_child, else_child, 0.0, 0)

# Constructor for terminal nodes
DDNode(value::Float64) =
    DDNode(typemax(UInt32), UInt32(0), INVALID_NODE, INVALID_NODE, value, 0)

@inline is_terminal(node::DDNode) = node.index == typemax(UInt32)

"""
    UniqueTable

Hash table for ensuring node uniqueness (hash consing).
One subtable per variable level.
"""
mutable struct UniqueTable
    slots::Vector{UInt64}   # Hash buckets (stores node indices, 0 = empty)
    shift::Int              # Shift amount for hash function
    keys::Int               # Number of nodes at this level
    dead::Int               # Number of dead nodes
end

function UniqueTable(initial_size::Int = 256)
    shift = 64 - trailing_zeros(initial_size)
    UniqueTable(zeros(UInt64, initial_size), shift, 0, 0)
end

"""
    CacheEntry

Entry in the computed table for caching operation results.
"""
struct CacheEntry
    f::NodeId
    g::NodeId
    h::UInt64      # Third operand or operation tag
    result::NodeId
end

CacheEntry() = CacheEntry(INVALID_NODE, INVALID_NODE, 0, INVALID_NODE)

"""
    ComputedTable

Cache for memoizing operation results.
"""
mutable struct ComputedTable
    entries::Vector{CacheEntry}
    shift::Int
end

function ComputedTable(size::Int = 262144)
    shift = 64 - trailing_zeros(size)
    ComputedTable([CacheEntry() for _ in 1:size], shift)
end

"""
    DDManager

Main manager for decision diagrams. Handles node allocation,
unique table, computed table, and variable ordering.
"""
mutable struct DDManager
    # Node storage
    nodes::Vector{DDNode}
    free_list::Vector{UInt64}  # Indices of free nodes

    # Unique table (one per variable level)
    unique_tables::Vector{UniqueTable}

    # Computed table (shared cache)
    cache::ComputedTable

    # Variable ordering
    num_vars::Int
    perm::Vector{Int}      # index -> level
    invperm::Vector{Int}   # level -> index
    vars::Vector{NodeId}   # Variable projection functions

    # Constants
    zero::NodeId
    one::NodeId

    # Statistics
    num_nodes::Int
    num_dead::Int

    # GC parameters
    gc_frac::Float64       # Trigger GC when dead/total > gc_frac
    max_cache_size::Int
end

"""
    DDManager(num_vars::Int)

Create a new decision diagram manager with the specified number of variables.
"""
function DDManager(num_vars::Int; cache_size::Int = 262144)
    # Initialize node storage with terminal node
    # In BDDs with complement edges, we only need one terminal (1)
    # Zero is represented as the complement of one
    nodes = DDNode[]
    push!(nodes, DDNode(1.0))  # Index 1: terminal 1

    # zero = complemented pointer to terminal 1 (index 1, shifted left, with complement bit)
    # one = regular pointer to terminal 1 (index 1, shifted left, no complement bit)
    zero = NodeId((1 << 1) | 1)  # Complemented pointer to node 1
    one = NodeId(1 << 1)          # Regular pointer to node 1

    # Initialize unique tables (one per variable)
    unique_tables = [UniqueTable() for _ in 1:num_vars]

    # Initialize cache
    cache = ComputedTable(cache_size)

    # Initialize variable ordering (identity)
    perm = collect(1:num_vars)
    invperm = collect(1:num_vars)

    # Create variable projection functions
    vars = NodeId[]

    manager = DDManager(
        nodes,
        UInt64[],
        unique_tables,
        cache,
        num_vars,
        perm,
        invperm,
        vars,
        zero,
        one,
        1,  # One terminal node
        0,
        0.2,
        cache_size
    )

    # Create projection functions for each variable
    for i in 1:num_vars
        push!(manager.vars, ith_var(manager, i))
    end

    return manager
end
