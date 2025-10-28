# ZDD (Zero-suppressed Decision Diagram) operations

"""
    zdd_empty(mgr::DDManager)

Return the empty set (ZDD zero terminal).
In ZDDs, this represents the empty family of sets.
"""
zdd_empty(mgr::DDManager) = mgr.zero

"""
    zdd_base(mgr::DDManager)

Return the base set (ZDD one terminal).
In ZDDs, this represents the family containing only the empty set {∅}.
"""
zdd_base(mgr::DDManager) = mgr.one

"""
    zdd_unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId)

Look up or create a unique ZDD node with the given variable and children.
Implements ZDD reduction rules:
1. If then_child == 0 (empty), return else_child (zero-suppression)
2. Otherwise, create node normally
"""
function zdd_unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId)
    # ZDD reduction rule: if then-child is empty, return else-child
    # This is the key difference from BDDs!
    if then_child == mgr.zero
        return else_child
    end

    # Otherwise use standard unique lookup
    level = mgr.perm[var_index]
    table = mgr.unique_tables[level]

    # Compute hash
    h = hash_node(then_child, else_child, table.shift)
    slot_idx = Int(((h - 1) % length(table.slots)) + 1)

    # Search collision chain
    node_idx = table.slots[slot_idx]
    while node_idx != 0
        node = mgr.nodes[node_idx]
        if node.index == var_index &&
           node.then_child == then_child &&
           node.else_child == else_child
            return NodeId(node_idx << 1)
        end
        node_idx = node.next
    end

    # Create new node
    return create_node!(mgr, var_index, then_child, else_child, table, slot_idx)
end

"""
    zdd_singleton(mgr::DDManager, var::Int)

Create a ZDD representing the set containing only the singleton {var}.
"""
function zdd_singleton(mgr::DDManager, var::Int)
    @assert 1 <= var <= mgr.num_vars "Variable index out of range"
    return zdd_unique_lookup(mgr, var, mgr.one, mgr.zero)
end

"""
    zdd_union(mgr::DDManager, f::NodeId, g::NodeId)

Compute the union of two ZDD sets: f ∪ g
"""
function zdd_union(mgr::DDManager, f::NodeId, g::NodeId)
    # Terminal cases
    if f == mgr.zero
        return g
    end
    if g == mgr.zero
        return f
    end
    if f == g
        return f
    end

    # Normalize: ensure f <= g for commutativity
    if f > g
        f, g = g, f
    end

    # Check cache
    cached = cache_lookup(mgr, OP_ZDD_UNION, f, g, UInt64(0))
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = node_level(mgr, f)
    g_level = node_level(mgr, g)

    if f_level < g_level
        # f has higher priority variable
        node_f = get_node(mgr, f)
        t = zdd_union(mgr, node_f.then_child, g)
        e = node_f.else_child
        result = zdd_unique_lookup(mgr, Int(node_f.index), t, e)
    elseif f_level > g_level
        # g has higher priority variable
        node_g = get_node(mgr, g)
        t = zdd_union(mgr, f, node_g.then_child)
        e = node_g.else_child
        result = zdd_unique_lookup(mgr, Int(node_g.index), t, e)
    else
        # Same variable
        node_f = get_node(mgr, f)
        node_g = get_node(mgr, g)
        t = zdd_union(mgr, node_f.then_child, node_g.then_child)
        e = zdd_union(mgr, node_f.else_child, node_g.else_child)
        result = zdd_unique_lookup(mgr, Int(node_f.index), t, e)
    end

    # Cache result
    cache_insert!(mgr, OP_ZDD_UNION, f, g, UInt64(0), result)
    return result
end

