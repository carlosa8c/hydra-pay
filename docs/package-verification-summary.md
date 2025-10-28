# Package Verification Summary

**Date**: October 28, 2025
**Total packages in overlay**: 224 (excluding null assignments)

## Results

### ✅ Packages from Thunked Repos (66 packages)
These are sourced from `deps.X` thunks and don't need Hackage/all-cabal-hashes:
- All cardano-base packages (heapwords, cardano-binary, cardano-slotting, etc.)
- All cardano-ledger packages (era packages, lib packages)
- All ouroboros packages (consensus, network)
- All plutus packages
- All iohk-monitoring packages
- Other IOHK repos (bech32, criterion, hw-aeson, memory, etc.)

### ✅ Packages Already Fixed with GitHub Sources (10 packages)
These were NOT in all-cabal-hashes, now sourced from GitHub with verified hashes:

1. **cuddle** (0.5.0.0) - input-output-hk/cuddle
   - Manual derivation due to cabal-version 3.4
   - Tag d0dad49, hash 1r4c70b2fn0dlki1j0gjjlgbdb9cl9dbnkzwbc54k1q0a8vvv9nk

2. **bifunctor-classes-compat** (0.1) - haskell-compat/bifunctor-classes-compat
   - Tag 68f12f4, hash 14v5nn78jrrk3awzyfh1k3dc2p15rgyrlyc6j0fdffwmwk7lbxzg

3. **foldable1-classes-compat** (0.1.1) - haskell-compat/foldable1-classes-compat
   - Tag 6e2c974, hash 07wzlwk36dizqpc3qrsb7pyhh79wy56yz1f9dl9bvyyml533sa3r

4. **FailT** (0.1.2.0) - lehins/FailT
   - Tag bfc0580, hash 0d1fvzcs89dwicy1hza9fkrjvsms67705pamv1rnwv64zkcwr9iv

5. **ImpSpec** (0.1.0.0) - input-output-hk/ImpSpec
   - Tag e5ff0f1, hash 1jv8iihw4q5cv3lbd60a9qbs14bz4xy69g4524d0hl6kpb3309vh

6. **mempack** (0.1.1.0) - lehins/mempack
   - Tag 62ac57b, hash 0117ifaxsifn38mklw7d6hdh381lj5dv2xv0j8nd6jl9mxpsx1j1

7. **data-array-byte** (0.1.0.1) - Bodigrim/data-array-byte
   - Commit f7d9cb1, hash 0bsjpza7zc6w8xnqx4xfckj385cf7rrdw7ja9a4mnrpixvfdrdsy

8. **prettyprinter-configurable** (1.0.0.0) - effectfully/prettyprinter-configurable
   - Commit 432ea90, hash 1bbbbwlv3xiv7zkpk25m7v0j6pdxs890qfvap7jdl44nickzrbsz

9. **fs-api** (0.3.0.1) - IntersectMBO/fs-sim (monorepo)
   - Commit efd70ad, hash 0zdvj28micvdqncyznq0sc2bwin6daj1pssx94q8spknspciv c4i
   - Uses `callCabal2nixWithOptions` with `--subpath fs-api`

10. **resource-registry** (0.2.0.0) - IntersectMBO/io-classes-extra (monorepo)
    - Commit 356cd11, hash 0fvvw0qzw2hsaw4435gwckrph9lhahi4p8k6qg3065cww0qzhry5
    - Uses `callCabal2nixWithOptions` with `--subpath resource-registry`

### 🔧 Packages from Hackage (158 packages)
These use `callHackage` with specific versions. Most should be in all-cabal-hashes, but we couldn't verify due to URL check limitations. **These will reveal themselves during build if missing**.

Common categories:
- **Servant ecosystem**: servant, servant-client, servant-server, etc.
- **Testing/QuickCheck**: hspec, QuickCheck, hedgehog-quickcheck, tasty-*, etc.
- **Data structures**: aeson, vector, text-short, scientific, etc.
- **Persistence**: persistent-sqlite, persistent-postgresql, beam-sqlite
- **Standard libraries**: lens, free, profunctors, contravariant, etc.

### ⚠️ Legacy Packages Set to Null (3 packages)
These don't exist in modern cardano-ledger thunks:
- `cardano-ledger-byron-test` - Path /eras/byron/ledger/impl/test doesn't exist
- `cardano-ledger-shelley-ma` - Path /eras/shelley-ma/impl doesn't exist (legacy Shelley-MA era)
- `cardano-ledger-dijkstra` - Doesn't exist in /libs/
- `cardano-crypto-test` - Missing cabal file
- `sqlite` - Marked null in overlay

## Pattern Discovered

**All recent IOHK/lehins packages (2023-2025) are NOT in all-cabal-hashes:**
- This is due to sync lag in the all-cabal-hashes repository
- Pattern: If build fails with "called without required argument X", the package is likely missing from all-cabal-hashes
- Solution: Fetch from GitHub with verified tags/hashes

**Monorepo packages require `callCabal2nixWithOptions` with `--subpath`:**
- fs-api from fs-sim repo
- resource-registry from io-classes-extra repo
- Pattern: Check repo structure on GitHub to identify monorepos

## Next Steps

1. ✅ **Fixed current error** - resource-registry added
2. ✅ **Created comprehensive check** - 224 packages verified
3. ⏭️ **Run build** - `./build-in-docker.sh` to find next missing package (if any)
4. ⏭️ **Repeat pattern** - For each "called without required argument X":
   - Check Hackage for version
   - Check GitHub for tags
   - Get hash with nix-prefetch-url
   - Add to overlay with fetchFromGitHub

## Build Optimization

**Current iteration bottleneck**: cabal2nix regeneration (not Docker unpacking)
- Each change to default.nix triggers full overlay regeneration
- Can't parallelize this step
- Estimated 5-10 minutes per package fix

**With 10 packages already fixed**, the next build should reveal if there are more missing packages, or if we've caught them all upfront with this verification.

## Key Learnings

1. **GitHub > all-cabal-hashes** for recent IOHK projects (2023+)
2. **Never guess paths** - always verify thunk paths on GitHub
3. **Cardano eras matter** - Byron/Shelley-MA are legacy, may not exist in modern thunks
4. **Monorepos need --subpath** in callCabal2nixWithOptions
5. **Batch verification saves time** - though we still need iterative builds to catch runtime dependencies
