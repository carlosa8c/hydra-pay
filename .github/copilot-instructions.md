# Hydra Pay Build Context for GitHub Copilot

## ⚠️ MIGRATION IN PROGRESS: reflex-platform → haskell.nix

**Current Status**: Actively migrating from reflex-platform to haskell.nix
- **From**: GHC 8.10.7, reflex-platform, Obelisk framework
- **To**: GHC 9.6.7, haskell.nix, CHaP (Cardano Haskell Packages)
- **Reason**: Obelisk no longer maintained, need modern GHC for cabal-version 3.4+ support

### Migration Progress
- ✅ Removed Obelisk from Haskell code (Backend.hs, routing)
- ✅ Updated cardano-project/default.nix to use haskell.nix
- ✅ Set compiler to GHC 9.6.7 (ghc967)
- ✅ Added CHaP repository for Cardano packages
- ✅ Updated cardano-node to 10.4.1, hydra to 1.1.0
- ✅ **RESOLVED**: strict-stm dependency incompatibility
  - CHaP was providing io-classes 1.8.0.1 with new InspectMonadSTM API
  - Solution: Override via `cabal.project` source-repository-package (takes precedence over CHaP)
  - Now using io-sim commit b61e23a (Nov 8, 2023) with io-classes 1.3.0.0
