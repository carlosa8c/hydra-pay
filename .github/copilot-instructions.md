# Hydra Pay Build Context for GitHub Copilot

## Project Goals

### Goal 1: Update Packages and Dependencies
- Keep all Haskell packages and dependencies updated to their latest viable versions
- Use Hackage, GitHub releases, and all-cabal-hashes to verify actual available versions
- **NEVER guess package versions** - always check online first using fetch_webpage
- **NEVER guess package paths** - always verify thunk paths exist before adding packages
- When fetching from GitHub directly, use nix-prefetch-url to get correct SHA256 hashes
- Prioritize stability over bleeding edge - use released tags when available

### Goal 2: Get Build Working with Latest Packages
- Ensure `./build-in-docker.sh` succeeds consistently
- Build must work across macOS, Linux, and CI environments
- Fix dependency resolution issues as they arise
- Update Nix overlays and package definitions as needed

## Current Build Environment

### Docker Setup
- **Host**: macOS (Apple Silicon)
- **Container**: nixos/nix:latest (linux/amd64)
- **Build Script**: `./build-in-docker.sh` → `.ci/inner-build.sh` → `nix-build`
- **Persistent Volumes**: 
  - `hydrapay-nix:/nix` (Nix store)
  - `hydrapay-nix-cache:/root/.cache/nix` (cache)
- **Security**: `--security-opt seccomp=unconfined` (required for macOS)
- **Sandbox**: Disabled (`sandbox = false` in NIX_CONFIG)

### Key Files
- **Build orchestration**: `build-in-docker.sh`, `.ci/inner-build.sh`
- **Main Nix config**: `cardano-project/default.nix`
- **Cardano packages overlay**: `cardano-project/cardano-overlays/cardano-packages/default.nix`
- **Dependency pins**: Multiple `thunk.nix` files throughout project
- **Build log**: `build-in-docker.log` (check with `tail -f` or `strings` for binary content)

## Current Issue: Cabal Version Mismatch

### Problem
The latest versions of some packages (like cuddle) use `cabal-version: 3.4` which is not supported by the cabal2nix version in the current nixos/nix image.

### Error Pattern
```
*** cannot parse "/nix/store/.../cuddle.cabal":
Unsupported cabal-version 3.4. See https://github.com/haskell/cabal/issues/4899.
```

### Options to Consider
1. **Use older package versions** that have cabal-version ≤ 3.0
2. **Upgrade Nix environment** to support cabal-version 3.4
3. **Switch Docker base image** to one with newer cabal2nix
4. **Build from source repos** instead of using cabal2nix for problematic packages

## Package Update Workflow

### Package Source Decision Tree

**Use this workflow to determine where to get each package:**

1. **First, try `callHackage`** (preferred for stability)
   - Try building with `callHackage`
   - If it works, keep it (most older/stable packages are in all-cabal-hashes)
   
2. **If `callHackage` fails with "Not found in archive":**
   - Package version is not in all-cabal-hashes (sync lag)
   - Switch to `fetchFromGitHub` approach below
   
3. **If package doesn't exist on GitHub:**
   - Set to `null` with explanatory comment
   - Document in package notes

**all-cabal-hashes limitations:**
- Has significant sync lag (weeks to months for new releases)
- Missing many new IOHK/Cardano packages (cuddle, ImpSpec, FailT, mempack, etc.)
- Missing packages not in Stackage/LTS
- Recent versions (< 6 months old) often not synced yet

