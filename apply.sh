#!/usr/bin/env bash

set -e

[ "$(whoami)" == "root" ] || (
	echo "This script needs to be run as root."
	exit 1
)

CMD="${1:-switch}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

exec nixos-rebuild "${CMD}" --flake "${ROOT}#$(hostname)"
