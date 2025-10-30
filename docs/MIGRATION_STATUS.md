# Migration Status: GHC 9.6+ Upgrade

## Completed
- ✅ Phase 1.1: Removed Obelisk dependencies from Haskell code
- ✅ Phase 1.2: Simplified default.nix (removed Obelisk project function)

## Current Status: Phase 1.3 - Upgrading to GHC 9.6.7

### Key Findings from Modern Hydra Project
Modern Hydra (cardano-scaling/hydra @ master) uses:
- **GHC 9.6.7** (`ghc967` in haskell.nix)
- **haskell.nix** from input-output-hk
- **CHaP** (Cardano Haskell Packages) at https://intersectmbo.github.io/cardano-haskell-packages
- **cardano-node 10.4.1**
- **Flake-based build** with flake-parts

### Our Approach (Non-Flake Adaptation)
Since we're using nix-thunks (not flakes), we'll adapt by:
1. Update cardano-project/default.nix to use haskell.nix directly
2. Set compiler-nix-name = "ghc967" (or ghc966 for compatibility)
3. Configure CHaP as package repository
4. Remove all reflex-platform/Obelisk/GHCJS machinery
5. Keep only Cardano package overlays

## Next Steps
1. Update cardano-project/default.nix with haskell.nix + GHC 9.6.7
2. Update dependency thunks (cardano-node, hydra, etc.) to modern versions
3. Restore modern packages (lsm-tree, etc.) that require cabal-version 3.4
4. Fix compilation errors from GHC upgrade
5. Test build with ./build-in-docker.sh

## Notes
- GHC 9.6.7 includes Cabal 3.10+ which can parse cabal-version 3.4
- Modern Cardano packages all require GHC 9.2+ minimum
- Backend-only focus: no mobile, no GHCJS, just hydra-pay API

## Phase 1.4: Dependency Thunk Updates

### Strategy
Align with main Hydra project (cardano-scaling/hydra):
- Hydra uses: cardano-node 10.4.1
- Hydra uses: GHC 9.6.7 (ghc967)
- Hydra uses: Latest Cardano packages from CHaP

### Critical Thunks to Update

1. **hydra** (cardano-scaling/hydra)
   - Current: 8f8f51a5df5108aa280e92e672a1eb87726a6ffe
   - Target: Latest stable release or master
   
2. **cardano-node** (IntersectMBO/cardano-node)
   - Current: ca1ec278070baf4481564a6ba7b4a5b9e3d9f366
   - Target: 10.4.1 (tag used by main Hydra)
   
3. **cardano-base** (IntersectMBO/cardano-base)
   - Need to check current version in cardano-project/cardano-overlays/cardano-packages/dep/
   - Target: Latest compatible with cardano-node 10.4.1

### Update Method
Use `ob thunk update` or manually edit github.json files with:
- New rev (commit hash or tag)
- New sha256 (get from nix-prefetch-url)

### Testing After Updates
After updating thunks, test with:
```bash
./build-in-docker.sh > build.log 2>&1 &
tail -f build.log
```
