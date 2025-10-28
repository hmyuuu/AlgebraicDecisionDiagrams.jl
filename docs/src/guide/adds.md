# Algebraic Decision Diagrams (ADDs)

Algebraic Decision Diagrams (ADDs) extend BDDs to represent functions that map Boolean variables to real numbers. They are useful for probabilistic reasoning, optimization, and numerical computations.

## What are ADDs?

An ADD is similar to a BDD, but:
- Terminal nodes contain real values (not just true/false)
- Represents functions: `f: {0,1}ⁿ → ℝ`
- Supports arithmetic operations (addition, multiplication, min, max)
- No complement edges (unlike BDDs)

## Creating ADDs

### Variables

ADD variables represent 0-1 indicator functions:

```julia
using AlgebraicDecisionDiagrams

mgr = DDManager(3)

# Create ADD variables (0-1 functions)
x1 = add_ith_var(mgr, 1)  # 1 if var 1 is true, 0 otherwise
x2 = add_ith_var(mgr, 2)
x3 = add_ith_var(mgr, 3)
```

### Constants

Create constant ADDs:

```julia
mgr = DDManager(3)

# Constant values
c0 = add_const(mgr, 0.0)
c1 = add_const(mgr, 1.0)
c5 = add_const(mgr, 5.0)
c_neg = add_const(mgr, -3.5)
```

## Arithmetic Operations

### Addition

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# f(x1, x2) = x1 + x2
# Returns: 0 if both false, 1 if one true, 2 if both true
f = add_plus(mgr, x1, x2)

# With constants: g(x1, x2) = 5 + 3*x1 + 2*x2
c5 = add_const(mgr, 5.0)
c3 = add_const(mgr, 3.0)
c2 = add_const(mgr, 2.0)

g = add_plus(mgr,
    add_plus(mgr, c5, add_times(mgr, c3, x1)),
    add_times(mgr, c2, x2))
```

### Multiplication

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# f(x1, x2) = x1 * x2 (AND operation for 0-1 functions)
f = add_times(mgr, x1, x2)

# Polynomial: g(x1, x2) = 2*x1*x2 + 3*x1 + 4*x2 + 5
c2 = add_const(mgr, 2.0)
c3 = add_const(mgr, 3.0)
c4 = add_const(mgr, 4.0)
c5 = add_const(mgr, 5.0)

g = add_plus(mgr,
    add_plus(mgr,
        add_plus(mgr,
            add_times(mgr, c2, add_times(mgr, x1, x2)),
            add_times(mgr, c3, x1)),
        add_times(mgr, c4, x2)),
    c5)
```

### Subtraction

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# f(x1, x2) = x1 - x2
f = add_minus(mgr, x1, x2)

# Can be negative: returns -1 if x1=0, x2=1
```

### Division

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)
c2 = add_const(mgr, 2.0)

# f(x1) = x1 / 2
f = add_divide(mgr, x1, c2)

# Note: Division by zero returns infinity
```

## Min/Max Operations

### Minimum

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# f(x1, x2) = min(x1, x2)
f = add_min(mgr, x1, x2)

# With constants: g(x1, x2) = min(5, 3*x1 + 2*x2)
c5 = add_const(mgr, 5.0)
c3 = add_const(mgr, 3.0)
c2 = add_const(mgr, 2.0)

expr = add_plus(mgr, add_times(mgr, c3, x1), add_times(mgr, c2, x2))
g = add_min(mgr, c5, expr)
```

### Maximum

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# f(x1, x2) = max(x1, x2)
f = add_max(mgr, x1, x2)

# Clamping: g(x) = max(0, min(x, 1))
c0 = add_const(mgr, 0.0)
c1 = add_const(mgr, 1.0)
g = add_max(mgr, c0, add_min(mgr, x1, c1))
```

## Evaluation

Evaluate an ADD with specific variable assignments:

