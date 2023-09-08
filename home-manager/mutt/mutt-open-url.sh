#!/usr/bin/env bash

OS="$(uname -s)"

# Read the URL from either STDIN or the first argument
if [ -p /dev/stdin ]; then
	# Read from the pipe
	URL="$(cat)"
elif [ $# -gt 0 ]; then
	# Use the first argument as the URL
	URL="$1"
else
	echo "Error: No URL provided."
	exit 1
fi

case "$OS" in
Linux)
	if [ -n "$BROWSER" ]; then
		"$BROWSER" "$URL" &
	else
		xdg-open "$URL" &
	fi
	;;
Darwin)
	if [ -n "$BROWSER" ]; then
		APP_NAME="$(ls -1 /Applications | grep -i "^$BROWSER.app" | head -n 1)"

		if [ -n "$APP_NAME" ]; then
			open -n -a "$APP_NAME" "$URL"
		else
			echo "Error: Could not find $BROWSER.app in /Applications directory."
			exit 1
		fi
	else
		# On macOS, use the default browser to open the URL
		open "$URL"
	fi
	;;
*)
	echo "Error: Unsupported operating system."
	exit 1
	;;
esac
