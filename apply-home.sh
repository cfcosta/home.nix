#!/usr/bin/env bash

set -e

get_arch() {
	case "$(uname -m)" in
	"arm64") echo "aarch64" ;;
	*) echo "x86_64" ;;
	esac
}

get_system() {
	case "$(uname)" in
	"Linux") echo "linux" ;;
	*) echo "darwin" ;;
	esac
}

build() {
	ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
	SYSTEM="$(get_arch)-$(get_system)"

	nix build \
		--extra-experimental-features nix-command --extra-experimental-features flakes \
		"${ROOT}#profiles.${SYSTEM}.$(hostname -s).home.activation-script" \
		--show-trace
}

ACTION="${1:-switch}"

case "${ACTION}" in
"build") build ;;
"switch") build && exec "${ROOT}/result/activate" ;;
*)
	echo "Unknown action: ${ACTION}"
	exit 1
	;;
esac
