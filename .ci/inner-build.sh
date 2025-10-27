#!/usr/bin/env bash
set -Eeuo pipefail
set -x

echo "==> PATH inside nix-shell:" "$PATH"
command -v nix-prefetch-url >/dev/null 2>&1 || { echo 'nix-prefetch-url missing inside nix-shell preflight'; exit 1; }

# Clear the build log file before starting new build
echo "==> Clearing previous build log..." > /work/build-in-docker.log

if [ -n "${TARGET_ATTR:-}" ]; then
  echo "Building attribute ${TARGET_ATTR} from default.nix"
  NIX_DEBUG=1 nix-build -K --keep-failed -j "${NIX_MAX_JOBS:-auto}" default.nix -A "${TARGET_ATTR}" --out-link result --show-trace ${NIX_EXTRA_FLAGS:-} 2>&1 | tee -a /work/build-in-docker.log
else
  NIX_DEBUG=1 nix-build -K --keep-failed -j "${NIX_MAX_JOBS:-auto}" build-docker.nix --out-link result --show-trace ${NIX_EXTRA_FLAGS:-} 2>&1 | tee -a /work/build-in-docker.log
fi
