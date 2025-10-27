#!/usr/bin/env bash
set -Eeuo pipefail

echo "Preparing environment..."

# Simple args: --push, --name <repo>, --version <tag>, --cores <n>, --jobs <n>
DOCKER_PUSH=${DOCKER_PUSH:-0}
NAME=${NAME:-carlosa8c/hydra-pay}
if [ -z "${VERSION:-}" ]; then
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    VERSION=$(git rev-parse --short HEAD)
  else
    VERSION=latest
  fi
fi
PUSH_LATEST=${PUSH_LATEST:-1}
NIX_BUILD_CORES=${NIX_BUILD_CORES:-0}
NIX_MAX_JOBS=${NIX_MAX_JOBS:-auto}

while [ $# -gt 0 ]; do
  case "$1" in
    --push) DOCKER_PUSH=1; shift ;;
    --name) NAME="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --cores) NIX_BUILD_CORES="$2"; shift 2 ;;
    --jobs) NIX_MAX_JOBS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1 (ignored)"; shift ;;
  esac
done

ABS_TOKEN_FILE="/Users/carlos/hydra-pay/.github_token"
if [ -f "$ABS_TOKEN_FILE" ]; then
  GITHUB_TOKEN=$(tr -d '\r\n' < "$ABS_TOKEN_FILE")
  export GITHUB_TOKEN
  echo "Using GitHub token from $ABS_TOKEN_FILE"
else
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    for f in ".github_token" "config/github_token" ".env"; do
      if [ -f "$f" ]; then
        GITHUB_TOKEN=$(grep -E '^GITHUB_TOKEN=' "$f" | tail -n1 | cut -d'=' -f2- | tr -d '"' | tr -d '\r\n' || true)
        [ -n "$GITHUB_TOKEN" ] && export GITHUB_TOKEN && echo "Using GitHub token from $f" && break
      fi
    done
  fi
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Warning: GITHUB_TOKEN not set. GitHub tarball fetches may hit rate limits."
fi

: "${HTTPS_PROXY:=http://http-proxy.tumblr.net:8080}"
: "${https_proxy:=${HTTPS_PROXY}}"
: "${HTTP_PROXY:=${HTTPS_PROXY}}"
: "${http_proxy:=${HTTPS_PROXY}}"
export HTTPS_PROXY https_proxy HTTP_PROXY http_proxy
echo "Using proxy: ${HTTPS_PROXY}"

# ----------------------------------------------------------------------
# PATCH 1: Update stdenv.lib → lib and ensure nix-prefetch-url exists
# ----------------------------------------------------------------------
cat > build-docker.nix << 'EOF2'
let
  nixpkgs = import <nixpkgs> {};
  lib = nixpkgs.lib;  # avoid stdenv.lib deprecation warning
  self = import ./. { system = builtins.currentSystem; };
  obelisk = import ./.obelisk/impl {
    system = builtins.currentSystem;
  };
  configs = nixpkgs.stdenv.mkDerivation {
    name = "configs";
    src = ./config;
    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';
  };
