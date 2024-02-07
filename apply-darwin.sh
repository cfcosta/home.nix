#!/usr/bin/env bash

set -e

CMD="${1:-switch}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NIX="nix --extra-experimental-features nix-command --extra-experimental-features flakes"

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This is meant only for macOS hosts."
	exit 1
fi

if [ ! -f "/opt/homebrew/bin/brew" ]; then
	echo "Homebrew not found, installing it."
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Homebrew found, continuing it."
fi

${NIX} run nix-darwin -- "$CMD" --flake "${ROOT}#$(hostname -s)"
