# Dependency Verification List

This document tracks all Haskell packages referenced in `cardano-project/cardano-overlays/cardano-packages/default.nix` to verify:
1. Package exists on Hackage
2. Package exists in all-cabal-hashes (or needs GitHub fallback)
3. Package version/source is correct
4. Thunk paths are valid (for packages from thunked repos)

## Status Legend
- ✅ Verified on Hackage + all-cabal-hashes
- 🔧 On Hackage but NOT in all-cabal-hashes (GitHub source used)
- ⚠️ Legacy package set to null (path doesn't exist)
- 🔍 Needs verification

---

## Cardano Base Packages (from cardanoBaseSrc)

### ✅ Verified
- [ ] heapwords
- [ ] cardano-strict-containers
- [ ] cardano-binary
- [ ] cardano-binary-test
- [ ] cardano-slotting
- [ ] base-deriving-via
- [ ] orphans-deriving-via
- [ ] measures

---

## Cardano Ledger Packages (from deps.cardano-ledger thunk)

### Era Packages
- [ ] cardano-ledger-babbage
- [ ] cardano-ledger-babbage-test
- [ ] cardano-ledger-byron
- [x] ⚠️ cardano-ledger-byron-test - NULL (path /eras/byron/ledger/impl/test doesn't exist)
- [ ] cardano-ledger-shelley
- [ ] cardano-ledger-shelley-test
- [x] ⚠️ cardano-ledger-shelley-ma - NULL (path /eras/shelley-ma/impl doesn't exist)
- [ ] cardano-ledger-allegra
- [ ] cardano-ledger-mary
- [ ] cardano-ledger-alonzo
- [ ] cardano-ledger-conway

### Lib Packages
- [ ] cardano-ledger-core
- [ ] cardano-ledger-api
- [ ] cardano-protocol-tpraos
- [x] ⚠️ cardano-ledger-dijkstra - NULL (doesn't exist in thunk /libs/)
- [ ] cardano-ledger-pretty
- [ ] cardano-data
- [ ] vector-map
- [ ] set-algebra
- [ ] non-integral
- [ ] small-steps
- [ ] small-steps-test
- [ ] byron-spec-chain
- [ ] byron-spec-ledger
- [x] 🔧 compact-map - From thunk (verify path)

---

## Recent IOHK Packages (GitHub sourced)

### ✅ Verified GitHub Sources
- [x] 🔧 cuddle (0.5.0.0) - Manual derivation, cabal-version 3.4
- [x] 🔧 bifunctor-classes-compat (0.1) - haskell-compat/bifunctor-classes-compat
- [x] 🔧 foldable1-classes-compat (0.1.1) - haskell-compat/foldable1-classes-compat
- [x] 🔧 FailT (0.1.2.0) - lehins/FailT
- [x] 🔧 ImpSpec (0.1.0.0) - input-output-hk/ImpSpec
- [x] 🔧 mempack (0.1.1.0) - lehins/mempack
- [x] 🔧 data-array-byte (0.1.0.1) - Bodigrim/data-array-byte
- [x] 🔧 prettyprinter-configurable (1.0.0.0) - effectfully/prettyprinter-configurable
- [x] 🔧 fs-api (0.3.0.1) - IntersectMBO/fs-sim monorepo
- [x] 🔧 resource-registry (0.2.0.0) - IntersectMBO/io-classes-extra monorepo

---

## IOHK Monitoring Framework (from deps.iohk-monitoring-framework)

- [ ] contra-tracer
- [ ] iohk-monitoring
- [ ] tracer-transformers
- [ ] lobemo-backend-trace-forwarder
- [ ] lobemo-backend-monitoring
- [ ] lobemo-backend-aggregation
- [ ] lobemo-backend-ekg
- [ ] lobemo-scribe-systemd

---

## Ouroboros Network/Consensus (from deps.ouroboros-network, deps.ouroboros-consensus)

- [ ] ouroboros-network-framework
- [ ] ouroboros-network-testing
- [ ] ouroboros-consensus
- [ ] ouroboros-consensus-byron
- [ ] ouroboros-consensus-shelley
- [ ] ouroboros-consensus-cardano
- [ ] monoidal-synchronisation
- [ ] network-mux
- [ ] ntp-client

---

## Cardano Node (from deps.cardano-node)

- [ ] cardano-node
- [ ] cardano-cli
- [ ] cardano-config
- [ ] hedgehog-extras (from deps.hedgehog-extras)

---

## Plutus (from deps.plutus)

- [ ] plutus-ledger
- [ ] freer-extras
- [ ] playground-common
- [ ] plutus-chain-index
- [ ] plutus-contract
- [ ] plutus-pab
- [ ] plutus-tx-plugin
- [ ] plutus-use-cases
- [ ] quickcheck-dynamic
- [ ] word-array

---

## Cardano Addresses (from deps.cardano-addresses)

- [ ] cardano-addresses
- [ ] cardano-addresses-cli

---

## IO-Sim/Typed-Protocols (from deps.io-sim, deps.typed-protocols)

- [ ] io-classes
- [ ] io-sim
- [ ] strict-stm
- [ ] strict-checked-vars (from deps.strict-checked-vars)
- [ ] typed-protocols
- [ ] typed-protocols-cborg
- [ ] typed-protocols-examples

---

## Other IOHK Dependencies

- [ ] ekg-json (from deps.ekg-json)
- [ ] Win32-network (from deps.Win32-network)
- [ ] cardano-sl-x509 (from deps.cardano-sl-x509)
- [ ] goblins (from deps.goblins)
- [ ] bech32 (from deps.bech32 + "/bech32")
- [ ] bech32-th (from deps.bech32 + "/bech32-th")
- [ ] optparse-applicative-fork (from deps.optparse-applicative)
- [ ] servant-purescript (from deps.servant-purescript)
- [ ] purescript-bridge (from deps.purescript-bridge)
- [x] ⚠️ cardano-crypto-test - NULL (missing cabal file)
- [ ] cardano-ledger-binary (alias to cardano-binary)
- [ ] cardano-prelude-test (from deps.cardano-prelude)
- [ ] cardano-crypto-wrapper

---

## Hackage Packages (callHackage - verify versions)

### Standard Libraries
- [ ] pcg-random (0.1.3.7)
- [ ] ekg (0.4.0.15)
- [ ] yaml (0.11.7.0)
- [ ] Unique (0.4.7.9)
- [ ] foldl (1.4.12)
- [ ] profunctors (5.6.2)
- [ ] contravariant (1.5.5)
- [ ] semigroupoids (5.3.7)
- [ ] StateVar (1.2.2)
- [ ] js-chart (2.9.4.1)
- [ ] lens (5.1)
- [ ] lens-aeson (1.1.3)
- [ ] free (5.1.7)
- [ ] microstache (1.0.2)
- [ ] aeson (2.0.2.0)
- [ ] aeson-pretty (0.8.9)
- [ ] hpack (0.34.5)
- [ ] deriving-aeson (0.2.8)
- [ ] semialign (1.2.0.1)
- [ ] openapi3 (3.1.0)
- [ ] servant-openapi3 (2.0.1.2)

### Servant Packages
- [ ] servant (0.18.3)
- [ ] servant-client (0.18.3)
- [ ] servant-client-core (0.18.3)
- [ ] servant-foreign (0.15.4)
- [ ] servant-options (0.1.0.0)
- [ ] servant-server (0.18.3)
- [ ] servant-subscriber (0.7.0.0)
- [ ] servant-websockets (2.0.0)
- [ ] servant-swagger-ui-core (0.3.5)
- [ ] servant-swagger-ui (0.3.5.3.47.1)

### Testing/Benchmarking
- [ ] tasty-bench (0.2.5)
- [ ] monoidal-containers (0.6.2.0)
- [ ] witherable (0.4.2)
- [ ] indexed-traversable (0.1.1)
- [ ] indexed-traversable-instances (0.1)
- [ ] smallcheck (1.2.1)
- [ ] katip (0.8.7.0)
- [ ] hspec-golden-aeson (0.9.0.0)
- [ ] tasty-golden (2.3.4)
- [ ] tasty (1.4.1)
- [ ] tasty-wai (0.1.1.1)
- [ ] hspec (2.8.2)
- [ ] hspec-core (2.8.2)
- [ ] hspec-discover (2.8.2)
- [ ] hspec-expectations (0.8.2)
- [ ] hspec-meta (2.7.8)
- [ ] QuickCheck (2.14.2)
- [ ] quickcheck-instances (0.3.27)
- [ ] hedgehog-quickcheck (0.1.1)
- [ ] tasty-hspec (1.2)
- [ ] generic-random (1.4.0.0)

### Data Structures
- [ ] text-short (0.1.5)
- [ ] tree-diff (0.2.1.1)
- [ ] swagger2 (2.6)
- [ ] recursion-schemes (5.2.2.2)
- [ ] generics-sop (0.5.1.2)
- [ ] nothunks (0.1.3)
- [ ] streaming-bytestring (0.2.1)
- [ ] text-conversions (0.3.1)
- [ ] base16-bytestring (1.0.2.0)
- [ ] unordered-containers (0.2.16.0)
- [ ] string-interpolate (0.3.1.1)
- [ ] wide-word (0.1.1.2)

### Time/Random
- [ ] time-compat (1.9.6)
- [ ] strict (0.4.0.1)
- [ ] vector (0.12.3.1)
- [ ] random (1.2.0)
- [ ] splitmix (0.1.0.3)

### Persistence
- [ ] persistent-test (2.13.0.0)
- [ ] persistent-sqlite (2.13.0.2)
- [ ] persistent-postgresql (2.13.0.3)
- [ ] persistent-template (2.12.0.0)
- [ ] lift-type (0.1.0.0)

### Misc
- [ ] tls (1.5.5)
- [ ] libsystemd-journal (1.4.5)
- [ ] beam-sqlite (0.5.0.0)
- [ ] scientific (0.3.7.0)
- [ ] integer-logarithms (1.0.3.1)
- [ ] th-compat (0.1.3)
- [ ] OneTuple (0.3.1)
- [ ] base16 (0.3.1.0)
- [ ] base-orphans (0.8.6)

---

## Packages from Thunked Deps

### Need Path Verification
- [ ] criterion (from deps.criterion)
- [ ] hw-aeson (from deps.hw-aeson) - 0.1.6.0
- [ ] ghcjs-base-stub (from deps.ghcjs-base-stub)
- [ ] memory (from deps.hs-memory) - 0.16
- [ ] persistent (from deps.persistent + "/persistent") - 2.13.1.2
- [ ] hedgehog (from deps.haskell-hedgehog + "/hedgehog")
- [ ] row-types (from deps.row-types) - 1.0.1.1
- [ ] base64-bytestring (from deps.base64-bytestring) - 1.2.1.0

---

## Packages with Overrides/Jailbreak (verify they still build)

- [ ] scrypt (platform override)
- [ ] size-based (doJailbreak)
- [ ] transformers-except (doJailbreak)
- [ ] trifecta (doJailbreak)
- [ ] rebase (doJailbreak)
- [ ] these-lens (doJailbreak)
- [ ] aeson-qq (dontCheck)
- [ ] dependent-sum-aeson-orphans (doJailbreak)
- [ ] http2 (dontCheck)
- [ ] http-media (doJailbreak)
- [ ] async-timer (doJailbreak + dontCheck + markUnbroken)
- [ ] OddWord (dontCheck + markUnbroken)
- [ ] quickcheck-state-machine (dontCheck + markUnbroken)
- [ ] cryptohash-md5 (dontCheck)
- [ ] cryptohash-sha1 (dontCheck)
- [ ] hs-rqlite (doJailbreak)
- [ ] blaze-markup (doJailbreak)
- [ ] natural-transformation (doJailbreak)
- [ ] tdigest (doJailbreak)
- [ ] binary-orphans (doJailbreak)
- [ ] bytestring-type (doJailbreak)
- [ ] base64-bytestring-type (doJailbreak)
- [ ] lattices (doJailbreak)
- [ ] insert-ordered-containers (doJailbreak)
- [ ] lzma (dontCheck)
- [ ] aeson-casing (dontCheck)
- [ ] persistent-qq (dontCheck)
- [ ] moo (dontCheck + markUnbroken)
- [ ] gray-code (markUnbroken + preCompileBuildDriver)
- [ ] cborg (dontCheck)
- [ ] canonical-json (dontCheck + doJailbreak + markUnbroken)
- [ ] fgl (doJailbreak)
- [ ] fgl-arbitrary (doJailbreak)
- [ ] graphviz (dontCheck)
- [ ] hedgehog-fn (doJailbreak)
- [ ] attoparsec (doJailbreak)
- [ ] http-api-data (doJailbreak)
- [ ] algebraic-graphs (doJailbreak + dontCheck)
- [ ] cassava (doJailbreak)
- [ ] psqueues (doJailbreak)
- [ ] tasty-hedgehog (doJailbreak)
- [ ] tasty-discover (dontCheck)
- [ ] test-framework (doJailbreak)
- [ ] test-framework-quickcheck2 (doJailbreak)
- [ ] dom-lt (markUnbroken)
- [ ] jsaddle (doJailbreak)
- [ ] webdriver (doJailbreak + patch for aeson 2)
- [ ] validation (doJailbreak)
- [ ] validation-selective (dontCheck)
- [x] ⚠️ sqlite - NULL

---

## Next Steps

1. **Extract package list programmatically**
   ```bash
   # Get all package names from default.nix
   grep -E '^\s+[a-z][a-z0-9-]+ =' cardano-project/cardano-overlays/cardano-packages/default.nix | \
     sed 's/^\s*//' | sed 's/ =.*//' | sort -u > package-names.txt
   ```

2. **Batch check Hackage availability**
   ```bash
   # For each package, curl https://hackage.haskell.org/package/{name}
   # Mark which ones return 200 vs 404
   ```

3. **Batch check all-cabal-hashes**
   ```bash
   # For each package, curl https://github.com/commercialhaskell/all-cabal-hashes/tree/master/{name}
   # Mark which ones return 200 vs 404
   ```

4. **Identify missing packages**
   - On Hackage but NOT in all-cabal-hashes → Need GitHub source
   - Not on Hackage → Check if from thunk or needs different source

5. **Verify thunk paths**
   - For each package from deps.X thunk, read thunk's github.json
   - Check GitHub at that commit for the path
   - Set to null if path doesn't exist

6. **Update all missing packages in one commit**
   - Add all GitHub sources with verified hashes
   - Update all package versions
   - Single rebuild to test everything

---

## Pattern Recognition

Based on packages fixed so far:
- **All lehins packages** (FailT, mempack) → NOT in all-cabal-hashes, use GitHub
- **All recent IOHK packages** (cuddle, ImpSpec, fs-api, resource-registry) → NOT in all-cabal-hashes, use GitHub
- **Legacy Byron/Shelley-MA packages** → May not exist in modern cardano-ledger thunks
- **Monorepo packages** (fs-api, resource-registry) → Use callCabal2nixWithOptions with --subpath

---

## Verification Commands

### Check Hackage
```bash
fetch_webpage "https://hackage.haskell.org/package/{package-name}"
```

### Check all-cabal-hashes
```bash
fetch_webpage "https://github.com/commercialhaskell/all-cabal-hashes/tree/master/{package-name}"
```

### Check GitHub tags
```bash
fetch_webpage "https://github.com/{owner}/{repo}/tags"
```

### Get SHA256 hash
```bash
docker run --rm nixos/nix:latest nix-prefetch-url --unpack https://github.com/{owner}/{repo}/archive/{commit}.tar.gz
```

### Verify thunk path
```bash
# 1. Read thunk github.json
cat deps/{thunk-name}/github.json

# 2. Check path on GitHub
fetch_webpage "https://github.com/{owner}/{repo}/tree/{commit}/{path}"
```