- ✅ Defined custom thunkSet function (replaces reflex-platform's thunkSet)
- 🔄 Build successfully compiling packages (first time past dependency resolution!)
- ⏳ Waiting for build completion or GHC 9.6.7 compilation errors

### Critical Lesson: Overriding CHaP Packages
**The ONLY way to override CHaP packages in haskell.nix:**

Use `cabal.project` source-repository-package entries. This is read by haskell.nix and takes precedence over CHaP.

```haskell
-- In cabal.project:
source-repository-package
  type: git
  location: https://github.com/input-output-hk/io-sim
  tag: b61e23a219c5ae113ff9a43f89b4451c8fe2f353
  --sha256: 1BwQ7dfXCYMg/Pl5Vvl1L7kXlPfWNl9dRZiLZru3UU0=
  subdir:
    io-sim
    io-classes
    strict-stm
    strict-mvar
    si-timers
```

**DO NOT** use `packages.*.src` in haskell.nix modules - this conflicts with cabal.project and causes errors.

**DO** use modules for configuration only:
```nix
modules = [
  {
    # Disable tests
    packages.io-classes.doCheck = false;
    packages.strict-stm.doCheck = false;
  }
]
```

### Known Issues
1. ~~**haskell.nix Package Overrides**: CHaP packages take precedence over local thunk definitions~~ ✅ SOLVED
   - ~~Solution: Use `packages.*.src` overrides in haskell.nix modules~~ **WRONG APPROACH**
   - **CORRECT**: Use cabal.project source-repository-package entries
2. ✅ **thunkSet missing**: reflex-platform's thunkSet not available in haskell.nix
   - Solution: Define custom thunkSet using fetchFromGitHub (implemented)
3. ✅ **Hash mismatches**: SHA256 hashes need recalculation when updating thunks
   - Use: `nix-prefetch-url --unpack https://github.com/...`
   - Note: Use base64 format (sha256-...), not nix32 format

## Project Goals

### Goal 1: Complete Migration to haskell.nix
- Get build working with GHC 9.6.7 and haskell.nix
- Properly override CHaP packages with local thunks when needed
- Fix io-sim/strict-stm version compatibility (use Nov 2023 version with old API)
- Support cabal-version 3.4+ packages (lsm-tree, bloomfilter-blocked, etc.)

### Goal 2: Update Packages and Dependencies
- Keep all Haskell packages and dependencies updated to their latest viable versions
- Use CHaP, Hackage, and GitHub to source packages
- **NEVER guess package versions** - always check online first using fetch_webpage
- **NEVER guess package paths** - always verify thunk paths exist before adding packages
- When fetching from GitHub directly, use nix-prefetch-url to get correct SHA256 hashes
- Prioritize stability over bleeding edge - use released tags when available

## Current Build Environment

### Thunk Path References (CRITICAL)
**IMPORTANT**: In `cardano-project/cardano-overlays/cardano-packages/default.nix`:
- `deps` refers to `cardano-project/cardano-overlays/cardano-packages/dep/`
- `parentDeps` refers to `cardano-project/dep/`
- `topLevelDeps` refers to `/dep/` (workspace root)

**Never forget**: When you see `deps.io-sim`, it's `cardano-project/cardano-overlays/cardano-packages/dep/io-sim`, NOT `/dep/io-sim`!

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
- **Main Nix config**: `cardano-project/default.nix` (uses haskell.nix, GHC 9.6.7)
- **Cardano packages overlay**: `cardano-project/cardano-overlays/cardano-packages/default.nix`
- **Dependency pins**: Multiple `github.json` files in thunk directories
- **Build log**: `build-in-docker.log` (check with `tail -f` or `strings` for binary content)

## haskell.nix Package Management

### How haskell.nix Works (Different from reflex-platform)
- **CHaP (Cardano Haskell Packages)**: Primary repository for Cardano packages
  - Configured via `inputMap` in haskell.nix project
  - Takes precedence over Hackage for Cardano packages
  - URL: https://intersectmbo.github.io/cardano-haskell-packages
- **Package Resolution Order**: cabal.project source-repository-package → CHaP → Hackage
- **Key Insight**: haskell.nix reads `cabal.project` and source-repository-package entries take precedence over CHaP
- **Solution for overrides**: Use `cabal.project` source-repository-package entries (NOT haskell.nix modules)

### Overriding CHaP Packages: The Correct Way
**Use `cabal.project` source-repository-package entries:**

```haskell
-- In cabal.project at workspace root:
source-repository-package
  type: git
  location: https://github.com/input-output-hk/io-sim
  tag: b61e23a219c5ae113ff9a43f89b4451c8fe2f353
  --sha256: 1BwQ7dfXCYMg/Pl5Vvl1L7kXlPfWNl9dRZiLZru3UU0=
  subdir:
    io-sim
    io-classes
    strict-stm
    strict-mvar
    si-timers
```

**Why this works:**
- haskell.nix reads cabal.project during plan generation
- source-repository-package entries are resolved BEFORE CHaP
- This is the standard Cabal way to override package sources
- No conflicts with haskell.nix internals

### What NOT to Do
**DO NOT use `packages.*.src` in haskell.nix modules:**

```nix
# ❌ WRONG - causes conflicts with cabal.project
modules = [
  {
    packages.strict-stm.src = pkgs.haskell-nix.haskellLib.cleanGit {
      name = "strict-stm";
      src = cardanoPackageDeps.io-sim + "/strict-stm";
    };
  }
]
```

This conflicts with cabal.project and causes "conflicting definition values" errors.

### What to Use haskell.nix Modules For
**DO use modules for package configuration (not sources):**

```nix
# ✅ CORRECT - configuration only
modules = [
  {
    # Disable tests
    packages.io-classes.doCheck = false;
    packages.strict-stm.doCheck = false;
    packages.strict-mvar.doCheck = false;
    
    # Other configuration
    packages.some-package.flags.some-flag = true;
  }
]
```

### Loading Git Thunks (Custom thunkSet)
reflex-platform's `thunkSet` is not available. Define manually:
```nix
thunkSet = dir: lib.mapAttrs (name: _:
  let thunkData = builtins.fromJSON (builtins.readFile (dir + "/${name}/github.json"));
  in pkgs.fetchFromGitHub {
    owner = thunkData.owner or (throw "thunk ${name} missing owner");
    repo = thunkData.repo or (throw "thunk ${name} missing repo");
    rev = thunkData.rev;
    sha256 = thunkData.sha256;
  }
) (builtins.readDir dir);
```

## Current Issue: strict-stm Dependency Incompatibility

### GHC 9.6.7 Migration Context
- **GHC 9.6.7 ships with Cabal 3.10+** - CAN parse cabal-version 3.4
- **This is why we're upgrading** - to support modern Cardano packages
- **Old limitation (GHC 8.10.7)**: Could only parse cabal-version up to 3.0

### The strict-stm Problem

### The strict-stm Problem
- **InspectMonad → InspectMonadSTM API rename** in io-classes (May 7, 2024, commit 5863917)
- **CHaP provides**: strict-stm 1.5.0.0 from Hackage (uses OLD InspectMonad API)
- **But CHaP also has**: io-classes 1.8.0.1 (has NEW InspectMonadSTM API)
- **Result**: Incompatibility - strict-stm 1.5.0.0 can't compile with io-classes 1.8.0.1

### Solution: Use io-sim thunk from November 2023
- **Commit**: b61e23a219c5ae113ff9a43f89b4451c8fe2f353 (Nov 8, 2023)
- **Version**: strict-stm 1.3.0.0, io-classes 1.3.x
- **Why**: This version has standalone strict-stm/strict-mvar packages with InspectMonad API
- **Location**: `cardano-project/cardano-overlays/cardano-packages/dep/io-sim/`
- **Override method**: Use haskell.nix modules to force src from thunk

### Migration Steps Needed
1. ✅ Define thunkSet function (replaces reflex-platform thunkSet)
2. 🚧 Fix SHA256 hash in io-sim thunk's github.json
3. 🚧 Configure haskell.nix modules to override strict-stm/strict-mvar/io-classes/io-sim
4. ⏳ Fix remaining GHC 9.6.7 compilation errors

## Package Update Workflow (haskell.nix Context)

### Package Source Priority
1. **CHaP** (Cardano packages) - checked first for Cardano ecosystem
2. **Hackage** - standard Haskell packages
3. **Local thunks** - must be explicitly configured via haskell.nix modules

### When to Override with Local Thunks
- Package has API incompatibility with CHaP version
- Need specific commit not published to CHaP/Hackage
- Testing unreleased features
- Working around CHaP sync lag

### Package Update Decision Tree (GHC 9.6.7)
1. **Check CHaP first** for Cardano packages
   - Browse: https://github.com/IntersectMBO/cardano-haskell-packages
   - Or: `nix-build` will try CHaP automatically
2. **If CHaP version incompatible**: Override with local thunk
3. **For non-Cardano packages**: Use Hackage (via haskell.nix)
4. **If not in Hackage**: Fetch from GitHub

### Known Packages Requiring Thunk Overrides
- **io-classes**: Use thunk (Nov 2023) for InspectMonad compatibility
- **io-sim**: Use thunk (Nov 2023) for InspectMonad compatibility  
- **strict-stm**: Use thunk (Nov 2023) for InspectMonad compatibility
- **strict-mvar**: Use thunk (Nov 2023) for InspectMonad compatibility

### Proactive cabal-version Checking (GHC 9.6.7)

### Proactive cabal-version Checking (GHC 9.6.7)
**GHC 9.6.7 supports cabal-version up to 3.10** (ships with Cabal 3.10)
- Most modern packages (cabal-version 3.4) are now compatible
- Still check for very new cabal-version requirements (> 3.10)
- Old restriction (GHC 8.10.7 / Cabal 3.2) no longer applies

**For packages requiring cabal-version > 3.10:**
1. Check if newer GHC needed (9.8+, 9.10+)
2. Set to `null` with explanation if incompatible
3. Document upgrade path

### Error Patterns

#### Hash Mismatch in Thunk
```
error: hash mismatch in fixed-output derivation '/nix/store/.../source.drv':
  specified: sha256-...
       got: sha256-...
```
**Fix**: Update `sha256` in `github.json` using nix-prefetch-url

#### CHaP Package Override Not Working
```
building strict-stm-1.5.0.0 (from CHaP/Hackage instead of thunk)
```
**Fix**: Add package.*.src override in haskell.nix modules

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

### Step 1: Check Package Source (haskell.nix)
```
1. For Cardano packages: Check CHaP first
   - Browse: https://github.com/IntersectMBO/cardano-haskell-packages
   - CHaP syncs from Hackage + Cardano repos
2. For general Haskell packages: Use Hackage
   - URL: https://hackage.haskell.org/package/{package}
3. Check cabal-version: Must be ≤ 3.10 for GHC 9.6.7
4. If not available or incompatible: Use GitHub thunk
```

### Step 2: Try Building with Default Resolution
```
1. Let haskell.nix resolve from CHaP/Hackage first
2. Run nix-build and check for errors
3. If version conflict or API incompatibility: Override with thunk
```

### Step 3: Override with Local Thunk (if needed)
### Step 3: Override with Local Thunk (if needed)
```
1. Create/update thunk directory with github.json:
   {
     "owner": "input-output-hk",
     "repo": "io-sim",
     "rev": "b61e23a219c5ae113ff9a43f89b4451c8fe2f353",
     "sha256": "1nb4f61f1bk7nwfgksaz3mf5kh0xadmjv7j2q0d69n85gvzsc87r"
   }

2. Add override in cardano-project/default.nix modules:
   {
     packages.strict-stm.src = pkgs.haskell-nix.haskellLib.cleanGit {
       name = "strict-stm";
       src = cardanoPackageDeps.io-sim + "/strict-stm";
     };
     packages.strict-stm.doCheck = false;
   }

3. For monorepo packages: Path must point to subdirectory with .cabal file
```

### Step 4: Get SHA256 Hash for Thunks
```bash
# Use nix-prefetch-url to get correct hash:
nix-prefetch-url --unpack https://github.com/{owner}/{repo}/archive/{commit}.tar.gz
```

### Step 5: Test Build
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

## Patch Testing Workflow

When creating local patches for Haskell packages, test patches directly against the source tarball to iterate faster than rebuilding the entire Nix environment.

### Testing Patches Directly

To test a patch without rebuilding the full project:

1. Find the source tarball path from Nix store (from build error or `nix-store -qR` result)
2. Extract and test the patch:

```bash
cd /tmp && tar -xzf /nix/store/{hash}-{package}-{version}.tar.gz && cd {package}-{version} && patch -p1 --dry-run < /path/to/patch/file
```

Example:
```bash
cd /tmp && tar -xzf /nix/store/7himsj4ycdizjsj8149x8vjms452byql-ouroboros-network-framework-0.18.0.2.tar.gz && cd ouroboros-network-framework-0.18.0.2 && patch -p1 --dry-run < /Users/carlos/hydra-pay/cardano-project/patches/ouroboros-network-snocket-ghc96.patch
```

3. If `--dry-run` succeeds, apply without `--dry-run` and test compilation
4. Iterate on the patch file until it applies cleanly

This approach allows rapid patch iteration without waiting for full Nix builds.

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
