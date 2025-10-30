# Hydra Pay Patches Directory

This directory contains patches applied to Haskell packages during the migration from reflex-platform to haskell.nix with GHC 9.6.7.

## Migration Context

Hydra Pay is undergoing a major infrastructure migration:
- **From**: reflex-platform, Obelisk framework, GHC 8.10.7
- **To**: haskell.nix, modern Nix infrastructure, GHC 9.6.7
- **Reason**: Obelisk is no longer maintained, need modern GHC for cabal-version 3.4+ support

## contra-tracer API Changes

The major breaking change requiring these patches is the upgrade from contra-tracer 0.1.x to 0.2.0+, which removed several functions:

- `nullTracer` → replaced with `mempty`
- `stdoutTracer` → no longer available
- `showTracing` → replaced with `contramap show`

These functions were used throughout the Cardano ecosystem for tracing and logging.

## Patch Files

### ouroboros-network-framework-connect-null-ghc96.patch
**Target**: `src/Ouroboros/Network/Socket.hs` in ouroboros-network-framework-0.18.0.2
**Purpose**: Fix `nullNetworkConnectTracers` function for GHC 9.6.7 compatibility
**Changes**:
- `nctMuxTracer = nullTracer` → `nctMuxTracer = mempty`
- `nctHandshakeTracer = nullTracer` → `nctHandshakeTracer = mempty`

### ouroboros-network-framework-connect-debug-ghc96.patch
**Target**: `src/Ouroboros/Network/Socket.hs` in ouroboros-network-framework-0.18.0.2
**Purpose**: Fix `debuggingNetworkConnectTracers` function for GHC 9.6.7 compatibility
**Changes**:
- `nctMuxTracer = showTracing stdoutTracer` → `nctMuxTracer = mempty`
- `nctHandshakeTracer = showTracing stdoutTracer` → `nctHandshakeTracer = mempty`
- **Note**: Uses `mempty` instead of stdout printing since libraries shouldn't print to stdout by default

### ouroboros-network-framework-server-null-ghc96.patch
**Target**: `src/Ouroboros/Network/Socket.hs` in ouroboros-network-framework-0.18.0.2
**Purpose**: Fix `nullNetworkServerTracers` function for GHC 9.6.7 compatibility
**Changes**:
- `nstMuxTracer = nullTracer` → `nstMuxTracer = mempty`
- `nstHandshakeTracer = nullTracer` → `nstHandshakeTracer = mempty`
- `nstErrorPolicyTracer = nullTracer` → `nstErrorPolicyTracer = mempty`
- `nstAcceptPolicyTracer = nullTracer` → `nstAcceptPolicyTracer = mempty`

### ouroboros-network-framework-contramapM-ghc96.patch
**Target**: `src/Simulation/Network/Snocket.hs` in ouroboros-network-framework-0.18.0.2
**Purpose**: Fix `contramapM` import and usage for GHC 9.6.7 compatibility
**Changes**:
- Remove `contramapM` from `Control.Tracer` import (function no longer exists in contra-tracer 0.2.0+)
- Replace `contramapM` usage with direct `Tracer` construction using `traceWith` in a do-block
- **Note**: `contramapM` was used to create monadic tracer transformations, replaced with manual monadic tracing

## How Patches Are Applied

These patches are applied automatically during the Nix build process via haskell.nix configuration in `cardano-project/default.nix`. The patches are referenced in the package overrides and applied before compilation.

## Future Maintenance

- These patches may become unnecessary if upstream packages update to support contra-tracer 0.2.0+
- Monitor CHaP (Cardano Haskell Packages) for updated versions
- Consider contributing fixes upstream to reduce patching needs

## Testing Patches

To test patches manually:
```bash
# Extract source
tar -xf /path/to/package.tar.gz
cd package-source

# Apply patch
patch -p1 < /path/to/patch/file

# Test compilation
cabal build
```

## Related Files

- `cardano-project/default.nix` - haskell.nix configuration with patch references
- `build-in-docker.log` - Build logs showing patch application
- `cardano-project/cardano-overlays/cardano-packages/default.nix` - Package definitions</content>
<parameter name="filePath">/Users/carlos/hydra-pay/cardano-project/patches/README.md