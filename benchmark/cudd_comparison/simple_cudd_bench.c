#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "cudd/cudd/cudd.h"

double get_time_ns() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1e9 + tv.tv_usec * 1e3;
}

int main() {
    printf("================================================================================\n");
    printf("CUDD C Library Benchmarks\n");
    printf("================================================================================\n\n");

    // Initialize CUDD
    DdManager *mgr = Cudd_Init(100, 0, CUDD_UNIQUE_SLOTS, CUDD_CACHE_SLOTS, 0);
    if (mgr == NULL) {
        printf("Failed to initialize CUDD\n");
        return 1;
    }

    printf("--- BDD Operations (Warm/Cached - 10000 iterations) ---\n\n");

    // Create variables
    DdNode *x1 = Cudd_bddIthVar(mgr, 0);
    DdNode *x2 = Cudd_bddIthVar(mgr, 1);
    DdNode *x3 = Cudd_bddIthVar(mgr, 2);

    // Benchmark AND
    double start = get_time_ns();
    for (int i = 0; i < 10000; i++) {
        DdNode *result = Cudd_bddAnd(mgr, x1, x2);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    double end = get_time_ns();
    printf("BDD AND:  %.2f ns/op\n", (end - start) / 10000);

    // Benchmark OR
    start = get_time_ns();
    for (int i = 0; i < 10000; i++) {
        DdNode *result = Cudd_bddOr(mgr, x1, x2);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    end = get_time_ns();
    printf("BDD OR:   %.2f ns/op\n", (end - start) / 10000);

    // Benchmark XOR
    start = get_time_ns();
    for (int i = 0; i < 10000; i++) {
        DdNode *result = Cudd_bddXor(mgr, x1, x2);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    end = get_time_ns();
    printf("BDD XOR:  %.2f ns/op\n", (end - start) / 10000);

    // Benchmark NOT
    start = get_time_ns();
    for (int i = 0; i < 10000; i++) {
        DdNode *result = Cudd_Not(x1);
        (void)result; // Use result to prevent optimization
    }
    end = get_time_ns();
    printf("BDD NOT:  %.2f ns/op\n", (end - start) / 10000);

    // Benchmark ITE
    start = get_time_ns();
    for (int i = 0; i < 10000; i++) {
        DdNode *result = Cudd_bddIte(mgr, x1, x2, x3);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    end = get_time_ns();
    printf("BDD ITE:  %.2f ns/op\n", (end - start) / 10000);

    printf("\n--- BDD AND Chain (Warm/Cached) ---\n\n");

    // Test different chain lengths - warm performance (variables pre-created)
    int sizes[] = {5, 10, 20, 50};
    for (int s = 0; s < 4; s++) {
        int n = sizes[s];

        // Pre-create variables (not timed)
        DdNode **vars = malloc(n * sizeof(DdNode*));
        for (int i = 0; i < n; i++) {
            vars[i] = Cudd_bddIthVar(mgr, i);
        }

        // Time only the AND chain operations
        start = get_time_ns();

        DdNode *result = vars[0];
        Cudd_Ref(result);

        for (int i = 1; i < n; i++) {
            DdNode *new_result = Cudd_bddAnd(mgr, result, vars[i]);
            Cudd_Ref(new_result);
            Cudd_RecursiveDeref(mgr, result);
            result = new_result;
        }

        end = get_time_ns();

        int nodes = Cudd_DagSize(result);
        printf("n=%2d: %.2f μs, %d nodes\n", n, (end - start) / 1000, nodes);

        Cudd_RecursiveDeref(mgr, result);
        free(vars);
    }

    printf("\n--- BDD AND Chain (Cold - with initialization) ---\n\n");

    // Test cold performance including manager initialization
    for (int s = 0; s < 4; s++) {
        int n = sizes[s];

        start = get_time_ns();

        // Create new manager for each test
        DdManager *mgr_cold = Cudd_Init(n, 0, CUDD_UNIQUE_SLOTS, CUDD_CACHE_SLOTS, 0);

        DdNode **vars = malloc(n * sizeof(DdNode*));
        for (int i = 0; i < n; i++) {
            vars[i] = Cudd_bddIthVar(mgr_cold, i);
        }

        DdNode *result = vars[0];
        Cudd_Ref(result);

        for (int i = 1; i < n; i++) {
            DdNode *new_result = Cudd_bddAnd(mgr_cold, result, vars[i]);
            Cudd_Ref(new_result);
            Cudd_RecursiveDeref(mgr_cold, result);
            result = new_result;
        }

        int nodes = Cudd_DagSize(result);

        end = get_time_ns();

        printf("n=%2d: %.2f μs, %d nodes\n", n, (end - start) / 1000, nodes);

        Cudd_RecursiveDeref(mgr_cold, result);
        free(vars);
        Cudd_Quit(mgr_cold);
    }

    printf("\n--- Statistics ---\n\n");
    printf("Total nodes in manager: %ld\n", Cudd_ReadNodeCount(mgr));
    printf("Peak nodes: %ld\n", Cudd_ReadPeakNodeCount(mgr));

    Cudd_Quit(mgr);

    printf("\n================================================================================\n");
    printf("Benchmark complete!\n");
    printf("================================================================================\n");

    return 0;
}
