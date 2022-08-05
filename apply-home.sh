#!/usr/bin/env bash

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

home-manager switch --flake "${ROOT}#$(whoami)@$(hostname)"
