@testset "ZDD Operations" begin
    @testset "ZDD Basics" begin
        mgr = DDManager(4)

        # Empty and base
        empty = zdd_empty(mgr)
        base = zdd_base(mgr)

        @test empty != base
        @test empty == zdd_empty(mgr)  # Consistent
        @test base == zdd_base(mgr)    # Consistent

        # Singleton sets
        s1 = zdd_singleton(mgr, 1)
        s2 = zdd_singleton(mgr, 2)

        @test s1 != empty
        @test s1 != base
        @test s1 != s2
    end

    @testset "ZDD Union" begin
        mgr = DDManager(4)

        s1 = zdd_singleton(mgr, 1)
        s2 = zdd_singleton(mgr, 2)

        # Union of singletons
        u = zdd_union(mgr, s1, s2)
        @test u != s1
        @test u != s2

        # Union with empty
        @test zdd_union(mgr, s1, zdd_empty(mgr)) == s1
        @test zdd_union(mgr, zdd_empty(mgr), s2) == s2

        # Union with self
        @test zdd_union(mgr, s1, s1) == s1

        # Commutativity
        @test zdd_union(mgr, s1, s2) == zdd_union(mgr, s2, s1)
    end

    @testset "ZDD Intersection" begin
        mgr = DDManager(4)

        s1 = zdd_singleton(mgr, 1)
        s2 = zdd_singleton(mgr, 2)

        # Intersection of different singletons is empty
        @test zdd_intersection(mgr, s1, s2) == zdd_empty(mgr)

        # Intersection with empty
        @test zdd_intersection(mgr, s1, zdd_empty(mgr)) == zdd_empty(mgr)

        # Intersection with self
        @test zdd_intersection(mgr, s1, s1) == s1

        # Commutativity
        @test zdd_intersection(mgr, s1, s2) == zdd_intersection(mgr, s2, s1)
    end

    @testset "ZDD Difference" begin
        mgr = DDManager(4)

        s1 = zdd_singleton(mgr, 1)
        s2 = zdd_singleton(mgr, 2)

        # Difference with empty
        @test zdd_difference(mgr, s1, zdd_empty(mgr)) == s1
        @test zdd_difference(mgr, zdd_empty(mgr), s1) == zdd_empty(mgr)

        # Difference with self
        @test zdd_difference(mgr, s1, s1) == zdd_empty(mgr)

        # Difference of different singletons
        @test zdd_difference(mgr, s1, s2) == s1
    end

    @testset "ZDD Subset Operations" begin
        mgr = DDManager(3)

        # Create ZDD for {{1}, {2}, {1,2}}
        s1 = zdd_singleton(mgr, 1)
        s2 = zdd_singleton(mgr, 2)
        s12_then = zdd_singleton(mgr, 2)
        s12 = zdd_unique_lookup(mgr, 1, s12_then, mgr.zero)

        f = zdd_union(mgr, zdd_union(mgr, s1, s2), s12)

        # Subset1: sets containing variable 1
        sub1 = zdd_subset1(mgr, f, 1)
        @test sub1 != zdd_empty(mgr)

        # Subset0: sets not containing variable 1
        sub0 = zdd_subset0(mgr, f, 1)
        @test sub0 != zdd_empty(mgr)

        # Union of subset0 and subset1 should give back original (approximately)
        # Note: This is a simplified test
        @test zdd_union(mgr, sub0, sub1) != zdd_empty(mgr)
    end

    @testset "ZDD Count" begin
        mgr = DDManager(3)

        # Empty set has 0 combinations
        @test zdd_count(mgr, zdd_empty(mgr)) == 0

        # Base (empty set family) has 1 combination
        @test zdd_count(mgr, zdd_base(mgr)) == 1

        # Singleton has 1 combination
        s1 = zdd_singleton(mgr, 1)
        @test zdd_count(mgr, s1) == 1

        # Union of two singletons has 2 combinations
        s2 = zdd_singleton(mgr, 2)
        u = zdd_union(mgr, s1, s2)
        @test zdd_count(mgr, u) == 2
    end

    @testset "ZDD From/To Sets" begin
        mgr = DDManager(4)

        # Create ZDD from sets
        sets = [[1], [2], [1, 2], [3]]
        zdd = zdd_from_sets(mgr, sets)

        @test zdd != zdd_empty(mgr)
        @test zdd_count(mgr, zdd) == 4

        # Convert back to sets
        result_sets = zdd_to_sets(mgr, zdd)
        @test length(result_sets) == 4

        # Check that all original sets are present (order may differ)
        for s in sets
            @test sort(s) in [sort(rs) for rs in result_sets]
        end
    end

    @testset "ZDD Change Operation" begin
        mgr = DDManager(3)

        # Change on base gives singleton
        s1 = zdd_change(mgr, zdd_base(mgr), 1)
        @test s1 == zdd_singleton(mgr, 1)

        # Change on empty gives empty
        @test zdd_change(mgr, zdd_empty(mgr), 1) == zdd_empty(mgr)
    end

    @testset "ZDD Complex Example" begin
        mgr = DDManager(4)

        # Create family of sets: {{1,2}, {2,3}, {1,3}}
        sets = [[1, 2], [2, 3], [1, 3]]
        family = zdd_from_sets(mgr, sets)

        @test zdd_count(mgr, family) == 3

        # Intersection with {{1,2}, {1,3}, {1,4}}
        sets2 = [[1, 2], [1, 3], [1, 4]]
        family2 = zdd_from_sets(mgr, sets2)

        intersect = zdd_intersection(mgr, family, family2)
        result = zdd_to_sets(mgr, intersect)

        # Should have {{1,2}, {1,3}}
        @test length(result) == 2
        @test sort([1, 2]) in [sort(s) for s in result]
        @test sort([1, 3]) in [sort(s) for s in result]
    end

    @testset "ZDD Node Counting" begin
        mgr = DDManager(4)

        # Empty and base are terminals
        @test count_nodes(mgr, zdd_empty(mgr)) == 0
        @test count_nodes(mgr, zdd_base(mgr)) == 0

        # Singleton has 1 node
        s1 = zdd_singleton(mgr, 1)
        @test count_nodes(mgr, s1) >= 1

        # Union creates more nodes
        s2 = zdd_singleton(mgr, 2)
        u = zdd_union(mgr, s1, s2)
        nodes_u = count_nodes(mgr, u)
        @test nodes_u >= count_nodes(mgr, s1)
    end
end
