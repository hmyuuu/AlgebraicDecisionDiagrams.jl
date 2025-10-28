# ADD (Algebraic Decision Diagram) operations

"""
    add_const(mgr::DDManager, value::Float64)

Create an ADD representing a constant value.
"""
function add_const(mgr::DDManager, value::Float64)
    # Check if this constant already exists
    for i in 1:length(mgr.nodes)
        node = mgr.nodes[i]
        if is_terminal(node) && node.value == value
            return NodeId(i << 1)
        end
    end

    # Create new terminal node
    node = DDNode(value)
    push!(mgr.nodes, node)
    node_idx = length(mgr.nodes)
    mgr.num_nodes += 1

    return NodeId(node_idx << 1)
end

"""
    add_ith_var(mgr::DDManager, i::Int)

Create an ADD for the i-th variable (0-1 valued).
"""
function add_ith_var(mgr::DDManager, i::Int)
    @assert 1 <= i <= mgr.num_vars "Variable index out of range"
    one_const = add_const(mgr, 1.0)
    zero_const = add_const(mgr, 0.0)
    return add_unique_lookup(mgr, i, one_const, zero_const)
end

"""
    add_unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId)

Look up or create a unique ADD node. Similar to BDD unique_lookup but without complement edges.
"""
function add_unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId)
    # Reduction rule
    if then_child == else_child
        return then_child
    end

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
    add_apply(mgr::DDManager, op::Function, f::NodeId, g::NodeId)

Apply a binary operation to two ADDs.

The operation function should take two Float64 values and return a Float64.
Common operations: +, -, *, /, max, min
"""
function add_apply(mgr::DDManager, op::Function, f::NodeId, g::NodeId)
    # Terminal case: both are constants
    f_node = get_node(mgr, f)
    g_node = get_node(mgr, g)

    if is_terminal(f_node) && is_terminal(g_node)
        result_value = op(f_node.value, g_node.value)
        return add_const(mgr, result_value)
    end

    # Generate operation tag
    op_tag = OP_ADD_APPLY + hash(op) % 1000

    # Check cache
    cached = cache_lookup(mgr, op_tag, f, g, UInt64(0))
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = add_node_level(mgr, f)
    g_level = add_node_level(mgr, g)
    top_level = min(f_level, g_level)

    # Compute cofactors
    fv, fnv = add_cofactors(mgr, f, f_level, top_level)
    gv, gnv = add_cofactors(mgr, g, g_level, top_level)

    # Recursive calls
    t = add_apply(mgr, op, fv, gv)
    e = add_apply(mgr, op, fnv, gnv)

    # Build result
    var_index = mgr.invperm[top_level]
    result = add_unique_lookup(mgr, var_index, t, e)

    # Cache result
    cache_insert!(mgr, op_tag, f, g, UInt64(0), result)

    return result
end

"""
    add_node_level(mgr::DDManager, id::NodeId)

Get the level of an ADD node (no complement edges for ADDs).
"""
@inline function add_node_level(mgr::DDManager, id::NodeId)
    node = get_node(mgr, id)
    if is_terminal(node)
        return typemax(Int)
    end
    return mgr.perm[node.index]
end

"""
    add_cofactors(mgr::DDManager, f::NodeId, f_level::Int, top_level::Int)

Compute cofactors for ADD (no complement edge handling).
"""
@inline function add_cofactors(mgr::DDManager, f::NodeId, f_level::Int, top_level::Int)
    if f_level == top_level
        node = get_node(mgr, f)
        return node.then_child, node.else_child
    else
        return f, f
    end
end

"""
    add_plus(mgr::DDManager, f::NodeId, g::NodeId)

Add two ADDs (pointwise addition).
"""
add_plus(mgr::DDManager, f::NodeId, g::NodeId) = add_apply(mgr, +, f, g)

"""
    add_minus(mgr::DDManager, f::NodeId, g::NodeId)

Subtract two ADDs (pointwise subtraction).
"""
add_minus(mgr::DDManager, f::NodeId, g::NodeId) = add_apply(mgr, -, f, g)

"""
    add_times(mgr::DDManager, f::NodeId, g::NodeId)

