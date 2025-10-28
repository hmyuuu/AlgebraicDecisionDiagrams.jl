# CUDD C library wrapper for benchmarking

# This assumes CUDD is installed and libcudd.so is available
# Install CUDD: https://github.com/cuddorg/cudd

const CUDD_LIB = "/tmp/cudd/cudd/.libs/libcudd.so"

# Check if CUDD library exists
function check_cudd_available()
    return isfile(CUDD_LIB)
end

if check_cudd_available()
    # CUDD Manager type (opaque pointer)
    const DdManager = Ptr{Cvoid}
    const DdNode = Ptr{Cvoid}

    # CUDD initialization
    function Cudd_Init(numVars::Integer, numVarsZ::Integer, numSlots::Integer, cacheSize::Integer, maxMemory::Integer)
        ccall((:Cudd_Init, CUDD_LIB), DdManager,
              (Cuint, Cuint, Cuint, Cuint, Culong),
              numVars, numVarsZ, numSlots, cacheSize, maxMemory)
    end

    # CUDD cleanup
    function Cudd_Quit(manager::DdManager)
        ccall((:Cudd_Quit, CUDD_LIB), Cvoid, (DdManager,), manager)
    end

    # BDD operations
    function Cudd_ReadOne(manager::DdManager)
        ccall((:Cudd_ReadOne, CUDD_LIB), DdNode, (DdManager,), manager)
    end

    function Cudd_ReadLogicZero(manager::DdManager)
        ccall((:Cudd_ReadLogicZero, CUDD_LIB), DdNode, (DdManager,), manager)
    end

    function Cudd_bddIthVar(manager::DdManager, i::Integer)
        ccall((:Cudd_bddIthVar, CUDD_LIB), DdNode, (DdManager, Cint), manager, i)
    end

    function Cudd_bddAnd(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_bddAnd, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_bddOr(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_bddOr, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_bddXor(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_bddXor, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_Not(node::DdNode)
        ccall((:Cudd_Not, CUDD_LIB), DdNode, (DdNode,), node)
    end

    function Cudd_bddIte(manager::DdManager, f::DdNode, g::DdNode, h::DdNode)
        ccall((:Cudd_bddIte, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode, DdNode), manager, f, g, h)
    end

    # Reference counting
    function Cudd_Ref(node::DdNode)
        ccall((:Cudd_Ref, CUDD_LIB), Cvoid, (DdNode,), node)
    end

    function Cudd_RecursiveDeref(manager::DdManager, node::DdNode)
        ccall((:Cudd_RecursiveDeref, CUDD_LIB), Cvoid, (DdManager, DdNode), manager, node)
    end

    # Statistics
    function Cudd_DagSize(node::DdNode)
        ccall((:Cudd_DagSize, CUDD_LIB), Cint, (DdNode,), node)
    end

    function Cudd_CountMinterm(manager::DdManager, node::DdNode, nvars::Integer)
        ccall((:Cudd_CountMinterm, CUDD_LIB), Cdouble, (DdManager, DdNode, Cint), manager, node, nvars)
    end

    function Cudd_ReadNodeCount(manager::DdManager)
        ccall((:Cudd_ReadNodeCount, CUDD_LIB), Clong, (DdManager,), manager)
    end

    function Cudd_ReadPeakNodeCount(manager::DdManager)
        ccall((:Cudd_ReadPeakNodeCount, CUDD_LIB), Clong, (DdManager,), manager)
    end

    # ADD operations
    function Cudd_addConst(manager::DdManager, value::Float64)
        ccall((:Cudd_addConst, CUDD_LIB), DdNode, (DdManager, Cdouble), manager, value)
    end

    function Cudd_addIthVar(manager::DdManager, i::Integer)
        ccall((:Cudd_addIthVar, CUDD_LIB), DdNode, (DdManager, Cint), manager, i)
    end

    function Cudd_addPlus(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_addPlus, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_addTimes(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_addTimes, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_addMinus(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_addMinus, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_addMaximum(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_addMaximum, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_addMinimum(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_addMinimum, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    # ZDD operations
    function Cudd_zddIthVar(manager::DdManager, i::Integer)
        ccall((:Cudd_zddIthVar, CUDD_LIB), DdNode, (DdManager, Cint), manager, i)
    end

    function Cudd_zddUnion(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_zddUnion, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_zddIntersect(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_zddIntersect, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_zddDiff(manager::DdManager, f::DdNode, g::DdNode)
        ccall((:Cudd_zddDiff, CUDD_LIB), DdNode, (DdManager, DdNode, DdNode), manager, f, g)
    end

    function Cudd_zddCount(manager::DdManager, node::DdNode)
        ccall((:Cudd_zddCount, CUDD_LIB), Cdouble, (DdManager, DdNode), manager, node)
    end

    println("✓ CUDD library loaded successfully from: $CUDD_LIB")
else
    println("⚠ CUDD library not found at: $CUDD_LIB")
    println("  Benchmarks against CUDD will be skipped.")
    println("  To enable CUDD benchmarks:")
    println("  1. Clone CUDD: git clone https://github.com/cuddorg/cudd /tmp/cudd")
    println("  2. Build CUDD: cd /tmp/cudd && ./configure && make")
    println("  3. Re-run benchmarks")
end
