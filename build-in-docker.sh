#!/usr/bin/env bash
set -Eeuo pipefail

# Build hydra-pay Docker image inside a NixOS container

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

# Optional parallelism settings (can also be set via env before running):
#   NIX_BUILD_CORES: threads per derivation (0 = all cores)
#   NIX_MAX_JOBS: parallel derivations ("auto" recommended)
NIX_BUILD_CORES=${NIX_BUILD_CORES:-0}
NIX_MAX_JOBS=${NIX_MAX_JOBS:-auto}

while [ $# -gt 0 ]; do
  case "$1" in
    --push)
      DOCKER_PUSH=1; shift ;;
    --name)
      NAME="$2"; shift 2 ;;
    --version)
      VERSION="$2"; shift 2 ;;
    --cores)
      NIX_BUILD_CORES="$2"; shift 2 ;;
    --jobs)
      NIX_MAX_JOBS="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1 (ignored)"; shift ;;
  esac
done

# Always prefer the absolute token path on this machine if present
ABS_TOKEN_FILE="/Users/carlos/hydra-pay/.github_token"
if [ -f "$ABS_TOKEN_FILE" ]; then
  GITHUB_TOKEN=$(tr -d '\r\n' < "$ABS_TOKEN_FILE")
  export GITHUB_TOKEN
  echo "Using GitHub token from $ABS_TOKEN_FILE"
else
  # Source GitHub token if not provided as env var
  if [ -z "${GITHUB_TOKEN:-}" ]; then
    if [ -f ".github_token" ]; then
      GITHUB_TOKEN=$(tr -d '\r\n' < .github_token)
      export GITHUB_TOKEN
      echo "Using GitHub token from .github_token"
    elif [ -f "config/github_token" ]; then
      GITHUB_TOKEN=$(tr -d '\r\n' < config/github_token)
      export GITHUB_TOKEN
      echo "Using GitHub token from config/github_token"
    elif [ -f ".env" ]; then
      # shellcheck disable=SC2046
      GITHUB_TOKEN=$(grep -E '^GITHUB_TOKEN=' .env | tail -n1 | cut -d'=' -f2- | tr -d '"' | tr -d '\r\n' || true)
      if [ -n "${GITHUB_TOKEN:-}" ]; then
        export GITHUB_TOKEN
        echo "Using GitHub token from .env"
      fi
    fi
  fi
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Warning: GITHUB_TOKEN not set. GitHub tarball fetches may hit rate limits."
fi

# Proxy config (optional; defaults for corporate proxy)
# You can override these by exporting HTTPS_PROXY/http(s)_proxy before running the script.
: "${HTTPS_PROXY:=http://http-proxy.tumblr.net:8080}"
: "${https_proxy:=${HTTPS_PROXY}}"
: "${HTTP_PROXY:=${HTTPS_PROXY}}"
: "${http_proxy:=${HTTPS_PROXY}}"
export HTTPS_PROXY https_proxy HTTP_PROXY http_proxy
echo "Using proxy: ${HTTPS_PROXY}"

# Create the Nix file on the host
cat > build-docker.nix << 'EOF2'
let
  nixpkgs = import <nixpkgs> {};
  self = import ./. { system = builtins.currentSystem; };
  obelisk = import ./.obelisk/impl {
    system = builtins.currentSystem;
  };
  configs = nixpkgs.stdenv.mkDerivation
  {
    name = "configs";
    src = ./config;

    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';
  };
