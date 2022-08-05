#!/usr/bin/env bash
#
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

nixos-rebuild switch --flake "${ROOT}#$(hostname)"
