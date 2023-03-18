#!/usr/bin/env bash

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

home-manager switch --flake "${ROOT}#${SYSTEM}.$(whoami)@$(hostname)"
