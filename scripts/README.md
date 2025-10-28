# Build & Dependency Management Scripts

This directory contains scripts for managing Nix package dependencies and analyzing the build.

## Dependency Analysis Scripts

### `analyze-dependencies-recursive.sh`
**Purpose**: Analyzes all `.cabal` files in the workspace to find direct dependencies.

**What it does**:
- Scans all `.cabal` files (backend, frontend, common, etc.)
- Extracts all `build-depends` entries
- Categorizes them as: defined in overlay, missing, standard libraries, or our own packages
- Generates `docs/recursive-dependency-analysis.md` with findings

**When to use**:
- Before starting a build to proactively find missing dependencies
- After adding new dependencies to .cabal files
- To understand the complete dependency tree

**Usage**:
```bash
./scripts/analyze-dependencies-recursive.sh
# Results written to: docs/recursive-dependency-analysis.md
```

### `check-cabal-dependencies.sh`
**Purpose**: Similar to `analyze-dependencies-recursive.sh` but with more detailed output.

**What it does**:
- Parses all `.cabal` files for dependencies
- Checks each against the Nix overlay
- Generates `docs/cabal-dependency-analysis.md`

**Usage**:
```bash
./scripts/check-cabal-dependencies.sh
# Results written to: docs/cabal-dependency-analysis.md
```

### `check-packages.sh`
**Purpose**: Verifies if packages exist in Hackage/all-cabal-hashes.

**What it does**:
- Takes a list of package names
- Checks if they exist in all-cabal-hashes repository
- Reports which packages are available and which are missing

**When to use**:
- Before adding packages via `callHackage`
- To verify package names are correct
- To check if a package needs to come from GitHub instead

**Usage**:
```bash
./scripts/check-packages.sh
# Interactive: Enter package names when prompted
```

### `verify-github-packages.sh`
**Purpose**: Focused verification of known problematic packages that come from GitHub.

**What it does**:
- Checks specific packages that are known to need GitHub sources
- Verifies the packages we've already added with `fetchFromGitHub`

**Usage**:
```bash
./scripts/verify-github-packages.sh
```

## Dependency Addition Scripts

### `add-missing-dependencies.sh`
**Purpose**: Adds missing dependencies found by analysis to the Nix overlay.

**What it does**:
- Reads findings from dependency analysis
- Adds package definitions to `cardano-project/cardano-overlays/cardano-packages/default.nix`
- Handles packages from:
  - Existing thunks (aeson-gadt-th, reflex, etc.)
  - Monorepo subpackages (obelisk-*, rhyolite-*)
- Provides guidance on remaining Hackage packages

**When to use**:
- After running dependency analysis
- Before attempting a build with missing dependencies

**Usage**:
```bash
# Review the script first!
cat ./scripts/add-missing-dependencies.sh

# Then run:
./scripts/add-missing-dependencies.sh
```

**⚠️ Warning**: This modifies `default.nix`. Review changes before committing.

## Workflow

### Recommended workflow for adding dependencies:

1. **Analyze dependencies**:
   ```bash
   ./scripts/analyze-dependencies-recursive.sh
   ```

2. **Review findings**:
   ```bash
   cat docs/recursive-dependency-analysis.md
   ```

3. **Add thunk-based packages**:
   ```bash
   ./scripts/add-missing-dependencies.sh
   ```

4. **For remaining Hackage packages**:
   - Check they exist: `./scripts/check-packages.sh`
   - Add to overlay manually with `callHackage` or `callHackageDirect`

5. **Test build**:
   ```bash
   ./build-in-docker.sh > build-in-docker.log 2>&1 &
   tail -f build-in-docker.log
   ```

6. **If build fails with "called without required argument X"**:
   - Add package X to overlay
   - Repeat from step 5

## Related Documentation

- `docs/DEPENDENCY-ANALYSIS.md` - Comprehensive dependency analysis results
- `docs/recursive-dependency-analysis.md` - Categorized dependency report
- `docs/cabal-dependency-analysis.md` - Detailed cabal-based analysis
- `docs/nix-docker-troubleshooting.md` - Docker build troubleshooting

## Notes

- All scripts assume they're run from the repository root
- Scripts are safe to run multiple times (they don't modify files except `add-missing-dependencies.sh`)
- The analysis scripts are read-only and generate reports in `docs/`
