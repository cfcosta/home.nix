#!/usr/bin/env sh

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

nix build "${ROOT}#testVM.config.system.build.vm"
