#!/usr/bin/env bash

set -e

if [ "$(uname -s)" != "Darwin" ]; then
	echo ":: Error: This script is meant to be ran only on MacOS."
	exit 1
fi

echo ":: Loading Nix Daemon"
# shellcheck source=/dev/null
. /run/current-system/sw/etc/profile.d/nix-daemon.sh

echo ":: Preparing system for MacOS Sequoia update"
curl --proto '=https' --tlsv1.2 -sSf -L https://github.com/NixOS/nix/raw/master/scripts/sequoia-nixbld-user-migration.sh | bash -

echo ":: Done."
