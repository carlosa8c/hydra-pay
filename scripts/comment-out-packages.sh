#!/usr/bin/env bash
# Script to comment out all direct package definitions that cause haskell.nix module errors
# These are lines like: package-name = ... that define new packages

FILE="cardano-project/cardano-overlays/cardano-packages/default.nix"

# Backup original
cp "$FILE" "$FILE.backup"

# Find lines that are direct package definitions (not super.* overrides, not callHackage for versions)
# Pattern: starts with spaces, has identifier, =, and either callCabal2nix, callPackage, or fetchFromGitHub/fetchzip on same or next line

echo "Commenting out direct package definitions in $FILE..."
echo "Backup saved to $FILE.backup"

# This will be a manual process - let me just list them first
echo ""
echo "Direct package definitions found:"
grep -n "^\s\+[a-zA-Z0-9_-]\+\s*=.*\(callCabal2nix\|callPackage.*generated-nix\|fetchFromGitHub\|fetchzip\)" "$FILE" | head -20
