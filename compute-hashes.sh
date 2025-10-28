#!/usr/bin/env bash

# Compute SHA256 hashes for GitHub packages
# Format: PACKAGE | REPO | COMMIT

declare -A packages
packages=(
  ["beam-automigrate"]="obsidiansystems/beam-automigrate|9294164cedbb9c31e0d9e58bf97becd987aa2baf"
  ["network"]="haskell/network|86f33ca2d31221c18afc787da4d6ea718616d261"
  ["reflex-dom-core"]="reflex-frp/reflex-dom|56dcb9b1fac39f6624fe29b88d9a59af38e04956"
  ["resource-pool"]="scrive/pool|589954fcf7ffc2ff8e819cfdf0252f1173a99095"
  ["uuid"]="haskell-hvr/uuid|45e9e5df24b05dccc2b89729d75e4c96d668fc59"
  ["which"]="obsidiansystems/which|e2a87735fb5af72f9ef28ec9c39bb54f3cd318f7"
  ["http-client"]="snoyberg/http-client|a0b418c12ff3c9878f21bff92bb174c239a9cfe3"
  ["http-conduit"]="snoyberg/http-client|a0b418c12ff3c9878f21bff92bb174c239a9cfe3"
  ["some"]="haskellari/some|7c7fd6a4e7cebc56394c51d02e5d4155edfcc52a"
  ["websockets"]="jaspervdj/websockets|cbba20b9e073e15e767052fc08b9e35cf8afb985"
  ["fsnotify"]="haskell-fswatch/hfsnotify|f780a2c9c8665402408683ac2c541c073fb76060"
  ["beam-postgres"]="haskell-beam/beam|bab3a2f952a880c14e79860b222a7536c83f686c"
  ["gargoyle"]="obsidiansystems/gargoyle|66324bf0cd71567fc7264ed68887d22e9862340a"
  ["gargoyle-postgresql"]="obsidiansystems/gargoyle|24feb5a687703dcd006e39a33259356f7314338a"
  ["gargoyle-postgresql-nix"]="obsidiansystems/gargoyle|7b196a9bd0e77997abcce2e2d90fb1a1fc9c3065"
  ["gargoyle-postgresql-connect"]="obsidiansystems/gargoyle|00ba66f3b0e9876e44cf1b7f02c856e808bd5c13"
  ["monad-logger"]="snoyberg/monad-logger|04a87e9838ee5a4e8555249d665440a408ca4635"
  ["typed-process"]="fpco/typed-process|d5e9fb30b203721c62974bae6bc1d2be474caae8"
  ["dependent-sum"]="obsidiansystems/dependent-sum|43c633312b1d706a81a01c61cc3a33bdbe5530a3"
)

echo "# Package SHA256 Hashes"
echo "# Generated: $(date)"
echo ""

for pkg in "${!packages[@]}"; do
  IFS='|' read -r repo commit <<< "${packages[$pkg]}"
  url="https://github.com/${repo}/archive/${commit}.tar.gz"
  
  echo "Computing hash for $pkg..."
  hash=$(docker run --rm nixos/nix:latest nix-prefetch-url --unpack "$url" 2>/dev/null | tail -1)
  echo "$pkg|$repo|$commit|$hash"
  echo ""
done
