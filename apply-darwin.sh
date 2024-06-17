#!/usr/bin/env bash

set -e

CMD="${1:-switch}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo ":: ERROR: This script is intended to be run on macOS only."
	exit 1
fi

if $(which nix &>/dev/null); then
  NIX_CMD="$(which nix)"
else
  NIX_CMD="/run/current-system/sw/bin/nix"
fi
NIX="${NIX_CMD} --extra-experimental-features nix-command --extra-experimental-features flakes"

if [ ! -f "/nix/var/nix/profiles/default/bin/nix" ]; then
	echo ":: Nix not found, installing"
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

if [ ! -f "/opt/homebrew/bin/brew" ]; then
	echo ":: Homebrew not found, installing"
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

${NIX} run nix-darwin -- "$CMD" --flake "${ROOT}#$(hostname -s)"
