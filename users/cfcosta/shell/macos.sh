#!/usr/bin/env bash

# MacOS by default does not load the completions set by Nix, so this
# function fixes that.
loadCompletions() {
	local dir="${1}/share/bash-completion/completions"

	if [ ! -d "${dir}" ]; then
		return
	fi

	for f in "${dir}"/*; do
		source "${f}"
	done
}

loadCompletions "${HOME}/.nix-profile"
loadCompletions "/nix/var/nix/profiles/default"

unset -f loadCompletions
