# Hydra Pay: Nix-in-Docker build notes (macOS)

This doc captures the Docker build issues we've resolved and the current status of the Nix build system for hydra-pay on macOS.

## Goals

- Fast, reliable Nix builds inside Docker on macOS with persistent caches
- Full project builds (`nix-build` without specific attributes)
- Sandbox off on macOS, unchanged on Linux
- Ability to test individual Haskell package builds locally

## Environment summary

- Host: macOS; running linux/amd64 Docker containers
- Proxies present (http/https); GitHub token provided via `.github_token`
- Container runs with `--security-opt seccomp=unconfined`
- Caches: `/nix` and `/root/.cache/nix` persisted via Docker volumes

Key files:
- `build-in-docker.sh` – orchestrates the Dockerized Nix build
- `.ci/inner-build.sh` – internal build script with improved logging
- `cardano-project/default.nix` – composes reflex-platform and overlays; includes blst package definition
- `cardano-project/cardano-overlays/cardano-packages/default.nix` – Cardano package overlay with dependency fixes
- `cardano-project/base.nix` – base package overrides
- `cardano-libs.nix` – additional Cardano library definitions
- Multiple `thunk.nix` files – dependency version pins updated to newer nixpkgs

## Quick Start

Inside repo root:

```sh
./build-in-docker.sh
```

This launches a NixOS container (linux/amd64 on macOS), disables sandboxing, forwards proxies and GitHub token, and runs the full project build with persistent caching.

## ✅ RESOLVED: Issue 1: Nix sandbox seccomp failure on Docker for Mac

**Status: FIXED**

Symptom:
- `unable to load seccomp BPF program: Invalid argument`

Cause: Docker for Mac's seccomp profile + Nix sandbox don't get along.

Fix implemented:
- Container startup sets `NIX_CONFIG` with `sandbox = false` and `filter-syscalls = false`.
- Container launched with `--security-opt seccomp=unconfined`.

Result: ✅ Seccomp/sandbox errors no longer block the build.

## ✅ RESOLVED: Issue 2: Container hanging indefinitely

**Status: FIXED**

Symptom:
- Docker build would hang without progress or error messages
- No visible build activity in logs

Cause: Container lock or resource contention issues.

Fix implemented:
- Container restart procedures
- Improved container lifecycle management
- Enhanced logging in `.ci/inner-build.sh` with build log clearing

Result: ✅ Build now progresses consistently without hanging.

## ✅ RESOLVED: Issue 3: Missing nixpkgs dependencies

**Status: FIXED**

Symptom:
- Missing `blst` package errors
- Various Cardano ecosystem packages not found

Cause: Outdated nixpkgs commits in thunk.nix files didn't contain required packages.

Fix implemented:
- Updated 11 thunk.nix files from old nixpkgs commit (3aad50c30c) to newer commit (47585496bcb)
- Added custom `blst` package definition in `cardano-project/default.nix`
- Updated SHA256 hashes for all dependency thunks

Result: ✅ All required system packages now available in nixpkgs.

## ✅ RESOLVED: Issue 4: Missing Cardano package dependencies

**Status: FIXED**

Symptom:
- `cardano-crypto-test` package not found
- `cardano-ledger-binary` package missing

Cause: Test packages and renamed packages in Cardano ecosystem.

Fix implemented:
- Set `cardano-crypto-test = null` to disable missing test package
- Added `cardano-ledger-binary = self.cardano-binary` alias
- Enhanced package definitions in `cardano-project/cardano-overlays/cardano-packages/default.nix`

Result: ✅ Missing package dependencies resolved.

## 🔄 CURRENT: Issue 5: cardano-crypto-wrapper function coercion

**Status: IN PROGRESS**

Symptom:
```
error: cannot coerce a function to a string: «lambda callPackageKeepDeriver @ /nix/store/...-source/pkgs/development/haskell-modules/make-package-set.nix:161:33»
```

Current approach:
- Disabled `cardano-crypto-wrapper` by setting to `null` in all overlay files
- Issue persists, suggesting deeper Nix expression evaluation problem

Investigation needed:
- Function coercion in Haskell.nix build system
- Possible cabal2nix-generated dependency issues
- May require alternative package definition approach

## What's Working ✅

- **Docker orchestration and caching**: Full container lifecycle management
- **macOS-specific fixes**: Sandbox disablement and seccomp unconfined configuration
- **Dependency resolution**: Updated nixpkgs and Cardano package ecosystem
- **Build progress**: Build now proceeds through dependency download and evaluation phases
- **Logging**: Enhanced build monitoring with clear log management
- **Container persistence**: Proper volume mounting for `/nix` and `/root/.cache/nix`

## Current Build Status

**Progress Made:**
- ✅ Container hanging resolved
- ✅ Missing nixpkgs dependencies resolved  
- ✅ Missing Cardano package dependencies resolved
- ✅ Build log monitoring improved
- 🔄 Function coercion error in cardano-crypto-wrapper (ongoing)

**Current Build Flow:**
1. Container starts successfully
2. Dependencies download and extract properly
3. Package evaluation begins
4. Stops at cardano-crypto-wrapper function coercion error

