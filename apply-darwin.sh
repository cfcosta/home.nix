#!/usr/bin/env bash

set -e

CMD="${1:-switch}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if $(which nix &>/dev/null); then
  NIX_CMD="nix"
else
  NIX_CMD="/run/current-system/sw/bin/nix"
fi
NIX="${NIX_CMD} --extra-experimental-features nix-command --extra-experimental-features flakes"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This is meant only for macOS hosts."
	exit 1
fi

if [ ! -f "/nix/var/nix/profiles/default/bin/nix" ]; then
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

if [ ! -f "/opt/homebrew/bin/brew" ]; then
	echo "Homebrew not found, installing it."
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Homebrew found, continuing it."
fi

${NIX} run nix-darwin -- "$CMD" --flake "${ROOT}#$(hostname -s)"
