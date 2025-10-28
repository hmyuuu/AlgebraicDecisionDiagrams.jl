@testset "Utility Functions" begin
    @testset "Node Counting" begin
        mgr = DDManager(4)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        x3 = ith_var(mgr, 3)

        # Single variable
        @test count_nodes(mgr, x1) == 1

        # Constants
        @test count_nodes(mgr, mgr.zero) == 0
        @test count_nodes(mgr, mgr.one) == 0

        # AND of two variables
        f = bdd_and(mgr, x1, x2)
        nodes_f = count_nodes(mgr, f)
        @test nodes_f >= 2

        # More complex formula
        g = bdd_or(mgr, bdd_and(mgr, x1, x2), x3)
        nodes_g = count_nodes(mgr, g)
        @test nodes_g >= nodes_f
    end

    @testset "Path Counting" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # Constant zero has 0 paths
        @test count_paths(mgr, mgr.zero) == 0

        # Constant one has 1 path
        @test count_paths(mgr, mgr.one) == 1

        # Single variable has 1 path to 1
        @test count_paths(mgr, x1) == 1

        # x1 OR x2 has 3 paths to 1
        f = bdd_or(mgr, x1, x2)
        @test count_paths(mgr, f) >= 1
    end

    @testset "Minterm Counting" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # Constant zero
        @test count_minterms(mgr, mgr.zero, 3) == 0.0

        # Constant one (all 2^3 = 8 assignments)
        @test count_minterms(mgr, mgr.one, 3) == 8.0

        # Single variable (half of assignments)
        @test count_minterms(mgr, x1, 3) == 4.0

        # x1 AND x2 (quarter of assignments)
        f = bdd_and(mgr, x1, x2)
        @test count_minterms(mgr, f, 3) == 2.0
    end

    @testset "Print DD" begin
        mgr = DDManager(2)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        f = bdd_and(mgr, x1, x2)

        # Should not error
        @test_nowarn print_dd(mgr, f, max_depth=5)
        @test_nowarn print_dd(mgr, mgr.zero)
        @test_nowarn print_dd(mgr, mgr.one)
    end

    @testset "DOT Export" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        f = bdd_and(mgr, x1, x2)

        # Export to DOT file
        filename = tempname() * ".dot"
        @test_nowarn to_dot(mgr, f, filename)

        # Check file was created
        @test isfile(filename)

        # Check file has content
        content = read(filename, String)
        @test occursin("digraph DD", content)
        @test occursin("node", content)

        # Clean up
        rm(filename)
    end

    @testset "Garbage Collection" begin
        mgr = DDManager(4)

        # Create some nodes
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        f = bdd_and(mgr, x1, x2)

        initial_nodes = mgr.num_nodes

        # Create more nodes that will become garbage
        for i in 1:10
            temp = bdd_and(mgr, x1, x2)
        end

        # GC should not error
        @test_nowarn garbage_collect!(mgr)

        # Check GC ran
        @test mgr.num_nodes >= initial_nodes
    end

    @testset "Manager Statistics" begin
        mgr = DDManager(5)

        @test mgr.num_vars == 5
        @test mgr.num_nodes >= 2  # At least the two terminal nodes
        @test mgr.num_dead >= 0

        # Create some nodes
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        f = bdd_and(mgr, x1, x2)

        @test mgr.num_nodes > 2
    end

    @testset "Variable Ordering" begin
        mgr = DDManager(4)

        # Check initial ordering is identity
        @test mgr.perm == [1, 2, 3, 4]
        @test mgr.invperm == [1, 2, 3, 4]

        # Check variable projection functions exist
        @test length(mgr.vars) == 4
        for i in 1:4
            @test mgr.vars[i] != mgr.zero
            @test mgr.vars[i] != mgr.one
        end
    end

    @testset "Cache Operations" begin
        mgr = DDManager(3)

        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # Perform operation (will cache result)
        f1 = bdd_and(mgr, x1, x2)

        # Same operation should use cache
        f2 = bdd_and(mgr, x1, x2)
        @test f1 == f2

        # Clear cache
        @test_nowarn AlgebraicDecisionDiagrams.clear_cache!(mgr)

        # Operation should still work after cache clear
        f3 = bdd_and(mgr, x1, x2)
        @test f1 == f3
    end
end