"""
    zdd_intersection(mgr::DDManager, f::NodeId, g::NodeId)

Compute the intersection of two ZDD sets: f ∩ g
"""
function zdd_intersection(mgr::DDManager, f::NodeId, g::NodeId)
    # Terminal cases
    if f == mgr.zero || g == mgr.zero
        return mgr.zero
    end
    if f == g
        return f
    end

    # Normalize
    if f > g
        f, g = g, f
    end

    # Check cache
    cached = cache_lookup(mgr, OP_ZDD_INTERSECT, f, g, UInt64(0))
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = node_level(mgr, f)
    g_level = node_level(mgr, g)

    if f_level < g_level
        # f has higher priority variable
        node_f = get_node(mgr, f)
        t = zdd_intersection(mgr, node_f.then_child, g)
        e = zdd_intersection(mgr, node_f.else_child, g)
        result = zdd_unique_lookup(mgr, Int(node_f.index), t, e)
    elseif f_level > g_level
        # g has higher priority variable
        node_g = get_node(mgr, g)
        t = zdd_intersection(mgr, f, node_g.then_child)
        e = zdd_intersection(mgr, f, node_g.else_child)
        result = zdd_unique_lookup(mgr, Int(node_g.index), t, e)
    else
        # Same variable
        node_f = get_node(mgr, f)
        node_g = get_node(mgr, g)
        t = zdd_intersection(mgr, node_f.then_child, node_g.then_child)
        e = zdd_intersection(mgr, node_f.else_child, node_g.else_child)
        result = zdd_unique_lookup(mgr, Int(node_f.index), t, e)
    end

    # Cache result
    cache_insert!(mgr, OP_ZDD_INTERSECT, f, g, UInt64(0), result)
    return result
end

"""
    zdd_difference(mgr::DDManager, f::NodeId, g::NodeId)

Compute the set difference: f \\ g (elements in f but not in g)
"""
function zdd_difference(mgr::DDManager, f::NodeId, g::NodeId)
    # Terminal cases
    if f == mgr.zero
        return mgr.zero
    end
    if g == mgr.zero
        return f
    end
    if f == g
        return mgr.zero
    end

    # Check cache
    cached = cache_lookup(mgr, OP_ZDD_DIFF, f, g, UInt64(0))
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = node_level(mgr, f)
    g_level = node_level(mgr, g)

    if f_level < g_level
        # f has higher priority variable
        node_f = get_node(mgr, f)
        t = zdd_difference(mgr, node_f.then_child, g)
        e = zdd_difference(mgr, node_f.else_child, g)
        result = zdd_unique_lookup(mgr, Int(node_f.index), t, e)
    elseif f_level > g_level
        # g has higher priority variable
        node_g = get_node(mgr, g)
        t = zdd_difference(mgr, f, node_g.then_child)
        e = zdd_difference(mgr, f, node_g.else_child)
        result = zdd_unique_lookup(mgr, Int(node_g.index), t, e)
    else
        # Same variable
        node_f = get_node(mgr, f)
        node_g = get_node(mgr, g)
        t = zdd_difference(mgr, node_f.then_child, node_g.then_child)
        e = zdd_difference(mgr, node_f.else_child, node_g.else_child)
        result = zdd_unique_lookup(mgr, Int(node_f.index), t, e)
    end

    # Cache result
    cache_insert!(mgr, OP_ZDD_DIFF, f, g, UInt64(0), result)
    return result
end

"""
    zdd_subset1(mgr::DDManager, f::NodeId, var::Int)

Return the subset of f where var is present (positive cofactor).
"""
function zdd_subset1(mgr::DDManager, f::NodeId, var::Int)
    if f == mgr.zero || f == mgr.one
        return mgr.zero
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return mgr.zero
    end

    if node.index == var
        return node.then_child
    elseif mgr.perm[node.index] < mgr.perm[var]
        t = zdd_subset1(mgr, node.then_child, var)
        e = zdd_subset1(mgr, node.else_child, var)
        return zdd_unique_lookup(mgr, Int(node.index), t, e)
    else
        return mgr.zero
    end
end

