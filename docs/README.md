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

### Automatic Deployment

Documentation is automatically built and deployed to GitHub Pages when:
- Code is pushed to the `main` branch
- A new tag is created
- The workflow is manually triggered from the Actions tab

### Setting up GitHub Pages

To enable the published documentation website:

1. Go to your repository on GitHub: https://github.com/hmyuuu/AlgebraicDecisionDiagrams.jl
2. Click on **Settings** tab
3. Navigate to **Pages** in the left sidebar (under "Code and automation")
4. Under **Source**, select **Deploy from a branch**
5. Select the **gh-pages** branch from the dropdown
6. Select **/ (root)** as the folder
7. Click **Save**

After a few minutes, your documentation will be available at:
**https://hmyuuu.github.io/AlgebraicDecisionDiagrams.jl/**

### How Deployment Works

The `.github/workflows/Documentation.yml` workflow:
1. Builds documentation using Documenter.jl
2. Pushes the generated HTML to the `gh-pages` branch  
3. Ensures a `.nojekyll` file exists to prevent Jekyll processing
4. GitHub Pages then serves the content from the `gh-pages` branch

### Troubleshooting

If documentation isn't showing up:
- Verify GitHub Pages is enabled in Settings → Pages
- Check that source is set to `gh-pages` branch
- Wait 2-3 minutes after workflow completes for Pages to update
- Check the Actions tab for any workflow errors

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
