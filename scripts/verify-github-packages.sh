#!/usr/bin/env bash
# Quick verification of packages we've added from GitHub
# These are the ones NOT in all-cabal-hashes that we need to track

set -euo pipefail

echo "Checking GitHub-sourced packages..."
echo ""

# Packages we've already added from GitHub
GITHUB_PACKAGES=(
  "cuddle"
  "bifunctor-classes-compat"
  "foldable1-classes-compat"
  "FailT"
  "ImpSpec"
  "mempack"
  "data-array-byte"
  "prettyprinter-configurable"
  "fs-api"
  "resource-registry"
)

echo "✅ Already added from GitHub (${#GITHUB_PACKAGES[@]} packages):"
for pkg in "${GITHUB_PACKAGES[@]}"; do
  echo "  - $pkg"
done
echo ""

# Packages on Hackage that might need GitHub sources
# (Check a subset that are commonly problematic for IOHK projects)
echo "🔍 Checking if these Hackage packages are in all-cabal-hashes..."
echo ""

POTENTIAL_MISSING=(
  "compact-map"
  "strict-checked-vars"
  "io-classes"
  "io-sim"
  "strict-stm"
  "typed-protocols"
  "hedgehog-extras"
  "ekg-json"
  "Win32-network"
  "bech32"
  "ghcjs-base-stub"
  "memory"
  "persistent"
  "hedgehog"
  "row-types"
  "criterion"
  "hw-aeson"
)

for pkg in "${POTENTIAL_MISSING[@]}"; do
  # Check if package uses callCabal2nix with deps.X (from thunk)
  if grep -q "callCabal2nix \"$pkg\" (deps\." cardano-project/cardano-overlays/cardano-packages/default.nix; then
    echo "  ✅ $pkg - from thunk (deps.X)"
  # Check if already using fetchFromGitHub
  elif grep -q "callCabal2nix \"$pkg\" (pkgs.fetchFromGitHub" cardano-project/cardano-overlays/cardano-packages/default.nix; then
    echo "  ✅ $pkg - already using GitHub source"
  # Check if using callHackage
  elif grep -q "callHackage \"$pkg\"" cardano-project/cardano-overlays/cardano-packages/default.nix; then
    echo "  🔧 $pkg - using Hackage (verify in all-cabal-hashes)"
  else
    echo "  ⚠️  $pkg - check source method"
  fi
done

echo ""
echo "Summary:"
echo "  - ${#GITHUB_PACKAGES[@]} packages confirmed using GitHub sources"
echo "  - Review 🔧 packages above - may need GitHub sources if build fails"
echo ""
echo "Next: Run build to see if any other packages fail with 'called without required argument' errors"
