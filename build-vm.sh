#!/usr/bin/env bash

set -e

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

nixos-rebuild build-vm --flake "${ROOT}#"

${ROOT}/result/bin/run-nixos-vm
