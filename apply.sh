#!/usr/bin/env bash

set -e

_red() {
	echo -ne "\033[0;31m$1\033[0m"
}

_gray() {
	echo -ne "\033[0;90m$1\033[0m"
}

_timestamp() {
	_gray "$(date "+%Y-%m-%d %H:%M:%S")"
}

echo -e "$(_gray "::") $(_timestamp) $(_red "[ERROR]") \
This script has been deprecated, please run $(_red "dusk-apply") instead."

if which dusk-apply &>/dev/null; then
	# shellcheck disable=SC2068
	exec dusk-apply $@
else
	# shellcheck disable=SC2068
	exec nix run "$(pwd)#dusk-apply" -- $@
fi