```julia
mgr = DDManager(3)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)
x3 = add_ith_var(mgr, 3)

# f(x1, x2, x3) = 2*x1 + 3*x2 + 4*x3
c2 = add_const(mgr, 2.0)
c3 = add_const(mgr, 3.0)
c4 = add_const(mgr, 4.0)

f = add_plus(mgr,
    add_plus(mgr,
        add_times(mgr, c2, x1),
        add_times(mgr, c3, x2)),
    add_times(mgr, c4, x3))

# Evaluate with x1=1, x2=1, x3=1
assignment = Dict(1 => 1.0, 2 => 1.0, 3 => 1.0)
result = add_eval(mgr, f, assignment)  # 9.0

# Evaluate with x1=1, x2=0, x3=1
assignment = Dict(1 => 1.0, 2 => 0.0, 3 => 1.0)
result = add_eval(mgr, f, assignment)  # 6.0

# Evaluate with x1=0, x2=0, x3=0
assignment = Dict(1 => 0.0, 2 => 0.0, 3 => 0.0)
result = add_eval(mgr, f, assignment)  # 0.0
```

## Converting Between BDDs and ADDs

### BDD to ADD

Convert a BDD to an ADD (0-1 function):

```julia
mgr = DDManager(2)

# Create BDD
x1_bdd = ith_var(mgr, 1)
x2_bdd = ith_var(mgr, 2)
f_bdd = bdd_and(mgr, x1_bdd, x2_bdd)

# Convert to ADD
f_add = bdd_to_add(mgr, f_bdd)

# Now can use arithmetic operations
c2 = add_const(mgr, 2.0)
g = add_times(mgr, c2, f_add)  # 2 if both true, 0 otherwise
```

### ADD to BDD

Convert an ADD to a BDD (threshold operation):

```julia
mgr = DDManager(2)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)

# f(x1, x2) = x1 + x2
f = add_plus(mgr, x1, x2)

# Convert to BDD: true if f > 0
f_bdd = add_to_bdd(mgr, f)

# This is equivalent to x1 ∨ x2
x1_bdd = ith_var(mgr, 1)
x2_bdd = ith_var(mgr, 2)
expected = bdd_or(mgr, x1_bdd, x2_bdd)
@assert f_bdd == expected
```

## Applications

### Probability Calculations

```julia
mgr = DDManager(3)

# Independent events with probabilities
# P(A) = 0.7, P(B) = 0.5, P(C) = 0.3
p_a = add_const(mgr, 0.7)
p_b = add_const(mgr, 0.5)
p_c = add_const(mgr, 0.3)

# Complement probabilities
p_not_a = add_const(mgr, 0.3)
p_not_b = add_const(mgr, 0.5)
p_not_c = add_const(mgr, 0.7)

# Variables
a = add_ith_var(mgr, 1)
b = add_ith_var(mgr, 2)
c = add_ith_var(mgr, 3)

# P(A ∧ B ∧ C) = P(A) * P(B) * P(C)
# Build probability function
prob_a = add_plus(mgr,
    add_times(mgr, a, p_a),
    add_times(mgr, add_minus(mgr, add_const(mgr, 1.0), a), p_not_a))

prob_b = add_plus(mgr,
    add_times(mgr, b, p_b),
    add_times(mgr, add_minus(mgr, add_const(mgr, 1.0), b), p_not_b))

prob_c = add_plus(mgr,
    add_times(mgr, c, p_c),
    add_times(mgr, add_minus(mgr, add_const(mgr, 1.0), c), p_not_c))

# Joint probability
joint = add_times(mgr, add_times(mgr, prob_a, prob_b), prob_c)

# Evaluate: P(A=true, B=true, C=true)
assignment = Dict(1 => 1.0, 2 => 1.0, 3 => 1.0)
p_all_true = add_eval(mgr, joint, assignment)  # 0.105
```

### Weighted Counting

```julia
mgr = DDManager(3)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)
x3 = add_ith_var(mgr, 3)

# Weights for each variable
w1 = add_const(mgr, 2.0)
w2 = add_const(mgr, 3.0)
w3 = add_const(mgr, 5.0)

# Total weight: 2*x1 + 3*x2 + 5*x3
total_weight = add_plus(mgr,
    add_plus(mgr,
        add_times(mgr, w1, x1),
        add_times(mgr, w2, x2)),
    add_times(mgr, w3, x3))

# Constraint: at least two variables must be true
x1_bdd = ith_var(mgr, 1)
x2_bdd = ith_var(mgr, 2)
x3_bdd = ith_var(mgr, 3)

at_least_two = bdd_or(mgr,
    bdd_or(mgr,
        bdd_and(mgr, x1_bdd, x2_bdd),
        bdd_and(mgr, x1_bdd, x3_bdd)),
    bdd_and(mgr, x2_bdd, x3_bdd))

# Convert constraint to ADD
constraint_add = bdd_to_add(mgr, at_least_two)

# Apply constraint: weight if constraint satisfied, 0 otherwise
constrained_weight = add_times(mgr, total_weight, constraint_add)

# Find maximum weight satisfying constraint
# (Would need to enumerate all assignments)
```

