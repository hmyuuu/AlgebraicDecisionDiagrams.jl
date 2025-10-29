module AlgebraicDecisionDiagrams

# Export types
export DDManager, NodeId

# Export BDD operations
export ith_var, bdd_and, bdd_or, bdd_xor, bdd_not, bdd_ite
export bdd_restrict, bdd_exists, bdd_forall

# Export ADD operations
export add_const, add_ith_var
export add_plus, add_minus, add_times, add_divide
export add_max, add_min, add_negate, add_scalar_multiply
export add_threshold, add_restrict, add_eval
export add_find_max, add_find_min

# Export ZDD operations
export zdd_empty, zdd_base, zdd_singleton
export zdd_union, zdd_intersection, zdd_difference
export zdd_subset0, zdd_subset1, zdd_change
export zdd_count, zdd_from_sets, zdd_to_sets
export zdd_unique_lookup

# Export utility functions
export count_nodes, count_paths, count_minterms
export print_dd, to_dot
export garbage_collect!, check_gc

# Include source files
include("types.jl")
include("unique.jl")
include("cache.jl")
include("bdd.jl")
include("add.jl")
include("zdd.jl")
include("utils.jl")

end # module AlgebraicDecisionDiagrams
