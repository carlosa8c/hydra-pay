#!/usr/bin/env bash
set -Eeuo pipefail

# Load a docker image tarball (from nix-build) and optionally push to a registry.
# Defaults:
#   --tar result.tar
#   --name carlosa8c/hydra-pay
#   --version $(git rev-parse --short HEAD) or 'latest' if not in a git repo
#   --push-latest (on by default)
# Enable push by passing --push or setting DOCKER_PUSH=1
# If pushing, you can login with env vars DOCKER_USERNAME / DOCKER_PASSWORD

TAR=result.tar
NAME=${NAME:-carlosa8c/hydra-pay}
PUSH_LATEST=1
DOCKER_PUSH=${DOCKER_PUSH:-0}

if [ -z "${VERSION:-}" ]; then
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    VERSION=$(git rev-parse --short HEAD)
  else
    VERSION=latest
  fi
fi

usage() {
  cat <<USAGE
Usage: $0 [--tar path] [--name repo/name] [--version tag] [--push] [--no-latest]

Environment overrides:
  NAME, VERSION, DOCKER_PUSH, DOCKER_USERNAME, DOCKER_PASSWORD
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --tar) TAR="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --push) DOCKER_PUSH=1; shift ;;
    --no-latest) PUSH_LATEST=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [ ! -f "$TAR" ]; then
  echo "Image tar not found: $TAR" >&2
  exit 1
fi

echo "Loading image from $TAR ..."
LOAD_OUT=$(docker load < "$TAR")
# docker load usually prints either:
#   Loaded image: repo/name:tag
# or
#   Loaded image ID: sha256:...
echo "$LOAD_OUT"
loaded_ref=$(echo "$LOAD_OUT" | awk -F': ' '/Loaded image:/ {print $2}' | tail -n1 || true)

if [ -z "$loaded_ref" ]; then
  echo "Could not detect image name from load output; will tag using ${NAME}:latest"
  loaded_ref="${NAME}:latest"
fi

echo "Tagging ${loaded_ref} -> ${NAME}:${VERSION}"
docker tag "$loaded_ref" "${NAME}:${VERSION}"

if [ "$PUSH_LATEST" = "1" ]; then
  echo "Tagging ${loaded_ref} -> ${NAME}:latest"
  docker tag "$loaded_ref" "${NAME}:latest"
fi

if [ "$DOCKER_PUSH" = "1" ]; then
  if [ -n "${DOCKER_USERNAME:-}" ] && [ -n "${DOCKER_PASSWORD:-}" ]; then
    echo "Logging in to Docker registry as $DOCKER_USERNAME..."
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  fi
  echo "Pushing ${NAME}:${VERSION}"
  docker push "${NAME}:${VERSION}"
  if [ "$PUSH_LATEST" = "1" ]; then
    echo "Pushing ${NAME}:latest"
    docker push "${NAME}:latest"
  fi
else
  echo "Skipping push (enable with --push or DOCKER_PUSH=1)."
fi
