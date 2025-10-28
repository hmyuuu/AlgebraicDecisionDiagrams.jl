@testset "ADD Operations" begin
    @testset "ADD Constants" begin
        mgr = DDManager(2)

        # Create constants
        c1 = add_const(mgr, 5.0)
        c2 = add_const(mgr, 10.0)
        c3 = add_const(mgr, 5.0)

        @test c1 != c2
        @test c1 == c3  # Same value should return same node

        # Zero and one
        zero = add_const(mgr, 0.0)
        one = add_const(mgr, 1.0)
        @test zero != one
    end

    @testset "ADD Variables" begin
        mgr = DDManager(3)

        x1 = add_ith_var(mgr, 1)
        x2 = add_ith_var(mgr, 2)
        x3 = add_ith_var(mgr, 3)

        @test x1 != x2
        @test x2 != x3
        @test x1 != x3
    end

    @testset "ADD Addition" begin
        mgr = DDManager(2)

        c1 = add_const(mgr, 3.0)
        c2 = add_const(mgr, 7.0)

        # Add two constants
        result = add_plus(mgr, c1, c2)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test AlgebraicDecisionDiagrams.is_terminal(node)
        @test node.value == 10.0

        # Add with zero
        zero = add_const(mgr, 0.0)
        result = add_plus(mgr, c1, zero)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 3.0
    end

    @testset "ADD Subtraction" begin
        mgr = DDManager(2)

        c1 = add_const(mgr, 10.0)
        c2 = add_const(mgr, 3.0)

        result = add_minus(mgr, c1, c2)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 7.0
    end

    @testset "ADD Multiplication" begin
        mgr = DDManager(2)

        c1 = add_const(mgr, 4.0)
        c2 = add_const(mgr, 5.0)

        result = add_times(mgr, c1, c2)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 20.0

        # Multiply by zero
        zero = add_const(mgr, 0.0)
        result = add_times(mgr, c1, zero)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 0.0

        # Multiply by one
        one = add_const(mgr, 1.0)
        result = add_times(mgr, c1, one)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 4.0
    end

    @testset "ADD Division" begin
        mgr = DDManager(2)

        c1 = add_const(mgr, 20.0)
        c2 = add_const(mgr, 4.0)

        result = add_divide(mgr, c1, c2)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 5.0
    end

    @testset "ADD Max/Min" begin
        mgr = DDManager(2)

        c1 = add_const(mgr, 3.0)
        c2 = add_const(mgr, 7.0)

        # Max
        result = add_max(mgr, c1, c2)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 7.0

        # Min
        result = add_min(mgr, c1, c2)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 3.0
    end

    @testset "ADD Scalar Operations" begin
        mgr = DDManager(2)

        c = add_const(mgr, 5.0)

        # Scalar multiply
        result = add_scalar_multiply(mgr, c, 3.0)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == 15.0

        # Negate
        result = add_negate(mgr, c)
        node = AlgebraicDecisionDiagrams.get_node(mgr, result)
        @test node.value == -5.0
    end

    @testset "ADD with Variables" begin
        mgr = DDManager(2)

        x1 = add_ith_var(mgr, 1)
        c = add_const(mgr, 5.0)

        # Add variable and constant
        result = add_plus(mgr, x1, c)
        @test result != x1
        @test result != c

        # Multiply variable by constant
        result = add_times(mgr, x1, c)
        @test result != x1
        @test result != c
    end

    @testset "ADD Restrict" begin
        mgr = DDManager(2)

        x1 = add_ith_var(mgr, 1)
        c1 = add_const(mgr, 5.0)
        c2 = add_const(mgr, 10.0)

        # Create ADD: if x1 then 10 else 5
        f = add_plus(mgr, c1, add_times(mgr, x1, c2))

        # Restrict x1 = true should give something involving 10
        f_true = add_restrict(mgr, f, 1, true)
        @test f_true != f

        # Restrict x1 = false should give something involving 5
        f_false = add_restrict(mgr, f, 1, false)
        @test f_false != f
        @test f_true != f_false
    end

    @testset "ADD Evaluation" begin
        mgr = DDManager(2)

        # Create simple ADD: x1 (0-1 valued)
        x1 = add_ith_var(mgr, 1)

        # Evaluate with x1 = true
        val = add_eval(mgr, x1, Dict(1 => true))
        @test val == 1.0

        # Evaluate with x1 = false
        val = add_eval(mgr, x1, Dict(1 => false))
        @test val == 0.0

        # Constant evaluation
        c = add_const(mgr, 42.0)
        val = add_eval(mgr, c, Dict{Int,Bool}())
        @test val == 42.0
    end

    @testset "ADD Find Max/Min" begin
        mgr = DDManager(2)

        x1 = add_ith_var(mgr, 1)
        c1 = add_const(mgr, 5.0)
        c2 = add_const(mgr, 10.0)

        # Create ADD with multiple terminal values
        f = add_plus(mgr, c1, add_times(mgr, x1, c2))

        # Find max and min values
        max_val = add_find_max(mgr, f)
        min_val = add_find_min(mgr, f)

        @test max_val >= min_val
        @test max_val >= 5.0
        @test min_val <= 15.0
    end

    @testset "ADD Threshold" begin
        mgr = DDManager(2)

        c1 = add_const(mgr, 3.0)
        c2 = add_const(mgr, 7.0)

        # Threshold at 5.0
        bdd1 = add_threshold(mgr, c1, 5.0)
        bdd2 = add_threshold(mgr, c2, 5.0)

        # 3.0 < 5.0, so should be zero
        @test bdd1 == mgr.zero

        # 7.0 >= 5.0, so should be one
        @test bdd2 == mgr.one
    end

    @testset "ADD Complex Operations" begin
        mgr = DDManager(3)

        x1 = add_ith_var(mgr, 1)
        x2 = add_ith_var(mgr, 2)

        # (x1 + x2) * 2
        sum = add_plus(mgr, x1, x2)
        result = add_scalar_multiply(mgr, sum, 2.0)

        # Should be different from inputs
        @test result != x1
        @test result != x2
        @test result != sum

        # Evaluate at different points
        val1 = add_eval(mgr, result, Dict(1 => false, 2 => false))
        val2 = add_eval(mgr, result, Dict(1 => true, 2 => false))
        val3 = add_eval(mgr, result, Dict(1 => false, 2 => true))
        val4 = add_eval(mgr, result, Dict(1 => true, 2 => true))

        @test val1 == 0.0  # (0 + 0) * 2 = 0
        @test val2 == 2.0  # (1 + 0) * 2 = 2
        @test val3 == 2.0  # (0 + 1) * 2 = 2
        @test val4 == 4.0  # (1 + 1) * 2 = 4
    end
end