**When to use GitHub (`fetchFromGitHub`):**
- Package version not found in all-cabal-hashes
- New IOHK/Cardano packages
- Very recent package versions
- Packages with cabal-version >= 3.4 (if cabal2nix doesn't support it)

### Step 1: Verify Version Exists on Hackage
```
1. Use fetch_webpage to check Hackage: https://hackage.haskell.org/package/{package}
2. Note all available versions and their release dates
3. Check cabal-version requirement (if >= 3.4, may need special handling)
4. IMPORTANT: Hackage existence doesn't guarantee all-cabal-hashes availability!
```

### Step 2: Try callHackage First (Test During Build)
```
1. Add package with callHackage using verified Hackage version
2. Start build and watch for "Not found in archive" errors
3. If it works: keep callHackage (stable, well-tested approach)
4. If it fails: proceed to Step 3 (GitHub approach)
```

### Step 3: Get Package from GitHub (Only if callHackage Failed)
```
ONLY use this if Step 2 (callHackage) failed with "Not found in archive"

1. Check releases/tags: https://github.com/{owner}/{repo}/tags
2. Find tag matching desired version (e.g., "v0.1.1" or "0.1")
3. Get commit hash from tag page
4. Fetch SHA256 hash:
   docker run --rm nixos/nix:latest nix-prefetch-url --unpack https://github.com/{owner}/{repo}/archive/refs/tags/{tag}.tar.gz
5. Update package definition to use fetchFromGitHub (see Step 4)
```

### Step 4: Update Package Definition
```nix
# If callHackage worked (Step 2 succeeded):
package = haskellLib.dontCheck (self.callHackage "package" "version" {});

# If callHackage failed (Step 2 failed, using GitHub from Step 3):
# IMPORTANT: Check if repository is a monorepo (has subdirectories with .cabal files)
# If monorepo, use callCabal2nixWithOptions with --subpath:
package = haskellLib.dontCheck (self.callCabal2nixWithOptions "package" (pkgs.fetchFromGitHub {
  owner = "owner";
  repo = "repo";
  rev = "commit-hash-from-tag";  # use full commit hash, not tag name
  sha256 = "actual-hash-from-nix-prefetch";
}) "--subpath package-directory" {});

# If NOT a monorepo (single package in root):
package = haskellLib.dontCheck (self.callCabal2nix "package" (pkgs.fetchFromGitHub {
  owner = "owner";
  repo = "repo";
  rev = "commit-hash-from-tag";  # use full commit hash, not tag name
  sha256 = "actual-hash-from-nix-prefetch";
}) {});

# If package doesn't exist anywhere:
package = null;  # Explain why in comment
```

### Known Monorepo Packages Requiring --subpath
- **dependent-sum**: subdirectory `dependent-sum/`
- **gargoyle**: subdirectories `gargoyle/`, `gargoyle-postgresql/`, `gargoyle-postgresql-nix/`, `gargoyle-postgresql-connect/`
- **uuid**: subdirectory `uuid/`
- **obelisk**: subdirectories `lib/backend/`, `lib/frontend/`, `lib/route/`, `lib/executable-config/lookup/`
- **rhyolite**: subdirectories `beam/db/`, `beam/task/backend/`, `beam/task/types/`

### Step 5 (cardano-ledger packages only): Verify Thunk Paths
```
For packages from deps.cardano-ledger thunk:
1. Read thunk's github.json to get commit hash
2. Use fetch_webpage to check GitHub: https://github.com/IntersectMBO/cardano-ledger/tree/{commit-hash}/libs
3. Verify directory exists (e.g., /libs/cardano-ledger-core)
4. If path doesn't exist, set package to null - don't guess!
```

### Step 5 (cardano-ledger packages only): Verify Thunk Paths
```
For packages from deps.cardano-ledger thunk:
1. Read thunk's github.json to get commit hash
2. Use fetch_webpage to check GitHub: https://github.com/IntersectMBO/cardano-ledger/tree/{commit-hash}/libs
3. Verify directory exists (e.g., /libs/cardano-ledger-core)
4. If path doesn't exist, set package to null - don't guess!
```

### Step 6: Test Build
```bash
./build-in-docker.sh > build-in-docker.log 2>&1 &
# Wait for completion, then:
tail -100 build-in-docker.log | strings
```

## Troubleshooting Common Errors

### "function 'anonymous lambda' called without required argument 'X'"
- **Cause**: Missing Haskell package dependency
- **Fix**: Add package definition to `cardano-project/cardano-overlays/cardano-packages/default.nix`

### "tar: */package/version/package.cabal: Not found in archive"
- **Cause**: Version doesn't exist in all-cabal-hashes
- **Fix**: Use different version or fetch from GitHub

### "Unsupported cabal-version X.Y"
- **Cause**: Package requires newer Cabal than available in Nix environment
- **Fix**: Use older package version or upgrade Nix environment

### "Cannot build X.drv. Reason: 1 dependency failed"
- **Cause**: Earlier dependency in chain failed
- **Fix**: Search log with `strings build.log | grep -B 10 "building.*X.drv"` to find root cause

## Package Categories in This Project

### Cardano Development Eras (Historical Context)
Understanding Cardano's evolution helps identify legacy vs. active packages:

1. **Byron** (2017-2020) - Original/legacy era
2. **Shelley** (2020) - Decentralization introduced
3. **Allegra** (Dec 2020) - Token locking
4. **Mary** (Mar 2021) - Multi-asset support
5. **Alonzo** (Sep 2021) - Smart contracts (Plutus)
6. **Babbage** (Sep 2022) - Plutus V2, reference inputs
7. **Conway** (2023+) - Voltaire governance era

**Shelley-MA**: "Shelley Multi-Asset" - transitional name for Allegra+Mary period.

**Package implications**:
- Byron and Shelley-MA packages may not exist in modern cardano-ledger (restructured/deprecated)
- If path like `/eras/byron/ledger/impl/test` or `/eras/shelley-ma/impl` doesn't exist, set to `null`
- Current focus: Babbage/Conway era packages for modern Cardano

### Cardano Ledger Packages
Located in cardano-ledger repo under `/eras/` and `/libs/`:
- Era packages: shelley, allegra, mary, alonzo, babbage, conway
- Lib packages: core, api, binary, pretty, protocol-tpraos, etc.
- Legacy: byron-test, shelley-ma (may not exist in newer thunks)

### Support Libraries
- **cuddle**: CDDL generator (currently problematic due to cabal-version 3.4)
- **FailT**: Monad transformer for failure handling
- **mempack**: Memory-efficient serialization
- **ImpSpec**: Imperative specification testing
- **compact-map**: Compact map implementation
- **transformers-except**: Exception transformers

## Build Iteration Speed

### Current Approach (Docker)
- ✅ Pros: Cross-platform consistency, matches CI
- ❌ Cons: Slow iteration (minutes per attempt)
- Volumes help but initial unpacking stages still slow

### Alternative (Not Currently Used)
Interactive container with live editing - could speed up iteration but user wants to keep Docker workflow for future compatibility.

## Important Rules

1. **Never guess versions** - always verify online
2. **Always get SHA256 hashes** when using fetchFromGitHub
3. **Check cabal-version compatibility** before using latest package versions
4. **Document reasoning** in comments when making version choices
5. **Test incrementally** - one package fix at a time when possible
6. **Keep build logs** - use `strings` command to read binary log content

## Next Steps When Resuming

1. Check latest build error: `tail -50 build-in-docker.log | strings`
2. Identify missing package or version issue
3. Research available versions online
4. Update package definition with verified version/hash
5. Restart build and monitor progress
6. Repeat until build succeeds
