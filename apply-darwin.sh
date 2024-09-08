#!/usr/bin/env bash

set -e

CMD="${1:-switch}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo ":: ERROR: This script is meant to be run on macOS only."
	exit 1
fi

export PATH="/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"

if ! which nix &>/dev/null ; then
	echo ":: Nix not found, installing"
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

	echo ":: Nix installed, loading daemon"
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if [ ! -f "/opt/homebrew/bin/brew" ]; then
	echo ":: Homebrew not found, installing"
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo ":: Done installing homebrew"
fi

nix --extra-experimental-features flakes run nix-darwin -- "$CMD" --flake "${ROOT}#$(hostname -s)"