Multiply two ADDs (pointwise multiplication).
"""
add_times(mgr::DDManager, f::NodeId, g::NodeId) = add_apply(mgr, *, f, g)

"""
    add_divide(mgr::DDManager, f::NodeId, g::NodeId)

Divide two ADDs (pointwise division).
"""
add_divide(mgr::DDManager, f::NodeId, g::NodeId) = add_apply(mgr, /, f, g)

"""
    add_max(mgr::DDManager, f::NodeId, g::NodeId)

Compute maximum of two ADDs (pointwise).
"""
add_max(mgr::DDManager, f::NodeId, g::NodeId) = add_apply(mgr, max, f, g)

"""
    add_min(mgr::DDManager, f::NodeId, g::NodeId)

Compute minimum of two ADDs (pointwise).
"""
add_min(mgr::DDManager, f::NodeId, g::NodeId) = add_apply(mgr, min, f, g)

"""
    add_scalar_multiply(mgr::DDManager, f::NodeId, scalar::Float64)

Multiply an ADD by a scalar constant.
"""
function add_scalar_multiply(mgr::DDManager, f::NodeId, scalar::Float64)
    scalar_node = add_const(mgr, scalar)
    return add_times(mgr, f, scalar_node)
end

"""
    add_negate(mgr::DDManager, f::NodeId)

Negate an ADD (multiply by -1).
"""
function add_negate(mgr::DDManager, f::NodeId)
    return add_scalar_multiply(mgr, f, -1.0)
end

"""
    add_threshold(mgr::DDManager, f::NodeId, threshold::Float64)

Convert ADD to BDD by thresholding: result is 1 where f >= threshold, 0 otherwise.
"""
function add_threshold(mgr::DDManager, f::NodeId, threshold::Float64)
    node = get_node(mgr, f)

    # Terminal case
    if is_terminal(node)
        return node.value >= threshold ? mgr.one : mgr.zero
    end

    # Recursive case
    t = add_threshold(mgr, node.then_child, threshold)
    e = add_threshold(mgr, node.else_child, threshold)

    return unique_lookup(mgr, Int(node.index), t, e)
end

"""
    add_restrict(mgr::DDManager, f::NodeId, var::Int, value::Bool)

Restrict an ADD by setting a variable to a constant value.
"""
function add_restrict(mgr::DDManager, f::NodeId, var::Int, value::Bool)
    node = get_node(mgr, f)

    # Terminal case
    if is_terminal(node)
        return f
    end

    if node.index == var
        # This is the variable we're restricting
        if value
            return node.then_child
        else
            return node.else_child
        end
    elseif mgr.perm[node.index] < mgr.perm[var]
        # Variable is above the restriction variable
        t = add_restrict(mgr, node.then_child, var, value)
        e = add_restrict(mgr, node.else_child, var, value)
        return add_unique_lookup(mgr, Int(node.index), t, e)
    else
        # Variable is below the restriction variable
        return f
    end
end

"""
    add_eval(mgr::DDManager, f::NodeId, assignment::Dict{Int,Bool})

Evaluate an ADD given a complete variable assignment.
Returns the terminal value.
"""
function add_eval(mgr::DDManager, f::NodeId, assignment::Dict{Int,Bool})
    node = get_node(mgr, f)

    while !is_terminal(node)
        if get(assignment, node.index, false)
            f = node.then_child
        else
            f = node.else_child
        end
        node = get_node(mgr, f)
    end

    return node.value
end

"""
    add_find_max(mgr::DDManager, f::NodeId)

Find the maximum terminal value in an ADD.
"""
function add_find_max(mgr::DDManager, f::NodeId)
    node = get_node(mgr, f)

    if is_terminal(node)
        return node.value
    end

    max_then = add_find_max(mgr, node.then_child)
    max_else = add_find_max(mgr, node.else_child)

    return max(max_then, max_else)
end

"""
    add_find_min(mgr::DDManager, f::NodeId)

Find the minimum terminal value in an ADD.
"""
function add_find_min(mgr::DDManager, f::NodeId)
    node = get_node(mgr, f)

    if is_terminal(node)
        return node.value
    end

    min_then = add_find_min(mgr, node.then_child)
    min_else = add_find_min(mgr, node.else_child)

    return min(min_then, min_else)
end
