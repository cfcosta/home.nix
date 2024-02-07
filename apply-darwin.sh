#!/usr/bin/env bash

set -e

CMD="${1:-switch}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NIX="nix --extra-experimental-features nix-command --extra-experimental-features flakes"

${NIX} run nix-darwin -- "$CMD" --flake "${ROOT}#$(hostname -s)"
