# Computed table (cache) operations for memoization

# Operation tags for cache
const OP_AND = UInt64(1)
const OP_OR = UInt64(2)
const OP_XOR = UInt64(3)
const OP_ITE = UInt64(4)
const OP_ADD_APPLY = UInt64(100)  # Base for ADD operations
const OP_ZDD_UNION = UInt64(200)
const OP_ZDD_INTERSECT = UInt64(201)
const OP_ZDD_DIFF = UInt64(202)

"""
    cache_hash(op::UInt64, f::NodeId, g::NodeId, h::UInt64, shift::Int)

Hash function for computed table.
"""
@inline function cache_hash(op::UInt64, f::NodeId, g::NodeId, h::UInt64, cache_size::Int)
    hash_val = (op * HASH_P1 + f * HASH_P2 + g * HASH_P1 + h * HASH_P2)
    return Int(((hash_val - 1) % cache_size) + 1)
end

"""
    cache_lookup(mgr::DDManager, op::UInt64, f::NodeId, g::NodeId, h::UInt64)

Look up a cached result for an operation.
Returns INVALID_NODE if not found.
"""
function cache_lookup(mgr::DDManager, op::UInt64, f::NodeId, g::NodeId, h::UInt64)
    cache = mgr.cache
    idx = cache_hash(op, f, g, h, length(cache.entries))

    entry = cache.entries[idx]

    # Check if entry matches (direct-mapped cache, so just check equality)
    if entry.f == f && entry.g == g && entry.h == (h ⊻ op)
        return entry.result
    end

    return INVALID_NODE
end

"""
    cache_insert!(mgr::DDManager, op::UInt64, f::NodeId, g::NodeId, h::UInt64, result::NodeId)

Insert a result into the cache.
"""
function cache_insert!(mgr::DDManager, op::UInt64, f::NodeId, g::NodeId, h::UInt64, result::NodeId)
    cache = mgr.cache
    idx = cache_hash(op, f, g, h, length(cache.entries))

    # Direct-mapped: just overwrite
    cache.entries[idx] = CacheEntry(f, g, h ⊻ op, result)
end

"""
    clear_cache!(mgr::DDManager)

Clear all cache entries.
"""
function clear_cache!(mgr::DDManager)
    for i in eachindex(mgr.cache.entries)
        mgr.cache.entries[i] = CacheEntry()
    end
end
