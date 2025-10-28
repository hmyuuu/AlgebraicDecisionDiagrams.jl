#include <stdio.h>
#include "cudd/cudd/cudd.h"

int main() {
    printf("Testing CUDD...\n");

    DdManager *mgr = Cudd_Init(3, 0, CUDD_UNIQUE_SLOTS, CUDD_CACHE_SLOTS, 0);
    if (mgr == NULL) {
        printf("Failed to initialize CUDD\n");
        return 1;
    }

    printf("CUDD initialized successfully\n");

    DdNode *x1 = Cudd_bddIthVar(mgr, 0);
    DdNode *x2 = Cudd_bddIthVar(mgr, 1);

    printf("Created variables\n");

    DdNode *result = Cudd_bddAnd(mgr, x1, x2);
    Cudd_Ref(result);

    printf("AND operation successful\n");
    printf("Node count: %d\n", Cudd_DagSize(result));

    Cudd_RecursiveDeref(mgr, result);
    Cudd_Quit(mgr);

    printf("Test completed successfully!\n");
    return 0;
}
