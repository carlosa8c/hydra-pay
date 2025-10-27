# Hydra Pay: Nix-in-Docker build notes (macOS)

This doc captures the issues we’re hitting when building via Nix inside Docker on macOS, what we changed, and pragmatic next steps for anyone jumping in.

## Goals

- Fast, reliable Nix builds inside Docker on macOS with persistent caches
- Attribute-targeted builds (e.g., `-A ghc.cardano-api`)
- Sandbox off on macOS, unchanged on Linux
- Ability to test individual Haskell package builds locally

## Environment summary

- Host: macOS; running linux/amd64 Docker containers
- Proxies present (http/https); GitHub token provided via `.github_token`
- Container runs with `--security-opt seccomp=unconfined`
- Caches: `/nix` and `/root/.cache/nix` persisted via Docker volumes

Key files:
- `build-in-docker.sh` – orchestrates the Dockerized Nix build
- `cardano-project/default.nix` – composes reflex-platform and overlays; wraps cabal2nix
- `cardano-project/cardano-overlays/cardano-packages/default.nix` – Cardano package overlay
- `dep/cardano-node/github.json` – pin (moved to 1.35.7 so `cardano-api/` exists)

## Repro (targeted build)

Inside repo root:

```sh
./build-in-docker.sh --attr ghc.cardano-api
```

This launches a NixOS container (linux/amd64 on macOS), disables sandboxing, forwards proxies and GitHub token, and runs `nix-build -A ghc.cardano-api` with `-K --keep-failed --show-trace`.

## Issue 1: Nix sandbox seccomp failure on Docker for Mac

Symptom (earlier in investigation):
- `unable to load seccomp BPF program: Invalid argument`

Cause: Docker for Mac’s seccomp profile + Nix sandbox don’t get along.

Fix implemented:
- Container startup sets `NIX_CONFIG` with `sandbox = false` and `filter-syscalls = false`.
- Container launched with `--security-opt seccomp=unconfined`.

Result: Seccomp/sandbox errors no longer block the build.

## Issue 2: cabal2nix mis-resolving local/VCS sources (subdir packages)

Target: Build `ghc.cardano-api`, which depends on subpackages from `cardano-base` (e.g., `cardano-binary`).

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
