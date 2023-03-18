#!/usr/bin/env bash

set -e

get_system() {
  if [[ "$(uname)" == "Linux" ]]; then
    echo "${ARCH}-linux"
  else
    echo "${ARCH}-darwin"
  fi
}

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ARCH="$(uname -m)"
SYSTEM="$(get_system)"
NIX_FLAGS="--extra-experimental-features nix-command --extra-experimental-features flakes"

nix build ${NIX_FLAGS} "${ROOT}#homeConfigurations.${SYSTEM}.$(whoami)@$(hostname).activation-script"

exec "${ROOT}/result/activate"
