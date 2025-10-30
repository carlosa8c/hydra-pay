# Pre-Generated Nix Expressions (DEPRECATED)

**NOTE: This directory is no longer needed with GHC 9.6.7 + haskell.nix**

With GHC 9.6.7, the bundled Cabal supports cabal-version up to 3.6+, so we can use `callCabal2nix` directly for all packages. The pre-generated `.nix` files have been moved to `generated-nix-expressions-old/` as a backup.

## Migration (Oct 2025)

All packages previously using pre-generated `.nix` files now use `callCabal2nixWithOptions` directly:

```nix
# Old approach (pre-generated):
io-classes = haskellLib.dontCheck (self.callPackage ../generated-nix-expressions/io-classes.nix {
  src = deps.io-sim;
});

# New approach (direct):
io-classes = haskellLib.dontCheck (self.callCabal2nixWithOptions "io-classes" (deps.io-sim + "/io-classes") "" {});
```

This simplifies maintenance and ensures we're always using the actual `.cabal` files from the source repositories.

---

## Historical Context (Pre-GHC 9.6)

<details>
<summary>Why we previously needed pre-generation (click to expand)</summary>

The cabal2nix version in nixpkgs only supported up to cabal-version 3.4. Packages using newer cabal-version specifications (3.6, 3.8, etc.) would fail with:

```
*** cannot parse "/nix/store/.../package.cabal":
Unsupported cabal-version X.Y. See https://github.com/haskell/cabal/issues/4899.
```

This is no longer an issue with modern GHC versions.

</details>
