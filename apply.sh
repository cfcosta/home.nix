#!/usr/bin/env bash

set -e

CMD="${1:-switch}"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ "$(whoami)" == "root" ] && [ "${CMD}" != "build" ]; then
	echo "This script needs to be run as root."
	exit 1
fi

exec nixos-rebuild "${CMD}" --flake "${ROOT}#$(hostname)"
