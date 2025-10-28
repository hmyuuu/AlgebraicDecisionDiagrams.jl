/*
 * CUDD Benchmark Program
 * Compares CUDD C library performance with Julia implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "cudd/cudd/cudd.h"

// Timing utilities (using gettimeofday for macOS compatibility)
typedef struct {
    struct timeval start;
    struct timeval end;
} Timer;

void timer_start(Timer *t) {
    gettimeofday(&t->start, NULL);
}

double timer_end(Timer *t) {
    gettimeofday(&t->end, NULL);
    long sec_diff = t->end.tv_sec - t->start.tv_sec;
    long usec_diff = t->end.tv_usec - t->start.tv_usec;
    return (sec_diff * 1e6 + usec_diff) * 1000.0; // Return nanoseconds
}

// Benchmark: BDD AND chain
void benchmark_bdd_and_chain(int n, int iterations) {
    Timer t;
    double total_time = 0;

    for (int iter = 0; iter < iterations; iter++) {
        DdManager *mgr = Cudd_Init(n, 0, CUDD_UNIQUE_SLOTS, CUDD_CACHE_SLOTS, 0);

        timer_start(&t);

        DdNode **vars = malloc(n * sizeof(DdNode*));
        for (int i = 0; i < n; i++) {
            vars[i] = Cudd_bddIthVar(mgr, i);
        }

        DdNode *result = vars[0];
        Cudd_Ref(result);

        for (int i = 1; i < n; i++) {
            DdNode *new_result = Cudd_bddAnd(mgr, result, vars[i]);
            Cudd_Ref(new_result);
            Cudd_RecursiveDeref(mgr, result);
            result = new_result;
        }

        int node_count = Cudd_DagSize(result);

        total_time += timer_end(&t);

        Cudd_RecursiveDeref(mgr, result);
        free(vars);
        Cudd_Quit(mgr);
    }

    printf("BDD AND chain (n=%d): %.2f ns/op, avg nodes=%d\n",
           n, total_time / iterations, n);
}

// Benchmark: BDD operations
void benchmark_bdd_operations(int iterations) {
    Timer t;

    DdManager *mgr = Cudd_Init(10, 0, CUDD_UNIQUE_SLOTS, CUDD_CACHE_SLOTS, 0);
    DdNode *x1 = Cudd_bddIthVar(mgr, 0);
    DdNode *x2 = Cudd_bddIthVar(mgr, 1);
    DdNode *x3 = Cudd_bddIthVar(mgr, 2);

    // AND
    double total = 0;
    for (int i = 0; i < iterations; i++) {
        timer_start(&t);
        DdNode *result = Cudd_bddAnd(mgr, x1, x2);
        total += timer_end(&t);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    printf("BDD AND: %.2f ns/op\n", total / iterations);

    // OR
    total = 0;
    for (int i = 0; i < iterations; i++) {
        timer_start(&t);
        DdNode *result = Cudd_bddOr(mgr, x1, x2);
        total += timer_end(&t);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    printf("BDD OR: %.2f ns/op\n", total / iterations);

    // XOR
    total = 0;
    for (int i = 0; i < iterations; i++) {
        timer_start(&t);
        DdNode *result = Cudd_bddXor(mgr, x1, x2);
        total += timer_end(&t);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    printf("BDD XOR: %.2f ns/op\n", total / iterations);

    // NOT
    total = 0;
    for (int i = 0; i < iterations; i++) {
        timer_start(&t);
        DdNode *result = Cudd_Not(x1);
        total += timer_end(&t);
    }
    printf("BDD NOT: %.2f ns/op\n", total / iterations);

    // ITE
    total = 0;
    for (int i = 0; i < iterations; i++) {
        timer_start(&t);
        DdNode *result = Cudd_bddIte(mgr, x1, x2, x3);
        total += timer_end(&t);
        Cudd_Ref(result);
        Cudd_RecursiveDeref(mgr, result);
    }
    printf("BDD ITE: %.2f ns/op\n", total / iterations);

    Cudd_Quit(mgr);
}

// Benchmark: ADD operations
void benchmark_add_operations(int n, int iterations) {
    Timer t;
    double total_time = 0;

    for (int iter = 0; iter < iterations; iter++) {
        DdManager *mgr = Cudd_Init(n, 0, CUDD_UNIQUE_SLOTS, CUDD_CACHE_SLOTS, 0);

        timer_start(&t);

        DdNode **vars = malloc(n * sizeof(DdNode*));
        for (int i = 0; i < n; i++) {
            vars[i] = Cudd_addIthVar(mgr, i);
        }

        DdNode *result = vars[0];
        Cudd_Ref(result);

        for (int i = 1; i < n; i++) {
            DdNode *new_result = Cudd_addApply(mgr, Cudd_addPlus, result, vars[i]);
            Cudd_Ref(new_result);
            Cudd_RecursiveDeref(mgr, result);
            result = new_result;
        }

        int node_count = Cudd_DagSize(result);

        total_time += timer_end(&t);

        Cudd_RecursiveDeref(mgr, result);
        free(vars);
        Cudd_Quit(mgr);
    }

    printf("ADD plus chain (n=%d): %.2f ns/op\n",
           n, total_time / iterations);
}

// Benchmark: ZDD operations
void benchmark_zdd_operations(int n, int iterations) {
    Timer t;
    double total_time = 0;

    for (int iter = 0; iter < iterations; iter++) {
        DdManager *mgr = Cudd_Init(0, n, CUDD_UNIQUE_SLOTS, CUDD_CACHE_SLOTS, 0);

        timer_start(&t);

        DdNode **singletons = malloc(n * sizeof(DdNode*));
        for (int i = 0; i < n; i++) {
            singletons[i] = Cudd_zddIthVar(mgr, i);
        }

        DdNode *result = singletons[0];
        Cudd_Ref(result);

        for (int i = 1; i < n; i++) {
            DdNode *new_result = Cudd_zddUnion(mgr, result, singletons[i]);
            Cudd_Ref(new_result);
            Cudd_RecursiveDeref(mgr, result);
            result = new_result;
        }

        int node_count = Cudd_DagSize(result);

        total_time += timer_end(&t);

        Cudd_RecursiveDeref(mgr, result);
        free(singletons);
        Cudd_Quit(mgr);
    }

    printf("ZDD union chain (n=%d): %.2f ns/op\n",
           n, total_time / iterations);
}

int main() {
    printf("================================================================================\n");
    printf("CUDD C Library Performance Benchmarks\n");
    printf("================================================================================\n\n");

    printf("--- BDD Operations ---\n\n");
    benchmark_bdd_operations(10000);

    printf("\n--- BDD Scalability ---\n\n");
    benchmark_bdd_and_chain(5, 1000);
    benchmark_bdd_and_chain(10, 1000);
    benchmark_bdd_and_chain(20, 1000);
    benchmark_bdd_and_chain(50, 100);

    printf("\n--- ADD Operations ---\n\n");
    benchmark_add_operations(5, 1000);
    benchmark_add_operations(10, 1000);
    benchmark_add_operations(20, 100);

    printf("\n--- ZDD Operations ---\n\n");
    benchmark_zdd_operations(5, 1000);
    benchmark_zdd_operations(10, 1000);
    benchmark_zdd_operations(20, 1000);
    benchmark_zdd_operations(50, 100);

    printf("\n================================================================================\n");
    printf("Benchmark complete!\n");
    printf("================================================================================\n");

    return 0;
}
