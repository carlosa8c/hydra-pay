#!/usr/bin/env bash
# Check cabal-version in all thunk-based packages that use callCabal2nix

set -euo pipefail

echo "Checking cabal-version in packages from thunks..."
echo "================================================"
echo ""

# Known problematic: io-classes from io-sim thunk
THUNKS=(
  "dep/io-sim:io-classes:io-classes/io-classes.cabal"
  "dep/io-sim:io-sim:io-sim/io-sim.cabal"
  "dep/io-sim:strict-stm:strict-stm/strict-stm.cabal"
  "dep/typed-protocols:typed-protocols:typed-protocols/typed-protocols.cabal"
  "dep/typed-protocols:typed-protocols-cborg:typed-protocols-cborg/typed-protocols-cborg.cabal"
  "cardano-project/dep/ouroboros-network:ouroboros-network:ouroboros-network/ouroboros-network.cabal"
  "cardano-project/dep/ouroboros-network:ouroboros-network-api:ouroboros-network-api/ouroboros-network-api.cabal"
  "cardano-project/dep/ouroboros-network:ouroboros-network-framework:ouroboros-network-framework/ouroboros-network-framework.cabal"
  "cardano-project/dep/ouroboros-network:ouroboros-network-protocols:ouroboros-network-protocols/ouroboros-network-protocols.cabal"
  "cardano-project/dep/ouroboros-consensus:ouroboros-consensus-diffusion:ouroboros-consensus-diffusion/ouroboros-consensus-diffusion.cabal"
  "cardano-project/dep/ouroboros-consensus:ouroboros-consensus-protocol:ouroboros-consensus-protocol/ouroboros-consensus-protocol.cabal"
  "cardano-project/dep/cardano-ledger:cardano-ledger-core:libs/cardano-ledger-core/cardano-ledger-core.cabal"
  "cardano-project/dep/cardano-ledger:cardano-ledger-binary:libs/cardano-ledger-binary/cardano-ledger-binary.cabal"
  "cardano-project/dep/cardano-ledger:cardano-ledger-api:libs/cardano-ledger-api/cardano-ledger-api.cabal"
)

ISSUES_FOUND=0
TOTAL_CHECKED=0

for entry in "${THUNKS[@]}"; do
  IFS=':' read -r thunk_path package_name cabal_rel_path <<< "$entry"
  
  # Get the github.json to find the commit
  github_json="$thunk_path/.git-thunk/github.json"
  
  if [[ ! -f "$github_json" ]]; then
    echo "⚠️  Missing: $github_json"
    continue
  fi
  
  rev=$(grep '"rev"' "$github_json" | cut -d'"' -f4)
  owner=$(grep '"owner"' "$github_json" | cut -d'"' -f4)
  repo=$(grep '"repo"' "$github_json" | cut -d'"' -f4)
  
  echo "Checking: $package_name"
  echo "  Thunk: $thunk_path"
  echo "  Repo: $owner/$repo @ ${rev:0:8}"
  
  # Try to find the .cabal file in the checked-out thunk
  cabal_file="$thunk_path/$cabal_rel_path"
  
  if [[ -f "$cabal_file" ]]; then
    cabal_version=$(grep -i "^cabal-version:" "$cabal_file" | head -1 | awk '{print $2}' | tr -d '\r')
    echo "  cabal-version: $cabal_version"
    
    # Check if it's >= 3.4 (which requires modern cabal2nix)
    if [[ -n "$cabal_version" ]]; then
      major=$(echo "$cabal_version" | cut -d. -f1)
      minor=$(echo "$cabal_version" | cut -d. -f2 | cut -d' ' -f1)
      
      if [[ "$major" -gt 3 ]] || [[ "$major" -eq 3 && "$minor" -ge 4 ]]; then
        echo "  ⚠️  REQUIRES PRE-GENERATION (cabal-version >= 3.4)"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
      else
        echo "  ✅ OK (supported by nixpkgs cabal2nix)"
      fi
    fi
  else
    echo "  ⚠️  .cabal file not found at: $cabal_file"
    echo "     (Thunk may not be materialized yet)"
  fi
  
  echo ""
  TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
done

echo "================================================"
echo "Summary: Checked $TOTAL_CHECKED packages"
if [[ $ISSUES_FOUND -gt 0 ]]; then
  echo "⚠️  Found $ISSUES_FOUND package(s) requiring pre-generation"
  echo ""
  echo "These packages need .nix files generated with cabal2nix 2.20.1+"
  echo "and saved to cardano-project/cardano-overlays/generated-nix-expressions/"
else
  echo "✅ All checked packages compatible with nixpkgs cabal2nix"
fi
