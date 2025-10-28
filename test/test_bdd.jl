@testset "BDD Operations" begin
    @testset "Basic BDD Construction" begin
        mgr = DDManager(3)

        # Test variable creation
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        x3 = ith_var(mgr, 3)

        @test x1 != mgr.zero
        @test x1 != mgr.one
        @test x2 != x1
        @test x3 != x1
    end

    @testset "BDD NOT Operation" begin
        mgr = DDManager(2)
        x1 = ith_var(mgr, 1)

        # NOT operation
        not_x1 = bdd_not(mgr, x1)
        @test not_x1 != x1

        # Double negation
        not_not_x1 = bdd_not(mgr, not_x1)
        @test not_not_x1 == x1

        # NOT of constants
        @test bdd_not(mgr, mgr.zero) == mgr.one
        @test bdd_not(mgr, mgr.one) == mgr.zero
    end

    @testset "BDD AND Operation" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # AND with constants
        @test bdd_and(mgr, x1, mgr.one) == x1
        @test bdd_and(mgr, x1, mgr.zero) == mgr.zero
        @test bdd_and(mgr, mgr.one, mgr.one) == mgr.one
        @test bdd_and(mgr, mgr.zero, mgr.zero) == mgr.zero

        # AND with self
        @test bdd_and(mgr, x1, x1) == x1

        # AND with negation
        @test bdd_and(mgr, x1, bdd_not(mgr, x1)) == mgr.zero

        # AND of different variables
        x1_and_x2 = bdd_and(mgr, x1, x2)
        @test x1_and_x2 != mgr.zero
        @test x1_and_x2 != mgr.one
        @test x1_and_x2 != x1
        @test x1_and_x2 != x2
    end

    @testset "BDD OR Operation" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # OR with constants
        @test bdd_or(mgr, x1, mgr.zero) == x1
        @test bdd_or(mgr, x1, mgr.one) == mgr.one
        @test bdd_or(mgr, mgr.zero, mgr.zero) == mgr.zero
        @test bdd_or(mgr, mgr.one, mgr.one) == mgr.one

        # OR with self
        @test bdd_or(mgr, x1, x1) == x1

        # OR with negation
        @test bdd_or(mgr, x1, bdd_not(mgr, x1)) == mgr.one

        # OR of different variables
        x1_or_x2 = bdd_or(mgr, x1, x2)
        @test x1_or_x2 != mgr.zero
        @test x1_or_x2 != mgr.one
    end

    @testset "BDD XOR Operation" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # XOR with constants
        @test bdd_xor(mgr, x1, mgr.zero) == x1
        @test bdd_xor(mgr, x1, mgr.one) == bdd_not(mgr, x1)
        @test bdd_xor(mgr, mgr.zero, mgr.zero) == mgr.zero
        @test bdd_xor(mgr, mgr.one, mgr.one) == mgr.zero

        # XOR with self
        @test bdd_xor(mgr, x1, x1) == mgr.zero

        # XOR with negation
        @test bdd_xor(mgr, x1, bdd_not(mgr, x1)) == mgr.one
    end

    @testset "BDD ITE Operation" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        x3 = ith_var(mgr, 3)

        # ITE terminal cases
        @test bdd_ite(mgr, mgr.one, x2, x3) == x2
        @test bdd_ite(mgr, mgr.zero, x2, x3) == x3
        @test bdd_ite(mgr, x1, x2, x2) == x2
        @test bdd_ite(mgr, x1, mgr.one, mgr.zero) == x1

        # ITE implements AND
        and_result = bdd_and(mgr, x1, x2)
        ite_result = bdd_ite(mgr, x1, x2, mgr.zero)
        @test and_result == ite_result

        # ITE implements OR
        or_result = bdd_or(mgr, x1, x2)
        ite_result = bdd_ite(mgr, x1, mgr.one, x2)
        @test or_result == ite_result
    end

    @testset "BDD Complex Formulas" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        x3 = ith_var(mgr, 3)

        # (x1 ∧ x2) ∨ (x1 ∧ x3)
        f1 = bdd_or(mgr, bdd_and(mgr, x1, x2), bdd_and(mgr, x1, x3))

        # x1 ∧ (x2 ∨ x3) - should be equivalent by distributivity
        f2 = bdd_and(mgr, x1, bdd_or(mgr, x2, x3))

        @test f1 == f2

        # De Morgan's law: ¬(x1 ∧ x2) = ¬x1 ∨ ¬x2
        lhs = bdd_not(mgr, bdd_and(mgr, x1, x2))
        rhs = bdd_or(mgr, bdd_not(mgr, x1), bdd_not(mgr, x2))
        @test lhs == rhs
    end

    @testset "BDD Restrict" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # f = x1 ∧ x2
        f = bdd_and(mgr, x1, x2)

        # f[x1=1] = x2
        f_x1_true = bdd_restrict(mgr, f, 1, true)
        @test f_x1_true == x2

        # f[x1=0] = 0
        f_x1_false = bdd_restrict(mgr, f, 1, false)
        @test f_x1_false == mgr.zero

        # f[x2=1] = x1
        f_x2_true = bdd_restrict(mgr, f, 2, true)
        @test f_x2_true == x1
    end

    @testset "BDD Quantification" begin
        mgr = DDManager(3)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)
        x3 = ith_var(mgr, 3)

        # f = x1 ∧ x2
        f = bdd_and(mgr, x1, x2)

        # ∃x1. (x1 ∧ x2) = x2
        exists_x1 = bdd_exists(mgr, f, [1])
        @test exists_x1 == x2

        # ∀x1. (x1 ∧ x2) = 0
        forall_x1 = bdd_forall(mgr, f, [1])
        @test forall_x1 == mgr.zero

        # ∃x2. (x1 ∧ x2) = x1
        exists_x2 = bdd_exists(mgr, f, [2])
        @test exists_x2 == x1
    end

    @testset "BDD Node Counting" begin
        mgr = DDManager(4)
        x1 = ith_var(mgr, 1)
        x2 = ith_var(mgr, 2)

        # Single variable has 1 node
        @test count_nodes(mgr, x1) == 1

        # Constant has 0 nodes (terminals don't count)
        @test count_nodes(mgr, mgr.zero) == 0
        @test count_nodes(mgr, mgr.one) == 0

        # x1 ∧ x2 should have 2 nodes
        f = bdd_and(mgr, x1, x2)
        @test count_nodes(mgr, f) >= 2
    end
end
