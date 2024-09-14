#!/usr/bin/env bash

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NAME="orbstack-nixos"
IMAGE="nixos"
ARCH="arm64"
RECREATE="${RECREATE:-false}"

set -e

if [ "$RECREATE" = "true" ] && (orbctl list | grep "${NAME}" &>/dev/null); then
	echo ":: Found previous instance of VM, killing it."
	orbctl delete -f "${NAME}"
fi

if ! (orbctl list | grep "${NAME}" &>/dev/null); then
	echo ":: VM not found, creating a new instance."
	orbctl create -a "${ARCH}" "${IMAGE}" "${NAME}"
fi

cd "${ROOT}"

orb run sudo hostname "${NAME}"
orb run -w "${ROOT}" nix-shell -p git --run "sudo ./apply.sh"
