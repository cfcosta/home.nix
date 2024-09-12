#!/usr/bin/env bash

set -e

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
NIX="nix --extra-experimental-features flakes --extra-experimental-features nix-command"

CMD="${1:-switch}"

HOSTNAME="$(hostname -s)"

if [ ! -f "$ROOT/machines/$HOSTNAME.nix" ]; then
	echo 'Error: you must define a machine with this hostname on the "machines" folder'
	exit 1
fi

setup_darwin() {
	NIX_ROOT="/run/current-system/sw"

	export PATH="${NIX_ROOT}/bin:$PATH"

	if ! which nix &>/dev/null; then
		echo ":: Nix not found, installing..."
		curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

		echo ":: Nix installed."
	fi

	# Make sure we are connected to the Nix Daemon
	#
	# shellcheck source=/dev/null
	[ -e "${NIX_ROOT}/etc/profile.d/nix-daemon.sh" ] && . "${NIX_ROOT}/etc/profile.d/nix-daemon.sh"

	if [ ! -f /opt/homebrew/bin/brew ]; then
		echo ":: Homebrew not found, installing..."
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		echo ":: Homebrew installed."
	fi
}

case "$(uname -s)" in
"Darwin")
	if [ "$(whoami)" == "root" ]; then
		echo "This script must be run as a normal user. Sudo password will be asked from you when required."
		exit 1
	fi

	setup_darwin

	exec ${NIX} run nix-darwin --show-trace -- "$CMD" --flake "${ROOT}#${HOSTNAME}"
	;;
"Linux")
	if [ "$(whoami)" != "root" ] && [ "${CMD}" == "switch" ]; then
		echo "This script needs to be run as root."
		exit 1
	fi

	exec nixos-rebuild "${CMD}" --flake "${ROOT}#${HOSTNAME}" --show-trace
	;;
*)
	echo "Error: Invalid system"
	;;
esac
