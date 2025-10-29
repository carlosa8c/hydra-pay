#!/usr/bin/env bash
set -euo pipefail

# Script to generate .nix files for packages with cabal-version 3.8+
# These packages require cabal2nix built with Cabal library 3.12+

echo "==> Installing latest cabal-install using GHCup..."

# Install GHCup if not present
if ! command -v ghcup &> /dev/null; then
    echo "Installing GHCup..."
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
    source ~/.ghcup/env
fi

# Install latest GHC and cabal-install
echo "==> Installing latest GHC and cabal-install..."
ghcup install ghc latest --set
ghcup install cabal latest --set

# Update cabal package list
echo "==> Updating cabal package list..."
cabal update

# Install cabal2nix
echo "==> Installing cabal2nix..."
cabal install cabal2nix --overwrite-policy=always

# Create directory for generated .nix files
mkdir -p generated-nix-expressions

echo "==> Generating .nix file for cardano-api..."
cd dep/cardano-api
cabal2nix --subpath cardano-api . > ../../generated-nix-expressions/cardano-api.nix

echo "==> Done! Generated .nix files are in generated-nix-expressions/"
echo ""
echo "Next steps:"
echo "1. Review the generated file: generated-nix-expressions/cardano-api.nix"
echo "2. Update cardano-overlays/cardano-packages/default.nix to import it"
echo "3. Commit the generated file to the repo"
