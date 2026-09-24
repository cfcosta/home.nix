#!/usr/bin/env bash

set -e

# Hyprland keeps an xkb group per input device, and a keyboard that shows up as
# several devices (or gets replugged, which resets it to group 0) can end up
# with its devices disagreeing. So instead of asking each device for "next",
# derive the target from the main keyboard and set that same index on every
# device at once: each press also re-syncs anything that drifted.
#
# No notification here: the shell already toasts when the main keyboard's
# keymap changes, and with every device in the same group it fires once.

read_main_keyboard() {
  hyprctl devices -j | jq -c '[.keyboards[] | select(.main == true)][0] // empty'
}

main() {
  local keyboard
  keyboard=$(read_main_keyboard)

  if [ -z "$keyboard" ]; then
    _error "No main keyboard found"
    exit 1
  fi

  local layouts current count target
  layouts=$(jq -r '.layout' <<<"$keyboard")
  current=$(jq -r '.active_layout_index' <<<"$keyboard")
  count=$(tr ',' '\n' <<<"$layouts" | wc -l)
  target=$(((current + 1) % count))

  _info "Switching all keyboards to layout index $(_blue "$target")"
  hyprctl switchxkblayout all "$target" >/dev/null

  local name
  name=$(read_main_keyboard | jq -r '.active_keymap')

  _info "Active keymap: $(_green "$name")"
}

main "$@"
