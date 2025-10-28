# Utility functions for BDDs and ADDs

"""
    count_nodes(mgr::DDManager, f::NodeId)

Count the number of nodes in a BDD/ADD (excluding terminals).
"""
function count_nodes(mgr::DDManager, f::NodeId)
    visited = Set{NodeId}()
    return count_nodes_rec(mgr, f, visited)
end

function count_nodes_rec(mgr::DDManager, f::NodeId, visited::Set{NodeId})
    f_reg = regular(f)

    if f_reg in visited
        return 0
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return 0
    end

    push!(visited, f_reg)
    count = 1

    count += count_nodes_rec(mgr, node.then_child, visited)
    count += count_nodes_rec(mgr, node.else_child, visited)

    return count
end

"""
    count_paths(mgr::DDManager, f::NodeId)

Count the number of paths from root to 1-terminal (for BDDs).
"""
function count_paths(mgr::DDManager, f::NodeId)
    if f == mgr.zero
        return 0
    end
    if f == mgr.one
        return 1
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return node.value != 0.0 ? 1 : 0
    end

    # Handle complement edge
    t = then_child(mgr, f)
    e = else_child(mgr, f)

    return count_paths(mgr, t) + count_paths(mgr, e)
end

"""
    count_minterms(mgr::DDManager, f::NodeId, nvars::Int)

Count the number of satisfying assignments (minterms) for a BDD.
"""
function count_minterms(mgr::DDManager, f::NodeId, nvars::Int)
    cache = Dict{NodeId, Float64}()
    return count_minterms_rec(mgr, f, nvars, cache)
end

function count_minterms_rec(mgr::DDManager, f::NodeId, nvars::Int, cache::Dict{NodeId, Float64})
    if haskey(cache, f)
        return cache[f]
    end

    if f == mgr.zero
        return 0.0
    end
    if f == mgr.one
        return 2.0^nvars
    end

    node = get_node(mgr, f)
    if is_terminal(node)
        return node.value != 0.0 ? 2.0^nvars : 0.0
    end

    level = mgr.perm[node.index]
    vars_below = nvars - level

    t = then_child(mgr, f)
    e = else_child(mgr, f)

    count_t = count_minterms_rec(mgr, t, vars_below - 1, cache)
    count_e = count_minterms_rec(mgr, e, vars_below - 1, cache)

    result = count_t + count_e
    cache[f] = result

    return result
end

"""
    print_dd(mgr::DDManager, f::NodeId; max_depth::Int=10)

Print a textual representation of a decision diagram.
"""
function print_dd(mgr::DDManager, f::NodeId; max_depth::Int=10)
    visited = Set{NodeId}()
    print_dd_rec(mgr, f, 0, max_depth, visited)
end

function print_dd_rec(mgr::DDManager, f::NodeId, depth::Int, max_depth::Int, visited::Set{NodeId})
    indent = "  " ^ depth

    if depth > max_depth
        println(indent, "...")
        return
    end

    f_reg = regular(f)
    is_comp = is_complemented(f)

    if f == mgr.zero
        println(indent, "0")
        return
    end
    if f == mgr.one
        println(indent, "1")
        return
    end

    node = get_node(mgr, f)

    if is_terminal(node)
        val = is_comp ? -node.value : node.value
        println(indent, "Terminal: ", val)
        return
    end

    if f_reg in visited
        println(indent, "Node x", node.index, is_comp ? " (complemented)" : "", " [already shown]")
        return
    end

    push!(visited, f_reg)

    println(indent, "Node x", node.index, is_comp ? " (complemented)" : "")
    println(indent, "  Then:")
    print_dd_rec(mgr, then_child(mgr, f), depth + 2, max_depth, visited)
    println(indent, "  Else:")
    print_dd_rec(mgr, else_child(mgr, f), depth + 2, max_depth, visited)
end

"""
    to_dot(mgr::DDManager, f::NodeId, filename::String)

Export a decision diagram to DOT format for visualization with Graphviz.
"""
function to_dot(mgr::DDManager, f::NodeId, filename::String)
    open(filename, "w") do io
        println(io, "digraph DD {")
        println(io, "  rankdir=TB;")
        println(io, "  node [shape=circle];")

        visited = Set{NodeId}()
        node_ids = Dict{NodeId, Int}()
        next_id = [1]

        # Write nodes
        to_dot_nodes(mgr, f, io, visited, node_ids, next_id)

        # Write edges
        visited = Set{NodeId}()
        to_dot_edges(mgr, f, io, visited, node_ids)

        println(io, "}")
    end
