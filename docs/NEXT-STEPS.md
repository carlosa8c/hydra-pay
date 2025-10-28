# Next Steps: Complete Dependency Resolution

## Summary of Findings

✅ **Created comprehensive dependency analysis** by parsing all .cabal files
✅ **Found 53 missing dependencies** that our code actually uses
✅ **Verified paths** for all monorepo packages on GitHub
✅ **Identified sources** for all packages (thunks vs Hackage vs new thunks needed)

## Critical Discovery

❌ **cardano-api** does NOT exist in our cardano-node thunk (commit ca1ec27)
✅ **Solution found**: It's a separate repo: https://github.com/IntersectMBO/cardano-api (123 releases)
➡️ **Action**: Need to add as a new thunk

## Immediate Next Steps (in order)

### 1. Add cardano-api Thunk (CRITICAL)
```bash
# Add the cardano-api repository as a thunk
mkdir -p dep/cardano-api
cat > dep/cardano-api/github.json << 'JSON'
{
  "owner": "IntersectMBO",
  "repo": "cardano-api",
  "branch": "master",
  "private": false,
  "rev": "NEED_TO_GET_LATEST_TAG",
  "sha256": "NEED_TO_COMPUTE"
}
JSON
```

Then check latest compatible version and add to overlay.

### 2. Run Add Dependencies Script
```bash
chmod +x scripts/add-missing-dependencies.sh
# Review it first, then run:
./scripts/add-missing-dependencies.sh
```

This will add ~15 packages from existing thunks to the overlay.

### 3. Add Hackage Packages
Add the following to overlay using callHackage or callHackageDirect:

**High priority (direct dependencies):**
- reflex-dom, reflex-dom-core (available on Hackage 0.6.3.4)
- async, dependent-sum, some
- postgresql-simple, resource-pool
- http-client, http-conduit
- websockets, websockets-snap
- snap-server (snap-core already from thunk)

**Beam ecosystem:**
- beam-core, beam-postgres, beam-automigrate

**Gargoyle (if needed - check if it's in rhyolite/obelisk):**
- gargoyle, gargoyle-postgresql, gargoyle-postgresql-connect, gargoyle-postgresql-nix

**Utilities:**
- case-insensitive, cryptonite, fsnotify, hexstring
- io-streams, logging-effect, managed, monad-logger, monad-loops
- network, prettyprinter, temporary, typed-process
- utf8-string, uuid, which

### 4. Verify Package Versions on Hackage
Before adding, check each package on Hackage for latest compatible version:
```bash
# Example:
curl -s https://hackage.haskell.org/package/reflex-dom | grep "Latest"
```

### 5. Test Build
```bash
./build-in-docker.sh > build-in-docker.log 2>&1 &
# Monitor with:
tail -f build-in-docker.log
```

### 6. Iterate on Errors
- For each "called without required argument X" error:
  - Check if X is in our missing deps list → add it
  - Check if X is a transitive dependency → check its .cabal file → add missing deps
  - Repeat until build succeeds

## Files Created

1. **DEPENDENCY-ANALYSIS.md** - Complete analysis of all dependencies
2. **recursive-dependency-analysis.md** - Categorized dependency report
3. **scripts/add-missing-dependencies.sh** - Script to add thunk-based packages
4. **scripts/analyze-dependencies-recursive.sh** - Tool to rerun analysis

## Progress Tracking

- [x] Analyzed all .cabal files (82 unique deps, 53 missing)
- [x] Verified monorepo paths on GitHub
- [x] Identified cardano-api source (separate repo)
- [ ] Add cardano-api thunk
- [ ] Add thunk-based packages to overlay (~15 packages)
- [ ] Add Hackage packages to overlay (~33 packages)
- [ ] Test build
- [ ] Fix remaining transitive dependencies
- [ ] Successful build!

## Key Insights

1. **Proactive approach works-la cardano-project/dep/rhyolite/ && cat cardano-project/dep/rhyolite/github.json 2>/dev/null* - Analyzing .cabal files found 53 packages upfront vs discovering one-by-one through build errors
2. **Old thunks are problematic** - cardano-node at ca1ec27 is missing expected packages
3. **Monorepos need verification** - Can't assume paths exist without checking on GitHub
4. **Transitive deps still exist** - Even after adding these 53, build may reveal more
5. **This is much faster** - One analysis session vs 53 build cycles at 5-10 min each = saved ~4-8 hours!
