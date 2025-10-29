# Pre-Generated Nix Expressions

This directory contains `.nix` files pre-generated using modern cabal2nix (2.20.1+) for packages that use `cabal-version > 3.4`.

## Why Pre-Generation?

The cabal2nix version in nixpkgs only supports up to cabal-version 3.4. Packages using newer cabal-version specifications (3.6, 3.8, etc.) will fail with:

```
*** cannot parse "/nix/store/.../package.cabal":
Unsupported cabal-version X.Y. See https://github.com/haskell/cabal/issues/4899.
```

## When to Pre-Generate

**Only pre-generate for packages with cabal-version > 3.4**

- cabal-version 3.0, 3.2, 3.4: Use `callCabal2nix` directly ✅
- cabal-version 3.6, 3.8, 3.10+: Pre-generate .nix file ⚠️

## How to Pre-Generate

1. Generate with modern cabal2nix:
   ```bash
   cabal2nix https://github.com/{owner}/{repo}/archive/{commit}.tar.gz --subpath {path} > {package}.nix
   ```

2. Modify generated file to accept `src` as parameter:
   ```nix
   # Change from:
   { mkDerivation, base, fetchzip, lib, ... }:
   mkDerivation {
     src = fetchzip { ... };
   
   # To:
   { mkDerivation, base, lib, ..., src }:
   mkDerivation {
     inherit src;
   ```

3. Use in overlay with `callPackage`:
   ```nix
   package = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/package.nix {
     src = pkgs.fetchFromGitHub { ... };
   });
   ```

## Current Pre-Generated Packages

- **cardano-api.nix** - cabal-version 3.8
- **io-classes.nix** - cabal-version 3.4 (ghc-internal dependency removed)
- **io-sim.nix** - cabal-version 3.4
- **typed-protocols.nix** - cabal-version 3.4
- **typed-protocols-cborg.nix** - cabal-version 3.4
- **typed-protocols-examples.nix** - cabal-version 3.4
- **ouroboros-network.nix** - cabal-version 3.4

## Proactive Scanning

Use `scan-cabal-versions.sh` (in workspace root) to check all thunks for problematic cabal-versions before building.