"""
    zdd_subset0(mgr::DDManager, f::NodeId, var::Int)

Return the subset of f where var is absent (negative cofactor).
"""
function zdd_subset0(mgr::DDManager, f::NodeId, var::Int)
    if f == mgr.zero || f == mgr.one
        return f
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return f
    end

    if node.index == var
        return node.else_child
    elseif mgr.perm[node.index] < mgr.perm[var]
        t = zdd_subset0(mgr, node.then_child, var)
        e = zdd_subset0(mgr, node.else_child, var)
        return zdd_unique_lookup(mgr, Int(node.index), t, e)
    else
        return f
    end
end

"""
    zdd_change(mgr::DDManager, f::NodeId, var::Int)

Change operation: add var to sets not containing it, remove from sets containing it.
"""
function zdd_change(mgr::DDManager, f::NodeId, var::Int)
    if f == mgr.zero
        return mgr.zero
    end
    if f == mgr.one
        return zdd_singleton(mgr, var)
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return zdd_singleton(mgr, var)
    end

    if node.index == var
        # Swap then and else children
        return zdd_unique_lookup(mgr, var, node.else_child, node.then_child)
    elseif mgr.perm[node.index] < mgr.perm[var]
        t = zdd_change(mgr, node.then_child, var)
        e = zdd_change(mgr, node.else_child, var)
        return zdd_unique_lookup(mgr, Int(node.index), t, e)
    else
        # var is above this node
        return zdd_unique_lookup(mgr, var, f, mgr.zero)
    end
end

"""
    zdd_count(mgr::DDManager, f::NodeId)

Count the number of sets (combinations) represented by the ZDD.
"""
function zdd_count(mgr::DDManager, f::NodeId)
    cache = Dict{NodeId, BigInt}()
    return zdd_count_rec(mgr, f, cache)
end

function zdd_count_rec(mgr::DDManager, f::NodeId, cache::Dict{NodeId, BigInt})
    if haskey(cache, f)
        return cache[f]
    end

    if f == mgr.zero
        return BigInt(0)
    end
    if f == mgr.one
        return BigInt(1)
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return BigInt(0)
    end

    count_t = zdd_count_rec(mgr, node.then_child, cache)
    count_e = zdd_count_rec(mgr, node.else_child, cache)

    result = count_t + count_e
    cache[f] = result
    return result
end

"""
    zdd_from_sets(mgr::DDManager, sets::Vector{Vector{Int}})

Create a ZDD from a collection of sets.
Each set is represented as a vector of variable indices.
"""
function zdd_from_sets(mgr::DDManager, sets::Vector{Vector{Int}})
    result = mgr.zero

    for set in sets
        # Create ZDD for this single set
        set_zdd = mgr.one
        for var in sort(set, rev=true)  # Process in reverse order
            set_zdd = zdd_unique_lookup(mgr, var, set_zdd, mgr.zero)
        end

        # Union with result
        result = zdd_union(mgr, result, set_zdd)
    end

    return result
end

"""
    zdd_to_sets(mgr::DDManager, f::NodeId)

Extract all sets represented by a ZDD.
Returns a vector of sets, where each set is a vector of variable indices.
"""
function zdd_to_sets(mgr::DDManager, f::NodeId)
    sets = Vector{Vector{Int}}()
    current_set = Int[]
    zdd_to_sets_rec(mgr, f, current_set, sets)
    return sets
end

function zdd_to_sets_rec(mgr::DDManager, f::NodeId, current_set::Vector{Int},
                         sets::Vector{Vector{Int}})
    if f == mgr.zero
        return
    end

    if f == mgr.one
        push!(sets, copy(current_set))
        return
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return
    end

    # Explore else-child (variable not in set)
    zdd_to_sets_rec(mgr, node.else_child, current_set, sets)

    # Explore then-child (variable in set)
    push!(current_set, node.index)
    zdd_to_sets_rec(mgr, node.then_child, current_set, sets)
    pop!(current_set)
end
