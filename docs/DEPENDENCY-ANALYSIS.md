# Comprehensive Dependency Analysis

Generated from analyzing all `.cabal` files in workspace.

## Summary

- **Workspace .cabal files**: 5 (backend, frontend, common, hydra-pay, hydra-pay-core)
- **Direct dependencies found**: 82 unique packages
- **Already defined in overlay**: 13
- **Standard libraries**: 11 (base, mtl, text, containers, etc.)
- **Our own packages**: 5 (backend, frontend, common, hydra-pay, hydra-pay-core)
- **Missing from overlay**: 53

## Missing Dependencies Breakdown

### From Existing Thunks (Already in dep/)

These packages should come from thunks we already have:

1. **aeson-gadt-th** → `dep/aeson-gadt-th` ✅
2. **bytestring-aeson-orphans** → `dep/bytestring-aeson-orphans` ✅
3. **constraints-extras** → `dep/constraints-extras` ✅
4. **optparse-applicative** → `cardano-project/cardano-overlays/cardano-packages/dep/optparse-applicative` ✅
5. **reflex** → `dep/reflex` ✅
6. **reflex-gadt-api** → `dep/reflex-gadt-api` ✅
7. **snap-core** → `dep/snap-core` ✅

### From Monorepo Thunks (Subpackages)

These come from monorepo thunks - need to verify paths:

#### Obelisk packages (from `dep/obelisk`)
- Commit: `58c04270d606c061e7ffd2f16345e0f451eba600`
- Verified paths in `/lib`:
  - `obelisk-backend` → `/lib/backend` ✅ EXISTS
  - `obelisk-frontend` → `/lib/frontend` ✅ EXISTS
  - `obelisk-route` → `/lib/route` ✅ EXISTS
  - `obelisk-executable-config-lookup` → `/lib/executable-config` (NEED TO VERIFY)
  - `obelisk-generated-static` → `/lib/?` (NEED TO VERIFY)

#### Reflex packages (from `dep/reflex`)
- Commit: `823afd9424234cbe0134051f09a6710e54509cec`
- Reflex is a single package repo (not a monorepo)
- `reflex-dom` → **NOT in this thunk** (separate repo: reflex-dom)
- `reflex-dom-core` → **NOT in this thunk** (separate repo: reflex-dom)
- `reflex-fsnotify` → **NOT in this thunk** (need to check)

#### Rhyolite packages (from `cardano-project/dep/rhyolite`)
- Commit: `8a10a67835c80a4a838e5ddd6b69451a77998c9b`
- Verified `/beam` has subdirs: `db`, `orphans`, `task`
- `rhyolite-beam-db` → `/beam/db` ✅ EXISTS
- `rhyolite-beam-task-worker-backend` → `/beam/task/?` (NEED TO VERIFY)
- `rhyolite-beam-task-worker-types` → `/beam/task/?` (NEED TO VERIFY)

#### Cardano packages (from `dep/cardano-node`)
- Commit: `ca1ec278070baf4481564a6ba7b4a5b9e3d9f366`
- `cardano-api` → **❌ DOES NOT EXIST** at this commit (404)
- `cardano-transaction` → **NEED TO CHECK** (not standard cardano-node package)

### From Hackage (Need to add to overlay)

These packages don't come from our thunks and need to be fetched from Hackage:

1. **async** - Standard async library
2. **beam-automigrate** - Database migration for beam
3. **beam-core** - Beam SQL library core
4. **beam-postgres** - Beam PostgreSQL backend
5. **case-insensitive** - Case insensitive strings
6. **cryptonite** - Cryptography library
7. **dependent-sum** - Dependent sums
8. **fsnotify** - File system notifications
9. **gargoyle** - Gargoyle framework
10. **gargoyle-postgresql** - PostgreSQL support for gargoyle
11. **gargoyle-postgresql-connect** - Connection handling
12. **gargoyle-postgresql-nix** - Nix integration
13. **hexstring** - Hex string handling (may be `haskell-hexstring` thunk?)
14. **http-client** - HTTP client library
15. **http-conduit** - HTTP conduit
16. **io-streams** - IO streams
17. **logging-effect** - Logging effects
18. **managed** - Resource management
19. **monad-logger** - Monad-based logging
20. **monad-loops** - Monad loop constructs
21. **network** - Network library
22. **postgresql-simple** - PostgreSQL simple interface
23. **prettyprinter** - Pretty printing
24. **resource-pool** - Resource pooling
25. **snap-server** - Snap server
26. **some** - Existential wrapper
27. **temporary** - Temporary file/directory support
28. **typed-process** - Type-safe process handling
29. **utf8-string** - UTF8 strings
30. **uuid** - UUID generation
31. **websockets** - WebSocket support
32. **websockets-snap** - WebSocket integration for Snap
33. **which** - Find executables

## Action Items

### Immediate: Verify Monorepo Paths

Need to check on GitHub at specific commits:

1. **Obelisk** (58c04270):
   - `/lib/executable-config` for `obelisk-executable-config-lookup`
   - Find location for `obelisk-generated-static`

2. **Reflex-DOM** (separate from reflex):
   - We DON'T have a reflex-dom thunk!
   - Need to add: `dep/reflex-dom`
   - Or use from Hackage if available

3. **Rhyolite** (8a10a67):
   - `/beam/task/` subdirs for worker packages

4. **Cardano** - CRITICAL:
   - `cardano-api` does NOT exist in our cardano-node thunk!
   - Need to either:
     a. Update cardano-node thunk to newer version with cardano-api
     b. Add separate cardano-api thunk
     c. Use from Hackage (check if available)

### Next Steps

1. ✅ Created comprehensive dependency analysis
2. ⏭️ Verify remaining monorepo paths on GitHub
3. ⏭️ Check Hackage for `cardano-api` availability
4. ⏭️ Add missing packages to overlay with correct sources
5. ⏭️ Test build with all dependencies added

## Already Defined (No Action Needed)

These are correctly defined in the overlay:

- aeson
- attoparsec
- base (stdlib)
- bytestring (stdlib)
- containers (stdlib)
- deepseq
- directory (stdlib)
- filepath (stdlib)
- lens
- mtl (stdlib)
- process (stdlib)
- stm (stdlib)
- template-haskell (stdlib)
- text (stdlib)
- time (stdlib)
- transformers (stdlib)
- unix (stdlib)

## Notes

- **Standard libraries** are provided by GHC/nixpkgs - no action needed
- **Our own packages** are workspace packages - no action needed
- **Monorepo packages** require `--subpath` in callCabal2nix
- **GitHub packages** need commit hash and SHA256 from nix-prefetch-url
- **Old thunks** like cardano-node at ca1ec27 may be missing expected packages