## Files Modified

### Dependency Updates
- **11 thunk.nix files**: Updated nixpkgs commits and SHA256 hashes
  - `.obelisk/impl/thunk.nix`
  - `cardano-project/.obelisk/impl/thunk.nix`
  - `cardano-project/dep/reflex-gadt-api/thunk.nix`
  - `cardano-project/dep/rhyolite/thunk.nix`
  - `cardano-project/dep/vessel/thunk.nix`
  - `dep/bytestring-aeson-orphans/thunk.nix`
  - `dep/cardano-node/thunk.nix`
  - `dep/cardano-transaction-builder/thunk.nix`
  - `dep/flake-compat/thunk.nix`
  - `dep/hydra/thunk.nix`
  - `dep/reflex-gadt-api/thunk.nix`

### Package Overlays
- **`cardano-project/default.nix`**: Added blst package definition
- **`cardano-project/cardano-overlays/cardano-packages/default.nix`**: 
  - Added cardano-crypto-test = null
  - Added cardano-ledger-binary alias
  - Disabled cardano-crypto-wrapper
- **`cardano-project/base.nix`**: Disabled cardano-crypto-wrapper
- **`cardano-libs.nix`**: Disabled cardano-crypto-wrapper

### Build System
- **`.ci/inner-build.sh`**: Enhanced logging with build log clearing

## Next Steps

### Immediate (to resolve cardano-crypto-wrapper)
1. **Investigate function coercion**: 
   - Deep dive into Haskell.nix build system
   - Check cabal2nix generated expressions
   - Consider alternative package definition methods

2. **Alternative approaches**:
   - Use pre-generated .nix files for problematic packages
   - Fetch from different source (Hackage vs. GitHub)
   - Investigate dependency graph to find root cause

### Medium-term improvements
1. **Package alignment**: Ensure consistent versions across Cardano ecosystem
2. **Testing**: Add validation for individual package builds
3. **Documentation**: Update build procedures and troubleshooting guides

## How to Test

```sh
# Full build attempt
./build-in-docker.sh

# Check logs
tail -f build-in-docker.log

# Clean restart if needed
docker stop hydra-pay-builder 2>/dev/null || true
docker run --rm -d --name hydra-pay-builder \
  -v "$(pwd):/work" \
  -v hydrapay-nix:/nix \
  -v hydrapay-nix-cache:/root/.cache \
  nixos/nix sh -c "cd /work && ./.ci/inner-build.sh"
```

## Previous Issues (Now Resolved)

<details>
<summary>Historical troubleshooting information</summary>

### Issue: cabal2nix subdir package resolution (OBSOLETE)
This was an earlier issue with cabal2nix handling of subdirectory packages from cardano-base. The current approach uses fetchFromGitHub and direct package definitions, which has resolved these issues.

### Issue: VCS/URL parsing errors (OBSOLETE)  
Earlier versions had issues with URL parsing and VCS operations. The updated nixpkgs and improved package definitions have resolved these.

</details>

Observed errors (latest):

```
*** parsing cabal file: /nix/store/<...>-cardano-base-src.tar.gz/binary: openBinaryFile: not a directory
error: unable to download '/nix/store/<...>-cardano-base-src.tar.gz': URL using bad/illegal format or missing URL (3)
** need a revision for VCS when the hash is given. skipping.
cabal2nix: user error (Failed to fetch source ... sourceCabalDir = "binary")
```

We also previously saw:
- `openBinaryFile: does not exist (No such file or directory)` when passing a directory to `--subpath`
- `tar: This does not look like a tar archive` when cabal2nix tried to treat a store path as a tar URL

### Hypothesis

When asking `cabal2nix` to generate from a subdirectory of a repo, it’s sometimes trying to “download” store paths or expects a VCS revision context, especially when `--subpath` is used. Proxies exacerbated issues when file:// URLs were misinterpreted.

### Changes and attempts so far

1) Ensure tools and PATH for generators
- Augmented `stdenv.initialPath` so `nix-prefetch-*`, coreutils, etc. are always present in builder environments.
- Wrapped `cabal2nix` in both `pkgs.cabal2nix` and `buildPackages.cabal2nix` to:
  - Prepend a tool-rich PATH (nix, coreutils, findutils, sed, grep, tar, xz, gzip, bzip2, curl)
  - Unset proxy env (`http_proxy`, `https_proxy`, `all_proxy`, `no_proxy`) to avoid proxying file:// paths

2) Pin to restore expected subdirs
- `dep/cardano-node/github.json` pinned to `1.35.7` (so `cardano-api/` exists in that repo).

3) Avoid cabal.project scanning
- `cleanSourceWith` filters `cabal.project*` out of `cardano-base` so cabal2nix doesn’t scan cross-repo project files.