### Optimization

```julia
mgr = DDManager(3)
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)
x3 = add_ith_var(mgr, 3)

# Objective function: maximize 5*x1 + 3*x2 + 2*x3
c5 = add_const(mgr, 5.0)
c3 = add_const(mgr, 3.0)
c2 = add_const(mgr, 2.0)

objective = add_plus(mgr,
    add_plus(mgr,
        add_times(mgr, c5, x1),
        add_times(mgr, c3, x2)),
    add_times(mgr, c2, x3))

# Constraint: x1 + x2 + x3 <= 2
sum_vars = add_plus(mgr, add_plus(mgr, x1, x2), x3)
c2_const = add_const(mgr, 2.0)

# Check all assignments to find maximum
max_value = -Inf
best_assignment = nothing

for x1_val in [0.0, 1.0]
    for x2_val in [0.0, 1.0]
        for x3_val in [0.0, 1.0]
            assignment = Dict(1 => x1_val, 2 => x2_val, 3 => x3_val)

            # Check constraint
            sum_val = add_eval(mgr, sum_vars, assignment)
            if sum_val <= 2.0
                # Evaluate objective
                obj_val = add_eval(mgr, objective, assignment)
                if obj_val > max_value
                    max_value = obj_val
                    best_assignment = assignment
                end
            end
        end
    end
end

println("Maximum value: ", max_value)  # 10.0
println("Best assignment: ", best_assignment)  # x1=1, x2=1, x3=0
```

## Performance Tips

### 1. Use Constants Efficiently

```julia
mgr = DDManager(10)

# Good: Create constant once
c2 = add_const(mgr, 2.0)
results = [add_times(mgr, c2, add_ith_var(mgr, i)) for i in 1:10]

# Bad: Create constant repeatedly
results = [add_times(mgr, add_const(mgr, 2.0), add_ith_var(mgr, i)) for i in 1:10]
```

### 2. Build Incrementally

```julia
mgr = DDManager(5)
vars = [add_ith_var(mgr, i) for i in 1:5]

# Good: Build incrementally
result = vars[1]
for i in 2:5
    result = add_plus(mgr, result, vars[i])
end

# Also good: Use reduce
result = reduce((acc, v) -> add_plus(mgr, acc, v), vars)
```

### 3. Avoid Unnecessary Conversions

```julia
mgr = DDManager(3)

# Good: Work in ADD domain
x1 = add_ith_var(mgr, 1)
x2 = add_ith_var(mgr, 2)
result = add_plus(mgr, x1, x2)

# Bad: Unnecessary conversions
x1_bdd = ith_var(mgr, 1)
x1_add = bdd_to_add(mgr, x1_bdd)  # Unnecessary
```

## Limitations

### No Complement Edges

Unlike BDDs, ADDs don't use complement edges:
- Negation requires explicit computation
- May result in larger diagrams
- But allows arbitrary real values

### Numerical Precision

ADDs use floating-point arithmetic:
- Subject to rounding errors
- Equality comparisons may be inexact
- Consider using tolerance for comparisons

```julia
mgr = DDManager(2)
x = add_ith_var(mgr, 1)

# May not be exactly equal due to floating point
c1 = add_const(mgr, 0.1)
c2 = add_const(mgr, 0.2)
c3 = add_const(mgr, 0.3)

sum = add_plus(mgr, c1, c2)
# sum might not exactly equal c3 due to floating point
```

## See Also

- [BDD Guide](bdds.md): Binary Decision Diagrams
- [ZDD Guide](zdds.md): Zero-suppressed Decision Diagrams
- [API Reference](@ref): Complete API documentation
