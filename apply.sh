#!/usr/bin/env bash

set -e

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

[ "$(whoami)" == "root" ] || (
    echo "This script needs to be run as root."
    exit 1
)

nixos-rebuild switch --flake "${ROOT}#$(hostname)"
