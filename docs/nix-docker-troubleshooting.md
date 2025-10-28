# Hydra Pay: Nix-in-Docker build notes (macOS)

This doc captures the Docker build issues we've resolved and the current status of the Nix build system for hydra-pay on macOS. The overarching goal is to keep the repository updated to the latest viable package and dependency versions while ensuring `./build-in-docker.sh` succeeds, so the project can be built consistently across macOS, Linux, and CI environments.

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

## 🔄 CURRENT: Issue 5: Cabal solver ignores Obelisk/Rhyolite overrides

**Status: IN PROGRESS**

Symptom:
```
Error: [Cabal-7107]
Could not resolve dependencies:
[__1] unknown package: obelisk-route (dependency of backend)
```

What we are seeing:
- The generated `cabal.project.local` text (see `nix eval .#packages.aarch64-darwin.debug-cabal-project`) correctly lists 30+ store paths for Obelisk and Rhyolite packages, yet `callCabalProjectToNix` never reads it.
- The temporary build directory captured with `--keep-failed` (for example `/nix/var/nix/builds/nix-35703-3265046263/tmp.*`) only contains the stock `cabal.project` from the repository (`optional-packages: *`), proving the local override is being dropped before Cabal runs.
- Feeding the content through `modules = [ moduleConfig ]` did not work because the module was executed after `callCabalProjectToNix` evaluated the project; wiring the text via the top-level `cabalProject` argument triggers the same evaluation, but `processAssets` inside Obelisk tries to consult `~/.gitconfig`, which is denied under pure evaluation.

Open questions we are tracking:
- Identify the correct hook for injecting the generated `packages:` stanza so Cabal sees the additional store paths (e.g. via `project.appendModule`, or by materialising the file and using `cabalProjectFileName`).
- Prevent Obelisk's `processAssets` from reading host configuration during evaluation (set `GIT_CONFIG_GLOBAL=/dev/null` or provide a stub).
- Once the solver succeeds on macOS, propagate the same wiring into the Docker/Linux pipeline to regain parity.

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
- ✅ Missing nixpkgs and Cardano package dependencies resolved
- ✅ Build log monitoring improved
- 🔄 Cabal still fails to see Obelisk/Rhyolite source overrides (current blocker)

**Current Build Flow:**
1. Container starts successfully
2. Dependencies download and extract properly
3. `callCabalProjectToNix` runs but only sees the base `cabal.project`
4. Cabal solver stops with `unknown package: obelisk-route`

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
- **`flake.nix`**:
  - Generates a `cabalProject` string merging the repo’s base file with store-path packages for Obelisk/Rhyolite
  - Adds debug outputs (`debug-cabal-project`, `debug-package-paths`) to inspect the generated configuration

## Next Steps

### Immediate (to resolve the Cabal override issue)
1. **Inject the `packages:` stanza earlier**
  - Pass a concrete `cabalProject` file (materialised in the repo or generated under `generated/`) so `callCabalProjectToNix` reads the augmented list before evaluation.
  - Alternatively, use `project.appendModule` or an overlay on `callCabalProjectToNix` to append the text after the default `packages: ./*.cabal` clause.

2. **Stub host Git configuration during evaluation**
  - Set `GIT_CONFIG_GLOBAL=/dev/null` and `HOME` to a temporary directory when running `processAssets` so Obelisk does not attempt to read `~/.gitconfig` in pure mode.
  - If necessary, pre-generate the asset manifest outside evaluation and feed the store path via `flake` inputs.

3. **Validate the solver outcome**
  - Re-run `nix build .#packages.aarch64-darwin.default --keep-failed` and confirm the generated `cabal.project` inside the kept build directory now includes the store paths.
  - Expect the next failure to surface at actual compilation instead of dependency resolution; iterate from there.

### Medium-term improvements
1. **Port fixes to Docker/Linux**: mirror the working `cabal.project` approach in `build-in-docker.sh` so CI parity is restored.
2. **Add smoke tests**: wire a minimal `cabal new-build` invocation in CI to catch regressions in project wiring quickly.
3. **Documentation upkeep**: keep this guide aligned with the chosen cabal wiring (materialised file vs. module injection).

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

1) **Materialise the augmented `cabal.project`**
   - Write the generated text from `debug-cabal-project` to `config/cabal.project.generated` (or similar) and commit it.
   - Point `flake.nix` at that file via `cabalProjectFileName` or by setting `cabalProject = builtins.readFile ./config/cabal.project.generated;`.
   - This keeps the override deterministic and sidesteps the module ordering problem entirely.

2) **Append the overrides in a module**
   - Use `project.appendModule` (or add another entry to `modules`) that returns `{ config.cabalProject = config.cabalProject + "\n" + extraPackagesText; }`.
   - Ensure the module reads `config.cabalProject` from its arguments rather than re-importing the file so the amendment survives evaluation.

3) **Sanitise the environment for `processAssets`**
   - Wrap `processAssets` in a `pkgs.runCommand` that sets `HOME` and `GIT_CONFIG_GLOBAL` to temporary locations.
   - Alternatively, run it once manually and commit the resulting manifest under `static/` so evaluation only references a store path.

## Current status

- Build stops during dependency planning with `unknown package: obelisk-route` because Cabal only sees the base `cabal.project`.
- The generated override text already resides in the store (`debug-cabal-project`); the remaining work is to inject it before `callCabalProjectToNix` runs.

## Pointers to changes

- `flake.nix`: source overrides, asset manifest wiring, debug helpers.
- `static/`: produced by `processAssets`; keep in sync if we decide to materialise outputs.
- `build-in-docker.sh`: orchestrates the macOS-to-Linux build; will need an update once cabal wiring stabilises.

## Who can pick this up next

- Run `nix eval --impure --raw .#packages.aarch64-darwin.debug-cabal-project > /tmp/cabal.project.generated` and inspect the contents.
- Decide between “materialise the file” vs “module append” and implement the chosen route in `flake.nix`.
- Re-run `nix build .#packages.aarch64-darwin.default --keep-failed`, inspect `/nix/var/nix/builds/.../tmp.*/cabal.project`, and keep iterating until it matches the generated file.

If you need a fresh trace, repeat the build with `--keep-failed` and check the `plan-to-nix` derivation logs:

```sh
nix build .#packages.aarch64-darwin.default --keep-failed --show-trace
```

The kept directory will live under `/nix/var/nix/builds/` with a random suffix; look for the newest entry after the failed build.

## Recommendation

- **Primary fix**: materialise the generated `cabal.project` (or append it via `project.appendModule`) so `callCabalProjectToNix` sees the Obelisk/Rhyolite packages during dependency planning.
- **Hardening step**: run `processAssets` under a clean environment (`GIT_CONFIG_GLOBAL=/dev/null`, temporary `HOME`) or pre-generate the manifest to avoid host `~/.gitconfig` lookups in pure mode.
- **Follow-through**: once macOS succeeds, update the Docker/Linux path and verify `nix build .#packages.x86_64-linux.default` uses the same project wiring.
