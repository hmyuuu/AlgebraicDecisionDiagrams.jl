# Documentation

This directory contains the documentation for AlgebraicDecisionDiagrams.jl using Documenter.jl.

## Building the Documentation

To build the documentation locally:

```bash
# From the repository root
cd docs

# Install dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Build the documentation
julia --project=. make.jl
```

The generated documentation will be in `docs/build/`.

## Viewing the Documentation

After building, open `docs/build/index.html` in your browser:

```bash
open build/index.html  # macOS
xdg-open build/index.html  # Linux
start build/index.html  # Windows
```

## Documentation Structure

- `src/index.md` - Home page
- `src/getting_started.md` - Installation and basic usage
- `src/guide/` - Detailed user guides
  - `bdds.md` - Binary Decision Diagrams
  - `adds.md` - Algebraic Decision Diagrams
  - `zdds.md` - Zero-suppressed Decision Diagrams
  - `utilities.md` - Utility functions
- `src/performance.md` - Performance characteristics
- `src/comparison.md` - Comparison with CUDD
- `src/api.md` - API reference
- `src/internals.md` - Implementation details

## Deploying Documentation

To deploy to GitHub Pages:

```bash
julia --project=. -e 'using Pkg; Pkg.add("DocumenterTools")'
julia --project=. -e 'using DocumenterTools; DocumenterTools.genkeys()'
```

Then add the generated key to your GitHub repository settings and push to trigger deployment.

## Contributing

When adding new features:
1. Update the relevant guide in `src/guide/`
2. Add API documentation in `src/api.md`
3. Include examples in the guides
4. Rebuild and verify the documentation

## Notes

- Documentation uses Documenter.jl
- Markdown files use CommonMark syntax
- Code blocks are automatically syntax highlighted
- `@docs` blocks pull docstrings from source code
