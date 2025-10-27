#!/usr/bin/env bash
set -Eeuo pipefail

echo "Preparing environment..."

# Simple args: --push, --name <repo>, --version <tag>, --cores <n>, --jobs <n>, --attr <attrPath>
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
TARGET_ATTR=${TARGET_ATTR:-}
NIX_EXTRA_FLAGS=${NIX_EXTRA_FLAGS:-}

# Detect host OS to choose sensible default for Nix sandboxing
if [ -z "${NIX_SANDBOX:-}" ]; then
  case "$(uname -s)" in
    Darwin)
      NIX_SANDBOX=false ;;
    *)
      NIX_SANDBOX=true ;;
  esac
fi
echo "Nix sandbox (host $(uname -s)): ${NIX_SANDBOX}"

# On macOS, prefer running the amd64 nix image for consistency
if [ -z "${DOCKER_PLATFORM:-}" ]; then
  case "$(uname -s)" in
    Darwin)
      # Use amd64 to align with most upstream binary tools and avoid cross-arch exec issues
      DOCKER_PLATFORM=linux/amd64 ;;
    *)
      DOCKER_PLATFORM= ;;
  esac
fi

# On macOS, grant privileged mode to avoid kernel seccomp limitations inside nested namespaces
if [ -z "${DOCKER_PRIVILEGED:-}" ]; then
  case "$(uname -s)" in
    Darwin)
      DOCKER_PRIVILEGED=--privileged ;;
    *)
      DOCKER_PRIVILEGED= ;;
  esac
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --push) DOCKER_PUSH=1; shift ;;
    --name) NAME="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --cores) NIX_BUILD_CORES="$2"; shift 2 ;;
    --jobs) NIX_MAX_JOBS="$2"; shift 2 ;;
    --attr) TARGET_ATTR="$2"; shift 2 ;;
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
# Compose default build or allow targeting a specific attribute
# ----------------------------------------------------------------------
if [ -z "$TARGET_ATTR" ]; then
  cat > build-docker.nix << 'EOF2'
let
  system = builtins.currentSystem;
  self = import ./. { inherit system; };
  nixpkgs = self.obelisk.nixpkgs;
  lib = nixpkgs.lib;  # avoid stdenv.lib deprecation warning
  configs = nixpkgs.stdenv.mkDerivation {
    name = "configs";
    src = ./config;
    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';
  };
in
  nixpkgs.buildEnv {
    name = "hydra-pay-env";
    paths = [
      self.hydra-pay
      configs
    ];
  }
EOF2
fi

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
  ${DOCKER_PLATFORM:+--platform ${DOCKER_PLATFORM}} \
  ${DOCKER_PRIVILEGED:-} \
  --security-opt seccomp=unconfined \
  -v "$PWD:/work" \
  -v "$NIX_VOLUME:/nix" \
  -v "$NIX_CACHE_VOLUME:/root/.cache/nix" \
  -w /work \
  ${GITHUB_TOKEN:+-e GITHUB_TOKEN="$GITHUB_TOKEN"} \
  -e NIX_SANDBOX="$NIX_SANDBOX" \
  -e NIX_BUILD_CORES="$NIX_BUILD_CORES" \
  -e NIX_MAX_JOBS="$NIX_MAX_JOBS" \
  -e TARGET_ATTR="$TARGET_ATTR" \
  -e HTTPS_PROXY="$HTTPS_PROXY" -e https_proxy="$https_proxy" \
  -e HTTP_PROXY="$HTTP_PROXY" -e http_proxy="$http_proxy" \
  nixos/nix \
  bash -lc 'bash /work/.ci/container-init.sh'

# ----------------------------------------------------------------------
# Build Docker image using host Docker
# ----------------------------------------------------------------------
if [ -d result ]; then
  echo "Creating Dockerfile..."
  cat > Dockerfile << 'EOF'
FROM nixos/nix:latest

# Copy built hydra-pay and configs
COPY result/ /hydra-pay/

# Set up user and permissions
RUN groupadd -r hydra-pay && \
    useradd -r -g hydra-pay hydra-pay && \
    chown -R hydra-pay:hydra-pay /hydra-pay

# Set environment
ENV PATH=/hydra-pay/bin:$PATH \
    LANG=C.UTF-8 \
    NETWORK=preprod \
    HTTPS_PROXY=http://http-proxy.tumblr.net:8080 \
    https_proxy=http://http-proxy.tumblr.net:8080 \
    HTTP_PROXY=http://http-proxy.tumblr.net:8080 \
    http_proxy=http://http-proxy.tumblr.net:8080

# Expose port and set working directory
EXPOSE 8010
WORKDIR /hydra-pay
USER hydra-pay

# Default command
CMD ["sh", "-c", "/hydra-pay/bin/hydra-pay instance $NETWORK"]
EOF

  echo "Building Docker image ${NAME}:${VERSION}..."
  docker build -t "${NAME}:${VERSION}" .
  if [ "${PUSH_LATEST}" = "1" ]; then
    docker tag "${NAME}:${VERSION}" "${NAME}:latest"
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
  echo "Build did not produce result directory; skipping Docker build." >&2
fi