in
  nixpkgs.dockerTools.buildImage ({
    name = "carlosa8c/hydra-pay";
    tag = "latest";

    keepContentsDirlinks = true;

    copyToRoot = nixpkgs.buildEnv {
      name = "root";
      paths = [ self.hydra-pay nixpkgs.bashInteractive nixpkgs.iana-etc
                 nixpkgs.cacert];
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
          [
            "/hydrapay"
            "/bin"
          ]
          ++
          map (pkg: "${pkg}/bin") nixpkgs.stdenv.initialPath
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
  })
EOF2

echo "Configuring persistent Nix volumes for caching..."

# Reuse a persistent Nix store/cache across runs to speed up builds drastically
: "${NIX_VOLUME:=hydrapay-nix}"
: "${NIX_CACHE_VOLUME:=hydrapay-nix-cache}"

if ! docker volume inspect "$NIX_VOLUME" >/dev/null 2>&1; then
  docker volume create "$NIX_VOLUME" >/dev/null
fi
if ! docker volume inspect "$NIX_CACHE_VOLUME" >/dev/null 2>&1; then
  docker volume create "$NIX_CACHE_VOLUME" >/dev/null
fi

echo "Using volumes: /nix -> $NIX_VOLUME, /root/.cache/nix -> $NIX_CACHE_VOLUME"

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
    mkdir -p /etc/nix; \
    # Core Nix tuning for speed + reuse
    { \
      echo 'experimental-features = nix-command flakes'; \
      echo \"max-jobs = ${NIX_MAX_JOBS}\"; \
      echo \"cores = ${NIX_BUILD_CORES}\"; \
      echo 'keep-outputs = true'; \
      echo 'keep-derivations = true'; \
      echo 'sandbox = false'; \
      echo 'narinfo-cache-positive-ttl = 3600'; \
      # Allow overriding substituters via env; default to cache.nixos.org only to avoid wrong keys
      echo \"substituters = ${SUBSTITUTERS:-https://cache.nixos.org/}\"; \
      # Allow trusted-public-keys override; default to the cache.nixos.org key
      echo \"trusted-public-keys = ${TRUSTED_PUBLIC_KEYS:-cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=}\"; \
      echo 'trusted-users = root'; \
    } >> /etc/nix/nix.conf; \
    if [ -n \"${GITHUB_TOKEN:-}\" ]; then \
      echo \"access-tokens = github.com=${GITHUB_TOKEN}\" >> /etc/nix/nix.conf; \
      printf 'machine api.github.com\n  login x-access-token\n  password %s\nmachine codeload.github.com\n  login x-access-token\n  password %s\n' \"${GITHUB_TOKEN}\" \"${GITHUB_TOKEN}\" > /etc/nix/netrc; \
      echo 'netrc-file = /etc/nix/netrc' >> /etc/nix/nix.conf; \
    fi; \
    # Show final nix.conf for debugging
    echo '--- /etc/nix/nix.conf ---'; cat /etc/nix/nix.conf; echo '---------------------------'; \
    nix-build -j \"${NIX_MAX_JOBS}\" build-docker.nix --out-link result.tar --show-trace"
echo ""
echo "To load and use the image:"
echo "  docker load < result.tar"
echo "  docker run -p 8010:8010 -e NETWORK=preprod carlosa8c/hydra-pay:latest"
# If build succeeded, load, retag and optionally push
if [ -f result.tar ]; then
  echo "Loading image from result.tar..."
  LOAD_OUT=$(docker load < result.tar)
  echo "$LOAD_OUT"
  loaded_ref=$(echo "$LOAD_OUT" | awk -F': ' '/Loaded image:/ {print $2}' | tail -n1)
  if [ -z "$loaded_ref" ]; then
    loaded_ref="${NAME}:latest"
  fi
  echo "Tagging ${loaded_ref} -> ${NAME}:${VERSION}"
  docker tag "$loaded_ref" "${NAME}:${VERSION}"
  if [ "${PUSH_LATEST}" = "1" ]; then
    echo "Tagging ${loaded_ref} -> ${NAME}:latest"
    docker tag "$loaded_ref" "${NAME}:latest"
  fi

  if [ "${DOCKER_PUSH}" = "1" ]; then
    if [ -n "${DOCKER_USERNAME:-}" ] && [ -n "${DOCKER_PASSWORD:-}" ]; then
      echo "Logging in to Docker registry as $DOCKER_USERNAME..."
      echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    fi
    echo "Pushing ${NAME}:${VERSION}"
    docker push "${NAME}:${VERSION}"
    if [ "${PUSH_LATEST}" = "1" ]; then
      echo "Pushing ${NAME}:latest"
      docker push "${NAME}:latest"
    fi
  else
    echo "Skipping push (set DOCKER_PUSH=1 or pass --push to enable)."
  fi
else
  echo "Build did not produce result.tar; skipping load/push." >&2
fi
