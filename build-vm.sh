#!/usr/bin/env bash

set -e

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

rm -f nixos.qcow2

nixos-rebuild build-vm --flake "${ROOT}#x86_64-linux"

${ROOT}/result/bin/run-nixos-vm
