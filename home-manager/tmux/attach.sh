#!/usr/bin/env bash

SESSION_NAME="${1:-main}"
TMUX="${TMUX:-tmux}"

shift

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
	# shellcheck disable=2068
	${TMUX} new -t "${SESSION_NAME}" $@
else
	# shellcheck disable=2068
	${TMUX} attach -t "${SESSION_NAME}" $@
fi
