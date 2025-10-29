#!/usr/bin/env bash
# Scan all thunks for packages with cabal-version >= 3.4
# These need pre-generation with modern cabal2nix

set -euo pipefail

echo "=========================================="
echo "Scanning for cabal-version >= 3.4 issues"
echo "=========================================="
echo ""

ISSUES=()
CHECKED=0

# Function to check cabal-version from GitHub
check_package() {
    local thunk_path="$1"
    local package_name="$2"
    local subpath="$3"  # e.g., "io-classes" or "libs/cardano-ledger-core"
    
    if [[ ! -f "$thunk_path/github.json" ]]; then
        echo "⚠️  No github.json in $thunk_path"
        return
    fi
    
    local owner=$(grep '"owner"' "$thunk_path/github.json" | cut -d'"' -f4)
    local repo=$(grep '"repo"' "$thunk_path/github.json" | cut -d'"' -f4)
    local rev=$(grep '"rev"' "$thunk_path/github.json" | cut -d'"' -f4)
    
    local cabal_url="https://raw.githubusercontent.com/${owner}/${repo}/${rev}/${subpath}/${package_name}.cabal"
    
    echo "Checking: $package_name"
    echo "  Path: $thunk_path"
    echo "  Subpath: $subpath"
    echo "  URL: $cabal_url"
    
    # Fetch the cabal file and extract cabal-version
    local cabal_content=$(curl -s "$cabal_url")
    
    if [[ -z "$cabal_content" ]] || [[ "$cabal_content" == *"404"* ]]; then
        echo "  ⚠️  .cabal file not found"
        echo ""
        return
    fi
    
    local cabal_version=$(echo "$cabal_content" | grep -i "^cabal-version:" | head -1 | awk '{print $2}' | tr -d '\r' | tr -d ' ')
    
    if [[ -z "$cabal_version" ]]; then
        echo "  ⚠️  cabal-version not found in file"
        echo ""
        return
    fi
    
    echo "  cabal-version: $cabal_version"
    
    # Parse version (handle >= prefix)
    cabal_version=$(echo "$cabal_version" | sed 's/>=//g' | sed 's/^[[:space:]]*//')
    
    local major=$(echo "$cabal_version" | cut -d. -f1)
    local minor=$(echo "$cabal_version" | cut -d. -f2)
    
    if [[ "$major" -gt 3 ]] || [[ "$major" -eq 3 && "$minor" -ge 4 ]]; then
        echo "  ❌ NEEDS PRE-GENERATION"
        ISSUES+=("$package_name:$thunk_path:$subpath:$cabal_url")
    else
        echo "  ✅ OK"
    fi
    
    echo ""
    CHECKED=$((CHECKED + 1))
}

# Check packages from cardano-project/cardano-overlays/cardano-packages/dep/
echo "=== Checking deps (cardano-project/cardano-overlays/cardano-packages/dep/) ==="
echo ""

# io-sim thunk
check_package "cardano-project/cardano-overlays/cardano-packages/dep/io-sim" "io-classes" "io-classes"
check_package "cardano-project/cardano-overlays/cardano-packages/dep/io-sim" "io-sim" "io-sim"
check_package "cardano-project/cardano-overlays/cardano-packages/dep/io-sim" "strict-stm" "strict-stm"

# typed-protocols thunk
if [[ -d "cardano-project/cardano-overlays/cardano-packages/dep/typed-protocols" ]]; then
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/typed-protocols" "typed-protocols" "typed-protocols"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/typed-protocols" "typed-protocols-cborg" "typed-protocols-cborg"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/typed-protocols" "typed-protocols-examples" "typed-protocols-examples"
fi

# ouroboros-network thunk
if [[ -d "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-network" ]]; then
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-network" "ouroboros-network" "ouroboros-network"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-network" "ouroboros-network-api" "ouroboros-network-api"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-network" "ouroboros-network-framework" "ouroboros-network-framework"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-network" "ouroboros-network-protocols" "ouroboros-network-protocols"
fi

# ouroboros-consensus thunk
if [[ -d "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-consensus" ]]; then
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-consensus" "ouroboros-consensus" "ouroboros-consensus"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-consensus" "ouroboros-consensus-diffusion" "ouroboros-consensus-diffusion"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-consensus" "ouroboros-consensus-protocol" "ouroboros-consensus-protocol"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-consensus" "sop-extras" "sop-extras"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/ouroboros-consensus" "strict-sop-core" "strict-sop-core"
fi

# cardano-ledger thunk
if [[ -d "cardano-project/cardano-overlays/cardano-packages/dep/cardano-ledger" ]]; then
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/cardano-ledger" "cardano-ledger-core" "libs/cardano-ledger-core"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/cardano-ledger" "cardano-ledger-binary" "libs/cardano-ledger-binary"
    check_package "cardano-project/cardano-overlays/cardano-packages/dep/cardano-ledger" "cardano-ledger-api" "libs/cardano-ledger-api"
fi

echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Checked: $CHECKED packages"
echo ""

if [[ ${#ISSUES[@]} -eq 0 ]]; then
    echo "✅ No cabal-version issues found!"
else
    echo "❌ Found ${#ISSUES[@]} package(s) needing pre-generation:"
    echo ""
    for issue in "${ISSUES[@]}"; do
        IFS=':' read -r pkg_name thunk_path subpath cabal_url <<< "$issue"
        echo "  • $pkg_name"
        echo "    Generate with:"
        
        # Extract owner, repo, rev from github.json
        owner=$(grep '"owner"' "$thunk_path/github.json" | cut -d'"' -f4)
        repo=$(grep '"repo"' "$thunk_path/github.json" | cut -d'"' -f4)
        rev=$(grep '"rev"' "$thunk_path/github.json" | cut -d'"' -f4)
        
        echo "    cabal2nix https://github.com/${owner}/${repo}/archive/${rev}.tar.gz \\"
        echo "      --subpath $subpath \\"
        echo "      > cardano-project/cardano-overlays/generated-nix-expressions/${pkg_name}.nix"
        echo ""
    done
    
    echo "After generating, modify each .nix file to:"
    echo "  1. Add ', src' to the function parameters"
    echo "  2. Replace 'src = fetchzip { ... };' with 'inherit src;'"
    echo "  3. Update overlay to use callPackage with the generated file"
fi
