#!/usr/bin/env bash

set -e

NIX="nix --extra-experimental-features flakes --extra-experimental-features nix-command"
CMD="${1:-switch}"
HOSTNAME="$(hostname -s)"

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=/dev/null
. "${ROOT}/scripts/bash-lib.sh"

if [ ! -f "$ROOT/machines/$HOSTNAME.nix" ]; then
	_fatal 'you must define a machine with this hostname on the "machines" folder'
fi

setup_darwin_xcode_cli_tools() {
	if xcode-select -p &>/dev/null; then
		_info "Found command-line tools: $(_blue "$(xcode-select -p)")"
		return 0
	fi

	_warn "Xcode Command Line Tools are not installed, installing..."

	xcode-select --install

	_info "Please follow the prompts to install Xcode Command Line Tools."
	_info "After installation is complete, please run this script again."

	if ! xcode-select -p &>/dev/null; then
		_fatal "Even after install, could not find installed command line tools, please try again"
	fi
}

setup_darwin_xcode_license() {
	XCODE_VERSION="$(xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/')"
	ACCEPTED_LICENSE_VERSION="$(defaults read /Library/Preferences/com.apple.dt.Xcode 2>/dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2)"

	_info "Found XCode version: $(_blue "${XCODE_VERSION}")"
	_info "Accepted XCode License Version: $(_blue "${ACCEPTED_LICENSE_VERSION}")"

	if [ "$XCODE_VERSION" != "$ACCEPTED_LICENSE_VERSION" ]; then
		_warn "You need to accept the current version XCode License, please input your password for sudo."
		_info "Running command: sudo xcodebuild -license accept"

		sudo xcodebuild -license accept && return 0

		_fatal "Could not accept XCode License"
	fi

	return 0
}

setup_darwin() {
	setup_darwin_xcode_cli_tools
	setup_darwin_xcode_license

	NIX_ROOT="/run/current-system/sw"

	export PATH="${NIX_ROOT}/bin:$PATH"

	if ! which nix &>/dev/null; then
		_warn "Nix not found, installing."

		curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

		_info "Done, Nix installed successfully."
	fi

	if which nix &>/dev/null; then
		_info "Found Nix: $(_blue "$(which nix)")"
	else
		_fatal "Could not find Nix even after install!"
	fi

	# Make sure we are connected to the Nix Daemon
	# shellcheck source=/dev/null
	if [ -e "${NIX_ROOT}/etc/profile.d/nix-daemon.sh" ]; then
		_info "Found Nix Daemon script: $(_blue "${NIX_ROOT}/etc/profile.d/nix-daemon.sh")"

		. "${NIX_ROOT}/etc/profile.d/nix-daemon.sh"
	fi

	BREW_PATH=/opt/homebrew/bin/brew

	if [ ! -e "${BREW_PATH}" ]; then
		_warn "Homebrew not found, installing..."
		NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	_info "Found Homebrew: $(_blue "${BREW_PATH}")"
}

_info "Found $(uname -s) machine, setting up environment."

case "$(uname -s)" in
"Darwin")
	if [ "$(whoami)" == "root" ]; then
		_fatal "This script must be run as a normal user. Sudo password will be asked from you when required."
	fi

	setup_darwin

	CMD="${NIX} run nix-darwin -- $CMD --flake ${ROOT}#${HOSTNAME} -L"

	_info "Running command: $(_blue "${CMD}")"

	exec ${CMD}
	;;
"Linux")
	if [ "$(whoami)" != "root" ] && [ "${CMD}" == "switch" ]; then
		_fatal "This script needs to be run as root."
	fi

	CMD="nixos-rebuild $CMD --flake ${ROOT}#${HOSTNAME} -L"
	;;
*)
	_fatal "Invalid system"
	;;
esac

_info "Running command: $(_blue "${CMD}")"

${CMD}

_info "Done!"
