# Cabal Dependency Analysis

This report analyzes all `.cabal` files in the workspace to identify dependencies
and checks if they're defined in our Nix overlay.

## Summary
- Total .cabal files: 5
- Unique dependencies found: 82
- Packages defined in overlay: 233
- Missing from overlay: 58
- Set to null in overlay: 0

## Legend
- ✅ Defined in overlay
- ❌ NOT defined in overlay (will cause build failure if used)
- ⚠️ Set to null in overlay (path doesn't exist in thunk)
- 📦 Standard library (provided by GHC/nixpkgs)

---

## Analysis

| ✅ | `aeson` | Defined in overlay |
| ❌ | `aeson-gadt-th` | **NOT DEFINED** - will cause build failure if needed |
| ✅ | `aeson-pretty` | Defined in overlay |
| ❌ | `async` | **NOT DEFINED** - will cause build failure if needed |
| ✅ | `attoparsec` | Defined in overlay |
| ❌ | `backend` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `base` | Standard library |
| ✅ | `base64-bytestring` | Defined in overlay |
| ❌ | `beam-automigrate` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `beam-core` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `beam-postgres` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `bytestring` | Standard library |
| ❌ | `bytestring-aeson-orphans` | **NOT DEFINED** - will cause build failure if needed |
| ✅ | `cardano-addresses` | Defined in overlay |
| ❌ | `cardano-api` | **NOT DEFINED** - will cause build failure if needed |
| ✅ | `cardano-ledger-core` | Defined in overlay |
| ❌ | `cardano-transaction` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `case-insensitive` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `common` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `constraints-extras` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `containers` | Standard library |
| ❌ | `cryptonite` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `dependent-sum` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `directory` | Standard library |
| 📦 | `filepath` | Standard library |
| ❌ | `frontend` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `fsnotify` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `gargoyle` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `gargoyle-postgresql` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `gargoyle-postgresql-connect` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `gargoyle-postgresql-nix` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `hexstring` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `http-client` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `http-conduit` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `hydra-pay` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `hydra-pay-core` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `io-streams` | **NOT DEFINED** - will cause build failure if needed |
| ✅ | `jsaddle` | Defined in overlay |
| ✅ | `lens` | Defined in overlay |
| ✅ | `lens-aeson` | Defined in overlay |
| ❌ | `logging-effect` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `managed` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `monad-logger` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `monad-loops` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `mtl` | Standard library |
| ❌ | `network` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `obelisk-backend` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `obelisk-executable-config-lookup` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `obelisk-frontend` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `obelisk-generated-static` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `obelisk-route` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `optparse-applicative` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `postgresql-simple` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `prettyprinter` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `process` | Standard library |
| ✅ | `random` | Defined in overlay |
| ❌ | `reflex` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `reflex-dom` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `reflex-dom-core` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `reflex-fsnotify` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `reflex-gadt-api` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `resource-pool` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `rhyolite-beam-db` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `rhyolite-beam-task-worker-backend` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `rhyolite-beam-task-worker-types` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `snap-core` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `snap-server` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `some` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `stm` | Standard library |
| ✅ | `string-interpolate` | Defined in overlay |
| ❌ | `temporary` | **NOT DEFINED** - will cause build failure if needed |
| 📦 | `text` | Standard library |
| 📦 | `time` | Standard library |
| ✅ | `time-compat` | Defined in overlay |
| 📦 | `transformers` | Standard library |
| ❌ | `typed-process` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `utf8-string` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `uuid` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `websockets` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `websockets-snap` | **NOT DEFINED** - will cause build failure if needed |
| ❌ | `which` | **NOT DEFINED** - will cause build failure if needed |
| ✅ | `witherable` | Defined in overlay |
