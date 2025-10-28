# BDD operations

"""
    ith_var(mgr::DDManager, i::Int)

Create a BDD for the i-th variable (projection function).
"""
function ith_var(mgr::DDManager, i::Int)
    @assert 1 <= i <= mgr.num_vars "Variable index out of range"
    return unique_lookup(mgr, i, mgr.one, mgr.zero)
end

"""
    bdd_ite(mgr::DDManager, f::NodeId, g::NodeId, h::NodeId)

Compute If-Then-Else: ITE(f, g, h) = (f ∧ g) ∨ (¬f ∧ h)

This is the fundamental BDD operation. All other operations can be
expressed in terms of ITE:
- AND(f, g) = ITE(f, g, 0)
- OR(f, g) = ITE(f, 1, g)
- XOR(f, g) = ITE(f, ¬g, g)
- NOT(f) = ITE(f, 0, 1)
"""
function bdd_ite(mgr::DDManager, f::NodeId, g::NodeId, h::NodeId)
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
    if g == mgr.zero && h == mgr.one
        return complement(f)
    end
    if f == g
        return bdd_or(mgr, f, h)
    end
    if f == h
        return bdd_and(mgr, f, g)
    end

    # Normalize: ensure canonical form
    # If f is complemented, swap g and h and complement f
    if is_complemented(f)
        f = complement(f)
        g, h = h, g
    end

    # Check cache
    cached = cache_lookup(mgr, OP_ITE, f, g, h)
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = node_level(mgr, f)
    g_level = node_level(mgr, g)
    h_level = node_level(mgr, h)
    top_level = min(f_level, g_level, h_level)

    # Compute cofactors
    fv, fnv = cofactors(mgr, f, f_level, top_level)
    gv, gnv = cofactors(mgr, g, g_level, top_level)
    hv, hnv = cofactors(mgr, h, h_level, top_level)

    # Recursive calls
    t = bdd_ite(mgr, fv, gv, hv)
    e = bdd_ite(mgr, fnv, gnv, hnv)

    # Build result
    var_index = mgr.invperm[top_level]
    result = unique_lookup(mgr, var_index, t, e)

    # Cache result
    cache_insert!(mgr, OP_ITE, f, g, h, result)

    return result
end

"""
    cofactors(mgr::DDManager, f::NodeId, f_level::Int, top_level::Int)

Compute positive and negative cofactors of f with respect to the top variable.
"""
@inline function cofactors(mgr::DDManager, f::NodeId, f_level::Int, top_level::Int)
    if f_level == top_level
        return then_child(mgr, f), else_child(mgr, f)
    else
        return f, f
    end
end

"""
    bdd_and(mgr::DDManager, f::NodeId, g::NodeId)

Compute the conjunction (AND) of two BDDs.
"""
function bdd_and(mgr::DDManager, f::NodeId, g::NodeId)
    # Terminal cases
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
    if f == complement(g)
        return mgr.zero
    end

    # Normalize: ensure f <= g for commutativity
    if f > g
        f, g = g, f
    end

    # Check cache
    cached = cache_lookup(mgr, OP_AND, f, g, UInt64(0))
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = node_level(mgr, f)
    g_level = node_level(mgr, g)
    top_level = min(f_level, g_level)

    # Compute cofactors
    fv, fnv = cofactors(mgr, f, f_level, top_level)
    gv, gnv = cofactors(mgr, g, g_level, top_level)

    # Recursive calls
    t = bdd_and(mgr, fv, gv)
    e = bdd_and(mgr, fnv, gnv)

    # Build result
    var_index = mgr.invperm[top_level]
    result = unique_lookup(mgr, var_index, t, e)

    # Cache result
    cache_insert!(mgr, OP_AND, f, g, UInt64(0), result)

    return result
end

