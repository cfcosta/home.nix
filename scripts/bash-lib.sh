#!/usr/bin/env bash

export COLORS_NONE='\033[0m' # No Color
export COLORS_BLACK='\033[0;30m'
export COLORS_RED='\033[0;31m'
export COLORS_GREEN='\033[0;32m'
export COLORS_YELLOW='\033[0;33m'
export COLORS_BLUE='\033[0;34m'
export COLORS_PURPLE='\033[0;35m'
export COLORS_CYAN='\033[0;36m'
export COLORS_WHITE='\033[0;37m'

_black() {
	echo -e "${COLORS_BLACK}$1${COLORS_NONE}"
}

_red() {
	echo -e "${COLORS_RED}$1${COLORS_NONE}"
}

_green() {
	echo -e "${COLORS_GREEN}$1${COLORS_NONE}"
}

_yellow() {
	echo -e "${COLORS_YELLOW}$1${COLORS_NONE}"
}

_blue() {
	echo -e "${COLORS_BLUE}$1${COLORS_NONE}"
}

_purple() {
	echo -e "${COLORS_PURPLE}$1${COLORS_NONE}"
}

_cyan() {
	echo -e "${COLORS_CYAN}$1${COLORS_NONE}"
}

_white() {
	echo -e "${COLORS_WHITE}$1${COLORS_NONE}"
}

_gray() {
	echo -e "\033[0;90m$1${COLORS_NONE}"
}

_timestamp() {
	_gray "$(date "+%Y-%m-%d %H:%M:%S")"
}

_info() {
	echo -e "$(_gray "::") $(_timestamp) $(_green "[INFO]") $1"
}

_debug() {
	echo -e "$(_gray "::") $(_timestamp) $(_purple "[DEBUG]") $1"
}

_warn() {
	echo -e "$(_gray "::") $(_timestamp) $(_yellow "[WARN]") $1" >&2
}

_error() {
	echo -e "$(_gray "::") $(_timestamp) $(_red "[ERROR]") $1" >&2
}

_fatal() {
	echo -e "$(_gray "::") $(_timestamp) $(_red "[FATAL]") $1" >&2
	exit 1
}
