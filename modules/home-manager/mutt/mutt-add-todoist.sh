#!/usr/bin/env bash

set -e

TEMP_FILE="/tmp/mutt-todoist-message" 

[ -f "${HOME}/.config/todoist/config.json" ] || (
	echo "Todoist token is not available, please run \`todoist sync\` to set up."
	exit 1
)

[ -f "${TEMP_FILE}" ] || (
  echo "There's no message set, are you sure you called the command inside mutt?"
  exit 1
)

read -r -p "Task title: " TITLE
DESCRIPTION="$(cat "${TEMP_FILE}")"

[ -z "${TITLE}" ] && {
	echo "Title is required."
	exit 1
}
[ -z "${DESCRIPTION}" ] && {
	echo "Description is required."
	exit 1
}

todoist a -N "Inbox" --description "${DESCRIPTION}" "${TITLE}"
todoist sync

rm "${TEMP_FILE}"
