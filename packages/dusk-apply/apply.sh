#!/usr/bin/env bash

set -e

ACTION="${1:-switch}"

HOSTNAME="$(hostname -s)"
NIX="nix --extra-experimental-features flakes --extra-experimental-features nix-command"
ROOT="$(git rev-parse --show-toplevel)"

_info "Running action $(_red "\`${ACTION}\`") for $(_blue "$(uname -s)") machine."

if [ -d "${ROOT}" ]; then
  _info "Found project root: $(_blue "${ROOT}")"
fi

if [ ! -f "$ROOT/machines/$HOSTNAME.nix" ]; then
  _error "Could not find a machine definition for $(_blue "${HOSTNAME}")."
  _info "Please create a file for it on the following path: $(_red "$ROOT/machines/$HOSTNAME.nix") (and ensure it has been added to git working copy, with $(_green "git add --intent-to-add") or something similar)."
  exit 1
fi

if [ "$(whoami)" == "root" ]; then
  _fatal "This script must be run as a normal user. Sudo password will be asked from you when required."
fi

# shellcheck disable=SC2086
_run ${NIX} run "${ROOT}#dusk-system-verify"

case "$(uname -s)" in
"Darwin")
  CMD="${NIX} run nix-darwin -- $ACTION --flake ${ROOT}#${HOSTNAME} -L"
  ;;
"Linux")
  CMD="nixos-rebuild $ACTION --flake ${ROOT}#${HOSTNAME} -L"

  case "$ACTION" in
  switch)
    CMD="sudo ${CMD}"
    ;;
  boot)
    CMD="sudo ${CMD}"
    ;;
  esac
  ;;
*)
  _fatal "Invalid system"
  ;;
esac

_info "Running command: $(_blue "${CMD}")"

exec ${CMD}
