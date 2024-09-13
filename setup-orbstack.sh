#!/usr/bin/env bash

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NAME="orbstack-nixos"
ARCH="arm64"

set -e

if ! (orbctl list | grep "${NAME}" &>/dev/null); then
	orbctl create -a "${ARCH}" nixos ${NAME}
fi

orb run -w "${ROOT}" nix-shell -p git --run "sudo bash apply.sh"
