# Unique table operations for hash consing

# Hash function constants (from CUDD)
const HASH_P1 = UInt64(12582917)
const HASH_P2 = UInt64(4256249)

"""
    hash_node(then_child::NodeId, else_child::NodeId, shift::Int)

Hash function for unique table lookup.
"""
@inline function hash_node(then_child::NodeId, else_child::NodeId, shift::Int)
    h = (regular(then_child) * HASH_P1 + regular(else_child)) * HASH_P2
    return (h >> shift) + 1  # +1 for 1-based indexing
end

"""
    unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId)

Look up or create a unique node with the given variable and children.
Implements the reduction rule: if then_child == else_child, return then_child.
"""
function unique_lookup(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId)
    # Reduction rule: if both children are the same, return that child
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
            # Found existing node
            return NodeId(node_idx << 1)  # Convert to NodeId (shift left, clear complement bit)
        end
        node_idx = node.next
    end

    # Node not found, create new one
    return create_node!(mgr, var_index, then_child, else_child, table, slot_idx)
end

"""
    create_node!(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId,
                 table::UniqueTable, slot_idx::Int)

Create a new node and insert it into the unique table.
"""
function create_node!(mgr::DDManager, var_index::Int, then_child::NodeId, else_child::NodeId,
                      table::UniqueTable, slot_idx::Int)
    # Allocate node
    if !isempty(mgr.free_list)
        node_idx = pop!(mgr.free_list)
        node = mgr.nodes[node_idx]
        node.index = UInt32(var_index)
        node.ref = UInt32(0)
        node.then_child = then_child
        node.else_child = else_child
        node.value = 0.0
    else
        node = DDNode(var_index, then_child, else_child)
        push!(mgr.nodes, node)
        node_idx = length(mgr.nodes)
    end

    # Insert at head of collision chain
    node = mgr.nodes[node_idx]
    node.next = table.slots[slot_idx]
    table.slots[slot_idx] = node_idx

    table.keys += 1
    mgr.num_nodes += 1

    # Check if resize needed
    if table.keys > length(table.slots) * 4
        resize_unique_table!(mgr, mgr.perm[var_index])
    end

    return NodeId(node_idx << 1)
end

"""
    resize_unique_table!(mgr::DDManager, level::Int)

Resize a unique table when it becomes too dense.
"""
function resize_unique_table!(mgr::DDManager, level::Int)
    table = mgr.unique_tables[level]
    old_slots = table.slots
    new_size = length(old_slots) * 2

    # Create new table
    table.slots = zeros(UInt64, new_size)
    table.shift = 64 - trailing_zeros(new_size)
    table.keys = 0

    # Rehash all nodes
    for old_slot in old_slots
        node_idx = old_slot
        while node_idx != 0
            node = mgr.nodes[node_idx]
            next_idx = node.next

            # Reinsert node
            h = hash_node(node.then_child, node.else_child, table.shift)
            new_slot = ((h - 1) % new_size) + 1
            node.next = table.slots[new_slot]
            table.slots[new_slot] = node_idx
            table.keys += 1

            node_idx = next_idx
        end
    end
end

"""
    get_node(mgr::DDManager, id::NodeId)

Get the node corresponding to a NodeId, handling complement edges.
"""
@inline function get_node(mgr::DDManager, id::NodeId)
    node_idx = regular(id) >> 1
    return mgr.nodes[node_idx]
end

"""
    node_index(id::NodeId)

Get the variable index of a node.
"""
@inline function node_index(mgr::DDManager, id::NodeId)
    return get_node(mgr, id).index
end

"""
    node_level(mgr::DDManager, id::NodeId)

Get the level of a node in the variable ordering.
"""
@inline function node_level(mgr::DDManager, id::NodeId)
    node = get_node(mgr, id)
    if is_terminal(node)
        return typemax(Int)
    end
    return mgr.perm[node.index]
end

"""
    then_child(mgr::DDManager, id::NodeId)

Get the then (high) child of a node.
"""
@inline function then_child(mgr::DDManager, id::NodeId)
    node = get_node(mgr, id)
    child = node.then_child
    # Handle complement edge
    if is_complemented(id)
        return complement(child)
    end
    return child
end

"""
    else_child(mgr::DDManager, id::NodeId)

Get the else (low) child of a node.
"""
@inline function else_child(mgr::DDManager, id::NodeId)
    node = get_node(mgr, id)
    child = node.else_child
    # Handle complement edge
    if is_complemented(id)
        return complement(child)
    end
    return child
end

"""
    node_value(mgr::DDManager, id::NodeId)

Get the value of a terminal node.
"""
@inline function node_value(mgr::DDManager, id::NodeId)
    node = get_node(mgr, id)
    val = node.value
    # Handle complement edge for BDDs
    if is_complemented(id)
        return 1.0 - val
    end
    return val
end

"""
    ref!(mgr::DDManager, id::NodeId)

Increment reference count of a node.
"""
function ref!(mgr::DDManager, id::NodeId)
    if id == mgr.zero || id == mgr.one
        return  # Don't ref terminals
    end
    node = get_node(mgr, id)
    if node.ref < typemax(UInt32)
        node.ref += 1
    end
end

"""
    deref!(mgr::DDManager, id::NodeId)

Decrement reference count of a node.
"""
function deref!(mgr::DDManager, id::NodeId)
    if id == mgr.zero || id == mgr.one
        return  # Don't deref terminals
    end
    node = get_node(mgr, id)
    if node.ref > 0 && node.ref < typemax(UInt32)
        node.ref -= 1
        if node.ref == 0
            mgr.num_dead += 1
        end
    end
end
