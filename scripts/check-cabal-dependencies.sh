#!/usr/bin/env bash
# Comprehensive dependency checker that analyzes .cabal files
# Finds all dependencies used by the project and checks if they're defined

set -euo pipefail

OVERLAY_FILE="cardano-project/cardano-overlays/cardano-packages/default.nix"
OUTPUT_FILE="cabal-dependency-analysis.md"

echo "Analyzing .cabal files in workspace..."
echo ""

# Find all .cabal files (excluding result symlinks and .stack-work)
CABAL_FILES=$(find . -name "*.cabal" -type f ! -path "*/result/*" ! -path "*/.stack-work/*" ! -path "*/dist-newstyle/*" | sort)

CABAL_COUNT=$(echo "$CABAL_FILES" | wc -l | tr -d ' ')
echo "Found $CABAL_COUNT .cabal files"

# Extract all build-depends from .cabal files
echo "Extracting dependencies..."
ALL_DEPS=$(
  for cabal in $CABAL_FILES; do
    # Extract build-depends sections properly
    awk '
      BEGIN { in_deps = 0 }
      
      # Start of build-depends section
      /^[[:space:]]*build-depends:/ {
        in_deps = 1
        # Get inline deps after colon if any
        line = $0
        sub(/^[[:space:]]*build-depends:[[:space:]]*/, "", line)
        if (line != "" && line !~ /^[[:space:]]*$/) print line
        next
      }
      
      # In build-depends section - continue with indented lines
      in_deps == 1 {
        # End section on blank line or new field (non-indented line with colon)
        if (/^[[:space:]]*$/) {
          in_deps = 0
          next
        }
        if (/^[a-zA-Z].*:/ && !/^[[:space:]]/) {
          in_deps = 0
          next
        }
        # Print indented dependency lines
        if (/^[[:space:]]+/) {
          print $0
        }
      }
    ' "$cabal"
  done | \
  # Split on commas
  tr ',' '\n' | \
  # Remove comments (everything after --)
  sed 's/--.*$//' | \
  # Remove leading/trailing whitespace
  sed 's/^[[:space:]]*//' | \
  sed 's/[[:space:]]*$//' | \
  # Extract package name only (before version constraints, braces, etc)
  sed 's/[[:space:]]*{.*$//' | \
  sed 's/[[:space:]]*[><=^].*$//' | \
  # Remove empty lines
  grep -v '^$' | \
  # Only keep valid package names (lowercase, numbers, hyphens)
  grep -E '^[a-z][a-z0-9-]*$' | \
  sort -u
)

DEP_COUNT=$(echo "$ALL_DEPS" | grep -v '^$' | wc -l | tr -d ' ')
echo "Found $DEP_COUNT unique dependencies in .cabal files"
echo ""

# Get packages defined in overlay
echo "Extracting defined packages from overlay..."
DEFINED_PACKAGES=$(grep -E '^  [a-z][a-z0-9-]+ =' "$OVERLAY_FILE" | \
  sed 's/^  //' | \
  sed 's/ =.*//' | \
  sort -u)

DEFINED_COUNT=$(echo "$DEFINED_PACKAGES" | wc -l | tr -d ' ')
echo "Found $DEFINED_COUNT packages defined in overlay"
echo ""

# Generate report
cat > "$OUTPUT_FILE" << 'EOF'
# Cabal Dependency Analysis

This report analyzes all `.cabal` files in the workspace to identify dependencies
and checks if they're defined in our Nix overlay.

## Summary
- Total .cabal files: CABAL_COUNT
- Unique dependencies found: DEP_COUNT
- Packages defined in overlay: DEFINED_COUNT
- Missing from overlay: MISSING_COUNT
- Set to null in overlay: NULL_COUNT

## Legend
- ✅ Defined in overlay
- ❌ NOT defined in overlay (will cause build failure if used)
- ⚠️ Set to null in overlay (path doesn't exist in thunk)
- 📦 Standard library (provided by GHC/nixpkgs)

---

## Analysis

EOF

# Standard libraries that don't need to be in overlay
STANDARD_LIBS="base array bytestring containers deepseq directory filepath ghc-prim integer-gmp mtl process stm template-haskell text time transformers unix Win32"

MISSING_COUNT=0
NULL_COUNT=0
STANDARD_COUNT=0

echo "Analyzing each dependency..."
while IFS= read -r dep; do
  [ -z "$dep" ] && continue
  
  # Check if it's a standard library
  IS_STANDARD=false
  for std_lib in $STANDARD_LIBS; do
    if [ "$dep" = "$std_lib" ]; then
      IS_STANDARD=true
      STANDARD_COUNT=$((STANDARD_COUNT + 1))
      echo "| 📦 | \`$dep\` | Standard library |" >> "$OUTPUT_FILE"
      break
    fi
  done
  
  [ "$IS_STANDARD" = true ] && continue
  
  # Check if defined in overlay
  if echo "$DEFINED_PACKAGES" | grep -q "^$dep$"; then
    # Check if it's set to null
    if grep -q "^  $dep = null" "$OVERLAY_FILE"; then
      echo "| ⚠️ | \`$dep\` | Set to null (path doesn't exist) |" >> "$OUTPUT_FILE"
      NULL_COUNT=$((NULL_COUNT + 1))
    else
      echo "| ✅ | \`$dep\` | Defined in overlay |" >> "$OUTPUT_FILE"
    fi
  else
    echo "| ❌ | \`$dep\` | **NOT DEFINED** - will cause build failure if needed |" >> "$OUTPUT_FILE"
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done <<< "$ALL_DEPS"

# Update summary counts
sed -i.bak "s/CABAL_COUNT/$CABAL_COUNT/" "$OUTPUT_FILE"
sed -i.bak "s/DEP_COUNT/$DEP_COUNT/" "$OUTPUT_FILE"
sed -i.bak "s/DEFINED_COUNT/$DEFINED_COUNT/" "$OUTPUT_FILE"
sed -i.bak "s/MISSING_COUNT/$MISSING_COUNT/" "$OUTPUT_FILE"
sed -i.bak "s/NULL_COUNT/$NULL_COUNT/" "$OUTPUT_FILE"
rm "${OUTPUT_FILE}.bak"

echo ""
echo "✅ Analysis complete!"
echo ""
echo "Results written to: $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "  - $CABAL_COUNT .cabal files analyzed"
echo "  - $DEP_COUNT unique dependencies found"
echo "  - $STANDARD_COUNT standard libraries (no action needed)"
echo "  - $MISSING_COUNT dependencies NOT defined in overlay"
echo "  - $NULL_COUNT dependencies set to null"
echo ""

if [ "$MISSING_COUNT" -gt 0 ]; then
  echo "⚠️  WARNING: $MISSING_COUNT dependencies are not defined!"
  echo "   These will cause build failures if actually used by the build."
  echo ""
  echo "   Next steps:"
  echo "   1. Review $OUTPUT_FILE for packages marked ❌"
  echo "   2. For each missing package:"
  echo "      - Check Hackage: https://hackage.haskell.org/package/{name}"
  echo "      - Check all-cabal-hashes"
  echo "      - Check if it should come from a thunk"
  echo "      - Add to overlay or set to null if path doesn't exist"
fi