in
  nixpkgs.dockerTools.buildImage {
    name = "carlosa8c/hydra-pay";
    tag = "latest";
    keepContentsDirlinks = true;

    copyToRoot = nixpkgs.buildEnv {
      name = "root";
      paths = [
        nixpkgs.git
        self.hydra-pay
        nixpkgs.bashInteractive
        nixpkgs.iana-etc
        nixpkgs.cacert
        nixpkgs.nix-prefetch-scripts
      ];
      pathsToLink = [ "/bin" ];
    };

    runAsRoot = ''
      #!${nixpkgs.runtimeShell}
      ${nixpkgs.dockerTools.shadowSetup}
      mkdir -p hydra-pay/config
      ln -sft /hydra-pay/config ${configs}/*
      groupadd -r hydra-pay
      useradd -r -g hydra-pay hydra-pay
      chown -R hydra-pay:hydra-pay /hydra-pay
    '';

    config = {
      Env = [
        ("PATH=" + builtins.concatStringsSep(":")(
          [ "/hydrapay" "/bin" ]
          ++ map (pkg: "${pkg}/bin") nixpkgs.stdenv.initialPath
        ))
        "LANG=C.UTF-8"
        "NETWORK=preprod"
        "HTTPS_PROXY=http://http-proxy.tumblr.net:8080"
        "https_proxy=http://http-proxy.tumblr.net:8080"
        "HTTP_PROXY=http://http-proxy.tumblr.net:8080"
        "http_proxy=http://http-proxy.tumblr.net:8080"
      ];
      Cmd = [ "sh" "-c" "/bin/hydra-pay instance $NETWORK" ];
      WorkingDir = "/hydra-pay";
      Expose = 8010;
      User = "hydra-pay:hydra-pay";
    };
  }
EOF2

# ----------------------------------------------------------------------
# Persistent volumes for speed
# ----------------------------------------------------------------------
echo "Configuring persistent Nix volumes for caching..."
: "${NIX_VOLUME:=hydrapay-nix}"
: "${NIX_CACHE_VOLUME:=hydrapay-nix-cache}"

docker volume inspect "$NIX_VOLUME" >/dev/null 2>&1 || docker volume create "$NIX_VOLUME" >/dev/null
docker volume inspect "$NIX_CACHE_VOLUME" >/dev/null 2>&1 || docker volume create "$NIX_CACHE_VOLUME" >/dev/null
echo "Using volumes: /nix -> $NIX_VOLUME, /root/.cache/nix -> $NIX_CACHE_VOLUME"

# ----------------------------------------------------------------------
# Run build inside container
# ----------------------------------------------------------------------
echo "Starting NixOS container for build..."

docker run --rm \
  --security-opt seccomp=unconfined \
  -v "$PWD:/work" \
  -v "$NIX_VOLUME:/nix" \
  -v "$NIX_CACHE_VOLUME:/root/.cache/nix" \
  -w /work \
  ${GITHUB_TOKEN:+-e GITHUB_TOKEN="$GITHUB_TOKEN"} \
  -e NIX_BUILD_CORES="$NIX_BUILD_CORES" \
  -e NIX_MAX_JOBS="$NIX_MAX_JOBS" \
  -e HTTPS_PROXY="$HTTPS_PROXY" -e https_proxy="$https_proxy" \
  -e HTTP_PROXY="$HTTP_PROXY" -e http_proxy="$http_proxy" \
  nixos/nix \
  bash -lc "set -Eeuo pipefail; \
    nix-env -iA nixpkgs.nix-prefetch-scripts nixpkgs.cabal2nix nixpkgs.git nixpkgs.cacert >/dev/null; \
    mkdir -p /etc/nix; \
    { \
      echo 'experimental-features = nix-command flakes'; \
      echo \"max-jobs = ${NIX_MAX_JOBS}\"; \
      echo \"cores = ${NIX_BUILD_CORES}\"; \
      echo 'keep-outputs = true'; \
      echo 'keep-derivations = true'; \
      echo 'sandbox = false'; \
      echo 'narinfo-cache-positive-ttl = 3600'; \
      echo \"substituters = ${SUBSTITUTERS:-https://cache.nixos.org/}\"; \
      echo \"trusted-public-keys = ${TRUSTED_PUBLIC_KEYS:-cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=}\"; \
      echo 'trusted-users = root'; \
    } >> /etc/nix/nix.conf; \
    if [ -n \"${GITHUB_TOKEN:-}\" ]; then \
      echo \"access-tokens = github.com=${GITHUB_TOKEN}\" >> /etc/nix/nix.conf; \
      printf 'machine api.github.com\n  login x-access-token\n  password %s\nmachine codeload.github.com\n  login x-access-token\n  password %s\n' \"${GITHUB_TOKEN}\" \"${GITHUB_TOKEN}\" > /etc/nix/netrc; \
      echo 'netrc-file = /etc/nix/netrc' >> /etc/nix/nix.conf; \
    fi; \
    nix-build -j \"${NIX_MAX_JOBS}\" build-docker.nix --out-link result.tar --show-trace"

# ----------------------------------------------------------------------
# Tag and push if built successfully
# ----------------------------------------------------------------------
if [ -f result.tar ]; then
  echo "Loading image from result.tar..."
  LOAD_OUT=$(docker load < result.tar)
  echo "$LOAD_OUT"
  loaded_ref=$(echo "$LOAD_OUT" | awk -F': ' '/Loaded image:/ {print $2}' | tail -n1)
  [ -z "$loaded_ref" ] && loaded_ref="${NAME}:latest"
  echo "Tagging ${loaded_ref} -> ${NAME}:${VERSION}"
  docker tag "$loaded_ref" "${NAME}:${VERSION}"
  if [ "${PUSH_LATEST}" = "1" ]; then
    docker tag "$loaded_ref" "${NAME}:latest"
  fi

  if [ "${DOCKER_PUSH}" = "1" ]; then
    [ -n "${DOCKER_USERNAME:-}" ] && [ -n "${DOCKER_PASSWORD:-}" ] && \
      echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker push "${NAME}:${VERSION}"
    [ "${PUSH_LATEST}" = "1" ] && docker push "${NAME}:latest"
  else
    echo "Skipping push (set DOCKER_PUSH=1 or pass --push to enable)."
  fi
else
  echo "Build did not produce result.tar; skipping load/push." >&2
fi