"""
    bdd_or(mgr::DDManager, f::NodeId, g::NodeId)

Compute the disjunction (OR) of two BDDs.
"""
function bdd_or(mgr::DDManager, f::NodeId, g::NodeId)
    # Terminal cases
    if f == mgr.one || g == mgr.one
        return mgr.one
    end
    if f == mgr.zero
        return g
    end
    if g == mgr.zero
        return f
    end
    if f == g
        return f
    end
    if f == complement(g)
        return mgr.one
    end

    # Normalize
    if f > g
        f, g = g, f
    end

    # Check cache
    cached = cache_lookup(mgr, OP_OR, f, g, UInt64(0))
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = node_level(mgr, f)
    g_level = node_level(mgr, g)
    top_level = min(f_level, g_level)

    # Compute cofactors
    fv, fnv = cofactors(mgr, f, f_level, top_level)
    gv, gnv = cofactors(mgr, g, g_level, top_level)

    # Recursive calls
    t = bdd_or(mgr, fv, gv)
    e = bdd_or(mgr, fnv, gnv)

    # Build result
    var_index = mgr.invperm[top_level]
    result = unique_lookup(mgr, var_index, t, e)

    # Cache result
    cache_insert!(mgr, OP_OR, f, g, UInt64(0), result)

    return result
end

"""
    bdd_xor(mgr::DDManager, f::NodeId, g::NodeId)

Compute the exclusive-or (XOR) of two BDDs.
"""
function bdd_xor(mgr::DDManager, f::NodeId, g::NodeId)
    # Terminal cases
    if f == mgr.zero
        return g
    end
    if g == mgr.zero
        return f
    end
    if f == g
        return mgr.zero
    end
    if f == complement(g)
        return mgr.one
    end

    # Normalize
    if f > g
        f, g = g, f
    end

    # Check cache
    cached = cache_lookup(mgr, OP_XOR, f, g, UInt64(0))
    if cached != INVALID_NODE
        return cached
    end

    # Find top variable
    f_level = node_level(mgr, f)
    g_level = node_level(mgr, g)
    top_level = min(f_level, g_level)

    # Compute cofactors
    fv, fnv = cofactors(mgr, f, f_level, top_level)
    gv, gnv = cofactors(mgr, g, g_level, top_level)

    # Recursive calls
    t = bdd_xor(mgr, fv, gv)
    e = bdd_xor(mgr, fnv, gnv)

    # Build result
    var_index = mgr.invperm[top_level]
    result = unique_lookup(mgr, var_index, t, e)

    # Cache result
    cache_insert!(mgr, OP_XOR, f, g, UInt64(0), result)

    return result
end

"""
    bdd_not(mgr::DDManager, f::NodeId)

Compute the negation (NOT) of a BDD.
For BDDs with complement edges, this is just a pointer complement.
"""
@inline bdd_not(mgr::DDManager, f::NodeId) = complement(f)

"""
    bdd_restrict(mgr::DDManager, f::NodeId, var::Int, value::Bool)

Restrict a BDD by setting a variable to a constant value.
This is also known as the cofactor operation.
"""
function bdd_restrict(mgr::DDManager, f::NodeId, var::Int, value::Bool)
    # Terminal case
    if f == mgr.zero || f == mgr.one
        return f
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return f
    end

    if node.index == var
        # This is the variable we're restricting
        if value
            return then_child(mgr, f)
        else
            return else_child(mgr, f)
        end
    elseif mgr.perm[node.index] < mgr.perm[var]
        # Variable is above the restriction variable
        t = bdd_restrict(mgr, then_child(mgr, f), var, value)
        e = bdd_restrict(mgr, else_child(mgr, f), var, value)
        return unique_lookup(mgr, Int(node.index), t, e)
    else
        # Variable is below the restriction variable
        return f
    end
end

"""
    bdd_exists(mgr::DDManager, f::NodeId, vars::Vector{Int})

Existential quantification: ∃vars. f = f[vars=0] ∨ f[vars=1]
"""
function bdd_exists(mgr::DDManager, f::NodeId, vars::Vector{Int})
    if isempty(vars)
        return f
    end

    # Quantify out one variable at a time
    result = f
    for var in vars
        result = bdd_or(mgr,
                       bdd_restrict(mgr, result, var, false),
                       bdd_restrict(mgr, result, var, true))
    end
    return result
end

"""
    bdd_forall(mgr::DDManager, f::NodeId, vars::Vector{Int})

Universal quantification: ∀vars. f = f[vars=0] ∧ f[vars=1]
"""
function bdd_forall(mgr::DDManager, f::NodeId, vars::Vector{Int})
    if isempty(vars)
        return f
    end

    # Quantify out one variable at a time
    result = f
    for var in vars
        result = bdd_and(mgr,
                        bdd_restrict(mgr, result, var, false),
                        bdd_restrict(mgr, result, var, true))
    end
    return result
end
