#!/usr/bin/env bash
# Script to add all missing dependencies from our .cabal analysis
# Run this after reviewing DEPENDENCY-ANALYSIS.md

set -euo pipefail

OVERLAY_FILE="cardano-project/cardano-overlays/cardano-packages/default.nix"

echo "🚀 Adding Missing Dependencies to Overlay"
echo "========================================="
echo ""

# Check if we should proceed
echo "This will add ~50 package definitions to:"
echo "  $OVERLAY_FILE"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Step 1: Adding packages from existing thunks..."
echo "================================================"

cat >> "$OVERLAY_FILE" << 'EOF'

  # === Packages from our .cabal analysis ===
  # Added based on comprehensive dependency analysis
  
  # From dep/aeson-gadt-th thunk
  aeson-gadt-th = self.callCabal2nix "aeson-gadt-th" deps.aeson-gadt-th {};
  
  # From dep/bytestring-aeson-orphans thunk  
  bytestring-aeson-orphans = self.callCabal2nix "bytestring-aeson-orphans" deps.bytestring-aeson-orphans {};
  
  # From dep/constraints-extras thunk
  constraints-extras = self.callCabal2nix "constraints-extras" deps.constraints-extras {};
  
  # From dep/reflex thunk
  reflex = haskellLib.dontCheck (self.callCabal2nix "reflex" deps.reflex {});
  
  # From dep/reflex-gadt-api thunk
  reflex-gadt-api = self.callCabal2nix "reflex-gadt-api" deps.reflex-gadt-api {};
  
  # From dep/snap-core thunk
  snap-core = self.callCabal2nix "snap-core" deps.snap-core {};

  # === Obelisk monorepo packages (from dep/obelisk) ===
  obelisk-backend = self.callCabal2nixWithOptions "obelisk-backend" deps.obelisk "--subpath lib/backend" {};
  obelisk-frontend = self.callCabal2nixWithOptions "obelisk-frontend" deps.obelisk "--subpath lib/frontend" {};
  obelisk-route = self.callCabal2nixWithOptions "obelisk-route" deps.obelisk "--subpath lib/route" {};
  obelisk-executable-config-lookup = self.callCabal2nixWithOptions "obelisk-executable-config-lookup" deps.obelisk "--subpath lib/executable-config/lookup" {};
  # Note: obelisk-generated-static - need to find correct path
  
  # === Rhyolite monorepo packages (from cardano-project/dep/rhyolite) ===
  rhyolite-beam-db = self.callCabal2nixWithOptions "rhyolite-beam-db" deps.rhyolite "--subpath beam/db" {};
  rhyolite-beam-task-worker-backend = self.callCabal2nixWithOptions "rhyolite-beam-task-worker-backend" deps.rhyolite "--subpath beam/task/backend" {};
  rhyolite-beam-task-worker-types = self.callCabal2nixWithOptions "rhyolite-beam-task-worker-types" deps.rhyolite "--subpath beam/task/types" {};

EOF

echo "✅ Added thunk-based packages"
echo ""

echo "Step 2: Packages needing Hackage/manual checking..."
echo "===================================================="
echo ""
echo "The following packages still need to be added:"
echo ""
echo "CRITICAL - cardano-api:"
echo "  ❌ NOT on Hackage!"
echo "  ❌ NOT in our cardano-node thunk (commit ca1ec27)"
echo "  ➡️  ACTION REQUIRED: Need to find correct source"
echo "     Options:"
echo "       a) Update cardano-node thunk to newer version"
echo "       b) Add separate cardano-api thunk"
echo "       c) Check if it's in a different Cardano repo"
echo ""

echo "reflex-dom packages:"
echo "  ✅ reflex-dom: Available on Hackage (0.6.3.4)"
echo "  ✅ reflex-dom-core: Available on Hackage"
echo "  ❓ reflex-fsnotify: Need to check"
echo "  ➡️  Add these via callHackage"
echo ""

echo "Standard Hackage packages (33 total):"
echo "  - async, beam-*, case-insensitive, cryptonite"
echo "  - dependent-sum, fsnotify, gargoyle*, hexstring"
echo "  - http-client, http-conduit, io-streams, logging-effect"
echo "  - managed, monad-logger, monad-loops, network"
echo "  - postgresql-simple, prettyprinter, resource-pool"
echo "  - snap-server, some, temporary, typed-process"
echo "  - utf8-string, uuid, websockets, websockets-snap, which"
echo "  ➡️  Need to verify versions and add with callHackage"
echo ""

echo "Next steps:"
echo "1. ✅ Basic thunk packages added to overlay"
echo "2. ⏭️  Investigate cardano-api source (CRITICAL)"
echo "3. ⏭️  Add reflex-dom packages from Hackage"
echo "4. ⏭️  Add remaining Hackage packages (check versions first)"
echo "5. ⏭️  Test build"
echo ""
echo "See DEPENDENCY-ANALYSIS.md for complete details"