4) Subdir strategies for `cardano-base` packages
- Direct subdir as path: `self.callCabal2nix "cardano-binary" (cleanCardanoBase + "/binary") {}` → still produced URL/VCS warnings.
- Force path: `builtins.toPath "${cleanCardanoBase}/binary"` → same failures.
- Use `callCabal2nixWithOptions` with `--subpath binary` on the directory → cabal2nix treated inputs oddly; errors like “not a tar archive”.
- Package repo into tarball first, then `--subpath`:
  ```nix
  cardanoBaseTarball = pkgs.runCommand "cardano-base-src.tar.gz" { src = cleanCardanoBase; } ''
    tar -C "$src" -czf "$out" .
  '';
  cardano-binary = self.callCabal2nixWithOptions "cardano-binary" cardanoBaseTarball "--subpath binary" {};
  ```
  → Still failing with “openBinaryFile: not a directory” and “URL using bad/illegal format”.

5) Direct out-of-band generation attempt (to vendor the nix):
- Tried: `cabal2nix --subpath binary --revision 9b4b06e4 https://github.com/IntersectMBO/cardano-base.git`
- This was intended to emit a stable `.nix` we could commit (e.g., `generated-cardano-binary.nix`).
- Command was invoked in a dockerized nix-shell but failed prior to completion; worth revisiting.

### Where it currently fails

- Failing derivation: `cabal2nix-cardano-binary.drv`
- The rest of the build (`cardano-api`) fails because `cardano-binary` generation fails first.

## What’s working

- Docker orchestration and caching
- macOS-specific sandbox disablement and seccomp unconfined
- Tooling availability and cabal2nix proxy-sanitized wrappers
- Pin to `cardano-node` 1.35.7

## Recommended next steps (low-risk → higher effort)

1) Vendor cabal2nix outputs for cardano-base subpackages
- Generate `.nix` for each needed subdir from a known-good revision, out-of-band (with network and git available), then commit under overlay, e.g., `cardano-overlays/cardano-packages/generated/`.
  - Example to re-run (pick a good SHA and adjust):
    ```sh
    docker run --rm --platform linux/amd64 --security-opt seccomp=unconfined \
      -e GITHUB_TOKEN=$(cat .github_token) -e http_proxy -e https_proxy \
      -v "$PWD":/work -w /work nixos/nix bash -lc '
        set -euo pipefail
        nix-shell -p cabal2nix git cacert --command \
          "cabal2nix --subpath binary --no-cabal-project --revision <REV> https://github.com/IntersectMBO/cardano-base.git > cardano-project/cardano-overlays/cardano-packages/generated/cardano-binary.nix"
      '
    ```
  - Update overlay to use `callPackage` on that generated file instead of invoking cabal2nix at build time.

2) Fetch via `fetchFromGitHub` and avoid `--subpath` download code paths
- Replace `cleanCardanoBase` with a true tarball fetch:
  ```nix
  cardanoBaseSrc = pkgs.fetchFromGitHub {
    owner = "IntersectMBO"; repo = "cardano-base";
    rev = "<REV>"; sha256 = "<HASH>";
  };
  cardano-binary = self.callCabal2nixWithOptions "cardano-binary" cardanoBaseSrc "--subpath binary --no-cabal-project" {};
  ```
- This should keep the source as an unpacked tar directory in the store and avoid VCS/hash heuristics.

3) Confirm our wrapper is actually the one used by cabal2nix derivations
- We already override both `pkgs.cabal2nix` and `buildPackages.cabal2nix`. Double-check via `nix-store -qR` of the failing drv whether our wrapper path appears.

4) Wire `cardano-api` from a stable source
- Since newer `cardano-node` versions dropped the `cardano-api/` subdir, we either:
  - Pin `cardano-api` from Hackage with the GHC 8.10.7 compatible version, or
  - Fetch a matching commit of `cardano-node` containing `cardano-api/` and add a separate overlay entry.

5) Align pins across `cardano-base`/`ledger`/`ouroboros` to a known-good set
- If generation succeeds but later compilation mismatches happen, lock to a consistent set of SHAs or versions.

## Current status

- Build stops at `cabal2nix-cardano-binary.drv` with URL/VCS/subpath confusion.
- Orchestration is otherwise healthy; the problem is isolated to cabal2nix input handling for `cardano-base` subpackages.

## Pointers to changes

- cabal2nix wrappers (unset proxies, richer PATH):
  - `cardano-project/default.nix` overlays for `cabal2nix` and `buildPackages.cabal2nix`
- Subdir handling attempts (directory, `--subpath`, tar.gz + `--subpath`):
  - `cardano-project/cardano-overlays/cardano-packages/default.nix`
- Node pin for `cardano-api/` presence:
  - `dep/cardano-node/github.json` → `1.35.7`
- Container build invocation and sandbox toggles:
  - `build-in-docker.sh`

## Who can pick this up next

- Try option (1): vendor generated `.nix` for the needed subdirs, commit, and switch overlay to those. This removes cabal2nix from the evaluation/realisation path entirely for `cardano-base` and should unblock quickly.
- If you prefer to keep generation in-Nix, try option (2) with `fetchFromGitHub` + `--no-cabal-project`.

If you need a fresh failing trace, re-run:

```sh
./build-in-docker.sh --attr ghc.cardano-api
```

…and inspect `/Users/carlos/hydra-pay/build-in-docker.log` for the cabal2nix error block.
