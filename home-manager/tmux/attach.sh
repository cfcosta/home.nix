#!/usr/bin/env bash

[ -z "$TMUX" ] || (
	echo "Error: you are already inside tmux."
	exit 1
)

SESSION_NAME="${1:-main}"
FLAGS="${2}"

#shellcheck disable=SC2086
tmux $FLAGS new -A -t "${SESSION_NAME}"
