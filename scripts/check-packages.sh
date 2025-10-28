#!/usr/bin/env bash
# Batch check package availability on Hackage and all-cabal-hashes
# Usage: ./scripts/check-packages.sh

set -euo pipefail

OVERLAY_FILE="cardano-project/cardano-overlays/cardano-packages/default.nix"
OUTPUT_FILE="package-check-results.md"

# Extract package names from overlay (exclude comments, null assignments, and aliases)
# Only match lines that are package definitions (start with 2 spaces, have package name, then = )
# Exclude lines inside fetchFromGitHub blocks (they have more indentation)
echo "Extracting package names from $OVERLAY_FILE..."
PACKAGES=$(grep -E '^  [a-z][a-z0-9-]+ =' "$OVERLAY_FILE" | \
  grep -v '= null' | \
  sed 's/^  //' | \
  sed 's/ =.*//' | \
  sort -u)

TOTAL=$(echo "$PACKAGES" | wc -l | tr -d ' ')
echo "Found $TOTAL packages to check"

# Initialize output file
cat > "$OUTPUT_FILE" << 'EOF'
# Package Availability Check Results

Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Summary
- Total packages checked: TOTAL_PLACEHOLDER
- On Hackage: HACKAGE_COUNT
- In all-cabal-hashes: ALL_CABAL_COUNT
- Missing from all-cabal-hashes: MISSING_COUNT

## Legend
- ✅ On Hackage AND in all-cabal-hashes
- 🔧 On Hackage but NOT in all-cabal-hashes (needs GitHub source)
- ❌ NOT on Hackage (verify source)

---

EOF

HACKAGE_COUNT=0
ALL_CABAL_COUNT=0
MISSING_COUNT=0
CURRENT=0

echo "" >> "$OUTPUT_FILE"
echo "## Package Details" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

while IFS= read -r package; do
  CURRENT=$((CURRENT + 1))
  echo "[$CURRENT/$TOTAL] Checking $package..."
  
  # Check Hackage (using curl with timeout)
  HACKAGE_STATUS="❌"
  if curl -s -f -m 5 "https://hackage.haskell.org/package/$package" > /dev/null 2>&1; then
    HACKAGE_STATUS="✅"
    HACKAGE_COUNT=$((HACKAGE_COUNT + 1))
  fi
  
  # Check all-cabal-hashes (using curl with timeout)
  ALL_CABAL_STATUS="❌"
  if curl -s -f -m 5 "https://raw.githubusercontent.com/commercialhaskell/all-cabal-hashes/master/$package/$package.cabal" > /dev/null 2>&1; then
    ALL_CABAL_STATUS="✅"
    ALL_CABAL_COUNT=$((ALL_CABAL_COUNT + 1))
  fi
  
  # Determine overall status
  if [ "$HACKAGE_STATUS" = "✅" ] && [ "$ALL_CABAL_STATUS" = "✅" ]; then
    OVERALL="✅"
  elif [ "$HACKAGE_STATUS" = "✅" ] && [ "$ALL_CABAL_STATUS" = "❌" ]; then
    OVERALL="🔧"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  else
    OVERALL="❌"
  fi
  
  # Write result
  echo "| $OVERALL | \`$package\` | Hackage: $HACKAGE_STATUS | all-cabal-hashes: $ALL_CABAL_STATUS |" >> "$OUTPUT_FILE"
  
  # Rate limit (be nice to servers)
  sleep 0.5
done <<< "$PACKAGES"

# Update summary
sed -i.bak "s/TOTAL_PLACEHOLDER/$TOTAL/" "$OUTPUT_FILE"
sed -i.bak "s/HACKAGE_COUNT/$HACKAGE_COUNT/" "$OUTPUT_FILE"
sed -i.bak "s/ALL_CABAL_COUNT/$ALL_CABAL_COUNT/" "$OUTPUT_FILE"
sed -i.bak "s/MISSING_COUNT/$MISSING_COUNT/" "$OUTPUT_FILE"
rm "${OUTPUT_FILE}.bak"

echo ""
echo "✅ Results written to $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "  Total: $TOTAL"
echo "  On Hackage: $HACKAGE_COUNT"
echo "  In all-cabal-hashes: $ALL_CABAL_COUNT"
echo "  Missing from all-cabal-hashes: $MISSING_COUNT"
echo ""
echo "Next steps:"
echo "  1. Review $OUTPUT_FILE for packages marked 🔧"
echo "  2. For each 🔧 package, find GitHub source and add to overlay"
echo "  3. Update dep-list.md with findings"
