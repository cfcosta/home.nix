#!/usr/bin/env bash

[ -z "$TMUX" ] || (
	echo "Error: you are already inside tmux."
	exit 1
)

SESSION_NAME="${1:-main}"
FLAGS="${2}"

echo "Starting session ${SESSION_NAME} with flags: ${FLAGS}"

#shellcheck disable=SC2086
tmux $FLAGS new -A -t "${SESSION_NAME}"
