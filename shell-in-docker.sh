#!/usr/bin/env bash
set -Eeuo pipefail

echo "Starting interactive Nix shell in Docker..."

: "${HTTPS_PROXY:=http://http-proxy.tumblr.net:8080}"
: "${https_proxy:=${HTTPS_PROXY}}"
: "${HTTP_PROXY:=${HTTPS_PROXY}}"
: "${http_proxy:=${HTTPS_PROXY}}"
export HTTPS_PROXY https_proxy HTTP_PROXY http_proxy

: "${NIX_VOLUME:=hydrapay-nix}"
: "${NIX_CACHE_VOLUME:=hydrapay-nix-cache}"

docker volume inspect "$NIX_VOLUME" >/dev/null 2>&1 || docker volume create "$NIX_VOLUME" >/dev/null

docker volume inspect "$NIX_CACHE_VOLUME" >/dev/null 2>&1 || docker volume create "$NIX_CACHE_VOLUME" >/dev/null

docker run --rm -it \
  -v "$PWD:/work" \
  -v "$NIX_VOLUME:/nix" \
  -v "$NIX_CACHE_VOLUME:/root/.cache/nix" \
  -w /work \
  ${GITHUB_TOKEN:+-e GITHUB_TOKEN="$GITHUB_TOKEN"} \
  -e HTTPS_PROXY="$HTTPS_PROXY" -e https_proxy="$https_proxy" \
  -e HTTP_PROXY="$HTTP_PROXY" -e http_proxy="$http_proxy" \
  nixos/nix \
  bash -lc "set -Eeuo pipefail; \
    mkdir -p /etc/nix; \
    { \
      echo 'experimental-features = nix-command flakes'; \
      echo 'keep-outputs = true'; \
      echo 'keep-derivations = true'; \
      echo 'sandbox = false'; \
      echo "substituters = ${SUBSTITUTERS:-https://cache.nixos.org/}"; \
      echo "trusted-public-keys = ${TRUSTED_PUBLIC_KEYS:-cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=}"; \
      echo 'trusted-users = root'; \
    } >> /etc/nix/nix.conf; \
    if [ -n \"${GITHUB_TOKEN:-}\" ]; then \
      echo \"access-tokens = github.com=${GITHUB_TOKEN}\" >> /etc/nix/nix.conf; \
      printf 'machine api.github.com\n  login x-access-token\n  password %s\nmachine codeload.github.com\n  login x-access-token\n  password %s\n' \"${GITHUB_TOKEN}\" \"${GITHUB_TOKEN}\" > /etc/nix/netrc; \
      echo 'netrc-file = /etc/nix/netrc' >> /etc/nix/nix.conf; \
    fi; \
    nix-shell -p nix-prefetch-scripts cabal2nix git cacert --command bash"
