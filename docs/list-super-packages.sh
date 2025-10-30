#!/usr/bin/env bash
set -euo pipefail

# Extract all super.* package references from the overlay file
echo "Extracting package names that reference super.*..."
grep -E '^\s+[a-zA-Z0-9_-]+\s*=.*super\.[a-zA-Z0-9_-]+' \
  cardano-project/cardano-overlays/cardano-packages/default.nix | \
  grep -v '^#' | \
  grep -v '^\s*//' | \
  sed -E 's/.*super\.([a-zA-Z0-9_-]+).*/\1/' | \
  sort -u > /tmp/super-packages.txt

echo "Found $(wc -l < /tmp/super-packages.txt) packages"
echo ""
cat /tmp/super-packages.txt