end

function to_dot_nodes(mgr::DDManager, f::NodeId, io::IO, visited::Set{NodeId},
                      node_ids::Dict{NodeId, Int}, next_id::Vector{Int})
    f_reg = regular(f)

    if f_reg in visited
        return
    end

    push!(visited, f_reg)
    node_ids[f_reg] = next_id[1]
    next_id[1] += 1

    node = get_node(mgr, f)

    if is_terminal(node)
        println(io, "  node", node_ids[f_reg], " [label=\"", node.value, "\", shape=box];")
        return
    end

    println(io, "  node", node_ids[f_reg], " [label=\"x", node.index, "\"];")

    to_dot_nodes(mgr, node.then_child, io, visited, node_ids, next_id)
    to_dot_nodes(mgr, node.else_child, io, visited, node_ids, next_id)
end

function to_dot_edges(mgr::DDManager, f::NodeId, io::IO, visited::Set{NodeId},
                      node_ids::Dict{NodeId, Int})
    f_reg = regular(f)

    if f_reg in visited
        return
    end

    push!(visited, f_reg)

    node = get_node(mgr, f)

    if is_terminal(node)
        return
    end

    t = node.then_child
    e = node.else_child

    t_reg = regular(t)
    e_reg = regular(e)

    # Then edge (solid)
    style = is_complemented(t) ? ", style=dashed" : ""
    println(io, "  node", node_ids[f_reg], " -> node", node_ids[t_reg],
            " [label=\"1\"", style, "];")

    # Else edge (dashed)
    style = is_complemented(e) ? ", style=dotted" : ", style=dashed"
    println(io, "  node", node_ids[f_reg], " -> node", node_ids[e_reg],
            " [label=\"0\"", style, "];")

    to_dot_edges(mgr, t, io, visited, node_ids)
    to_dot_edges(mgr, e, io, visited, node_ids)
end

"""
    garbage_collect!(mgr::DDManager)

Perform garbage collection to reclaim dead nodes.
"""
function garbage_collect!(mgr::DDManager)
    # Mark phase: mark all reachable nodes
    marked = Set{UInt64}()

    # Mark from all nodes with positive reference count
    for (idx, node) in enumerate(mgr.nodes)
        if node.ref > 0
            mark_reachable!(mgr, NodeId(idx << 1), marked)
        end
    end

    # Sweep phase: collect unmarked nodes
    for level in 1:mgr.num_vars
        table = mgr.unique_tables[level]
        for slot_idx in 1:length(table.slots)
            prev_idx = UInt64(0)
            node_idx = table.slots[slot_idx]

            while node_idx != 0
                node = mgr.nodes[node_idx]
                next_idx = node.next

                if node_idx ∉ marked && node.ref == 0
                    # Remove from chain
                    if prev_idx == 0
                        table.slots[slot_idx] = next_idx
                    else
                        mgr.nodes[prev_idx].next = next_idx
                    end

                    # Add to free list
                    push!(mgr.free_list, node_idx)
                    table.keys -= 1
                    table.dead -= 1
                    mgr.num_nodes -= 1
                    mgr.num_dead -= 1
                else
                    prev_idx = node_idx
                end

                node_idx = next_idx
            end
        end
    end

    # Clear cache after GC
    clear_cache!(mgr)
end

function mark_reachable!(mgr::DDManager, f::NodeId, marked::Set{UInt64})
    node_idx = regular(f) >> 1

    if node_idx in marked
        return
    end

    push!(marked, node_idx)

    node = mgr.nodes[node_idx]
    if !is_terminal(node)
        mark_reachable!(mgr, node.then_child, marked)
        mark_reachable!(mgr, node.else_child, marked)
    end
end

"""
    check_gc(mgr::DDManager)

Check if garbage collection should be triggered and run it if needed.
"""
function check_gc(mgr::DDManager)
    if mgr.num_nodes > 0 && mgr.num_dead / mgr.num_nodes > mgr.gc_frac
        garbage_collect!(mgr)
    end
end
