#!/usr/bin/env bash
set -Eeuo pipefail
set -x

echo "==> Initial PATH:" "$PATH"
command -v nix-prefetch-url >/dev/null 2>&1 || echo 'nix-prefetch-url not on PATH yet'
ls -al /root/.nix-profile/bin 2>/dev/null || echo '/root/.nix-profile/bin not present'

# Ensure /usr/bin/env exists for scripts that rely on it (common in nix-prefetch-scripts)
if ! [ -x /usr/bin/env ]; then
  ENV_BIN="$(command -v env || true)"
  if [ -n "$ENV_BIN" ]; then
    mkdir -p /usr/bin
    ln -sf "$ENV_BIN" /usr/bin/env || true
  fi
fi

# Choose a writable nix config directory (use user config to avoid read-only /etc on nix image)
: "${HOME:=/root}"
NIX_USER_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nix"
NIX_CONF_DIR="$NIX_USER_CONF_DIR"
mkdir -p "$NIX_CONF_DIR"

# Defaults if not provided
: "${NIX_MAX_JOBS:=auto}"
: "${NIX_BUILD_CORES:=0}"
: "${NIX_SANDBOX:=false}"

# Write nix.conf in one heredoc to avoid quoting pitfalls (overwrite each run)
cat > "$NIX_CONF_DIR/nix.conf" <<EOF
experimental-features = nix-command flakes
max-jobs = ${NIX_MAX_JOBS}
cores = ${NIX_BUILD_CORES}
keep-outputs = true
keep-derivations = true
sandbox = ${NIX_SANDBOX}
build-users-group =
sandbox-fallback = false
filter-syscalls = false
narinfo-cache-positive-ttl = 3600
substituters = ${SUBSTITUTERS:-https://cache.nixos.org/}
trusted-public-keys = ${TRUSTED_PUBLIC_KEYS:-cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=}
trusted-users = root
EOF

if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "access-tokens = github.com=${GITHUB_TOKEN}" >> "$NIX_CONF_DIR/nix.conf"
  printf 'machine api.github.com\n  login x-access-token\n  password %s\nmachine codeload.github.com\n  login x-access-token\n  password %s\n' "${GITHUB_TOKEN}" "${GITHUB_TOKEN}" > "$NIX_CONF_DIR/netrc"
  echo "netrc-file = $NIX_CONF_DIR/netrc" >> "$NIX_CONF_DIR/nix.conf"
fi

# Make sure critical settings are honored even if other defaults interfere
export NIX_CONFIG=$(printf "sandbox = %s\nfilter-syscalls = false" "${NIX_SANDBOX}")
echo "==> Effective overrides via NIX_CONFIG:"
printf "%s\n" "$NIX_CONFIG"
echo "==> nix show-config (sandbox/filter-syscalls lines):"
nix show-config | grep -Ei 'sandbox|filter-syscalls' || true

# Run the inner build (already mounted from the host)
nix-shell \
  --option sandbox ${NIX_SANDBOX} \
  --option sandbox-fallback false \
  --option filter-syscalls false \
  -p nix-prefetch-scripts cabal2nix git cacert \
  --command 'bash /work/.ci/inner-build.sh'
