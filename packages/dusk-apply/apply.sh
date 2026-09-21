#!/usr/bin/env bash

set -e

ACTION="${1:-switch}"

HOSTNAME="$(hostname -s)"
NIX=(nix --extra-experimental-features flakes --extra-experimental-features nix-command)
ROOT="$(git rev-parse --show-toplevel)"

# FlakeHub Cache holds what the GitHub Actions builds already produced for these
# machines. Determinate Nix configures it globally on NixOS, but nix-darwin owns
# /etc/nix/nix.conf on drone, so pass it on the command line and keep both
# machines pulling from the same place. Keys come from Determinate's own
# nix.conf; they are append-only, so a rotation degrades to a local rebuild
# rather than a failure.
FLAKEHUB_SUBSTITUTERS="https://cache.flakehub.com https://edge.cache.flakehub.com"
FLAKEHUB_KEYS="cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio= cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU= cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU= cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8= cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ= cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o= cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="

CACHE_OPTS=(
  --option extra-substituters "${FLAKEHUB_SUBSTITUTERS}"
  --option extra-trusted-public-keys "${FLAKEHUB_KEYS}"
)

# Reads from FlakeHub Cache are authenticated, and an unauthenticated Nix just
# falls back to building everything locally without saying why.
_verify_flakehub_login() {
  if ! command -v determinate-nixd &>/dev/null; then
    _warn "$(_blue determinate-nixd) not found, builds will not use FlakeHub Cache."
    return 0
  fi

  local status
  status="$(determinate-nixd status 2>/dev/null || true)"

  if ! grep -qx "Logged in: true" <<<"${status}"; then
    _warn "Not logged in to FlakeHub, builds will fall back to $(_blue "cache.nixos.org")."
    _info "Run $(_green "determinate-nixd login") to use FlakeHub Cache."
    return 0
  fi

  _info "Using FlakeHub Cache as $(_blue "$(sed -n 's/^FlakeHub user name: //p' <<<"${status}")")."
}

_info "Running action $(_red "\`${ACTION}\`") for $(_blue "$(uname -s)") machine."

if [ -d "${ROOT}" ]; then
  _info "Found project root: $(_blue "${ROOT}")"
fi

if [ ! -d "$ROOT/machines/$HOSTNAME" ]; then
  _error "Could not find a machine definition for $(_blue "${HOSTNAME}")."
  _info "Please create a directory for it on the following path: $(_red "$ROOT/machines/$HOSTNAME") with a $(_red "default.nix") inside (and ensure it has been added to git working copy, with $(_green "git add --intent-to-add") or something similar)."
  exit 1
fi

if [ "$(whoami)" == "root" ]; then
  _fatal "This script must be run as a normal user. Sudo password will be asked from you when required."
fi

_verify_flakehub_login

_run "${NIX[@]}" "${CACHE_OPTS[@]}" run "${ROOT}#dusk-system-verify"

case "$(uname -s)" in
"Darwin")
  CMD=(sudo "${NIX[@]}" "${CACHE_OPTS[@]}" run nix-darwin -- "$ACTION" --flake "${ROOT}#${HOSTNAME}")
  ;;
"Linux")
  CMD=(nixos-rebuild "$ACTION" "${CACHE_OPTS[@]}" --flake "${ROOT}#${HOSTNAME}")

  case "$ACTION" in
  switch)
    CMD=(sudo "${CMD[@]}")
    ;;
  boot)
    CMD=(sudo "${CMD[@]}")
    ;;
  esac
  ;;
*)
  _fatal "Invalid system"
  ;;
esac

_info "Running command: $(_blue "${CMD[*]}")"

exec "${CMD[@]}"
