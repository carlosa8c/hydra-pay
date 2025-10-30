#!/usr/bin/env bash
set -euo pipefail

# Script to check which packages referenced via super.* don't exist in GHC 9.6.7

OVERLAY_FILE="cardano-project/cardano-overlays/cardano-packages/default.nix"

echo "Checking for packages that reference super.* in $OVERLAY_FILE..."
echo ""

# Extract package names that reference super.something
grep -E '^\s+\w+\s*=.*super\.\w+' "$OVERLAY_FILE" | \
  grep -v '^#' | \
  sed -E 's/.*super\.([a-zA-Z0-9_-]+).*/\1/' | \
  sort -u > /tmp/super-packages.txt

echo "Found $(wc -l < /tmp/super-packages.txt) unique packages referencing super.*"
echo ""

# Try to build a test expression that checks if each package exists
cat > /tmp/check-packages.nix << 'EOF'
let
  pkgs = import <nixpkgs> {};
  haskell = pkgs.haskell;
  # Use GHC 9.6.7 package set
  hsPkgs = haskell.packages.ghc967;
in
{
  checkPackage = name:
    if hsPkgs ? ${name}
    then { package = name; exists = true; }
    else { package = name; exists = false; };
}
EOF

echo "Checking each package against GHC 9.6.7 package set..."
echo ""
echo "Packages that DO NOT EXIST:"
echo "=========================="

while IFS= read -r pkg; do
  # Check if package exists in ghc967
  if nix-instantiate --eval --expr "
    let
      pkgs = import <nixpkgs> {};
      hsPkgs = pkgs.haskell.packages.ghc967;
    in
      hsPkgs ? $pkg
  " 2>/dev/null | grep -q "false"; then
    echo "  ❌ $pkg"
    # Find the line in the original file
    grep -n "super\.$pkg" "$OVERLAY_FILE" | head -1
  fi
done < /tmp/super-packages.txt

echo ""
echo "Checking complete!"
