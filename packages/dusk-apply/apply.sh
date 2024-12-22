#!/usr/bin/env bash

set -e

CMD="${1:-switch}"

HOSTNAME="$(hostname -s)"
NIX="nix --extra-experimental-features flakes --extra-experimental-features nix-command"
ROOT="$(git rev-parse --show-toplevel)"

if [ ! -f "$ROOT/machines/$HOSTNAME.nix" ]; then
  _fatal 'you must define a machine with this hostname on the "machines" folder'
fi

_info "Applying new configuration to $(uname -s) machine."

case "$(uname -s)" in
"Darwin")
  if [ "$(whoami)" == "root" ]; then
    _fatal "This script must be run as a normal user. Sudo password will be asked from you when required."
  fi

  dusk-system-verify || _fatal "System failed minimum requirements to run"

  CMD="${NIX} run nix-darwin -- $CMD --flake ${ROOT}#${HOSTNAME} -L"

  _info "Running command: $(_blue "${CMD}")"

  exec ${CMD}
  ;;
"Linux")
  if [ "$(whoami)" == "root" ]; then
    _fatal "This script must be run as a normal user. Sudo password will be asked from you when required."
  fi

  dusk-system-verify || _fatal "System failed minimum requirements to run"

  CMD="sudo nixos-rebuild $CMD --flake ${ROOT}#${HOSTNAME} -L"
  ;;
*)
  _fatal "Invalid system"
  ;;
esac

_info "Running command: $(_blue "${CMD}")"

${CMD}

_info "Done!"
