#!/usr/bin/env bash

set -e

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=/dev/null
. "${ROOT}/scripts/bash-lib.sh"

if [ "$(uname -s)" != "Darwin" ]; then
	_fatal "This script is meant to be ran only on MacOS."
fi

_info "Loading Nix Daemon"
# shellcheck source=/dev/null
. /run/current-system/sw/etc/profile.d/nix-daemon.sh

_info "Preparing system for MacOS Sequoia update"
curl --proto '=https' --tlsv1.2 -sSf -L https://github.com/NixOS/nix/raw/master/scripts/sequoia-nixbld-user-migration.sh | bash -

_info "Done."
