#!/usr/bin/env bash

set -e

get_active_keyboards() {
  local keyboards
  keyboards=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .name')

  if [ -z "$keyboards" ]; then
    _error "No active keyboards found that support keymap switching"
    exit 1
  fi

  echo "$keyboards"
}

get_available_keymaps() {
  local layouts variants
  layouts=$(hyprctl getoption input:kb_layout | grep "str:" | cut -d' ' -f2-)
  variants=$(hyprctl getoption input:kb_variant | grep "str:" | cut -d' ' -f2-)

  IFS=',' read -ra LAYOUT_ARRAY <<<"$layouts"
  IFS=',' read -ra VARIANT_ARRAY <<<"$variants"

  local keymaps=()
  for i in "${!LAYOUT_ARRAY[@]}"; do
    local layout="${LAYOUT_ARRAY[i]}"
    local variant="${VARIANT_ARRAY[i]:-}"

    if [ -z "$variant" ]; then
      keymaps+=("$layout")
    else
      keymaps+=("$layout($variant)")
    fi
  done

  printf '%s\n' "${keymaps[@]}"
}

get_friendly_keymap_name() {
  local keymap="$1"

  case "$keymap" in
  "English (US)")
    echo "US Layout"
    ;;
  "English (US, international with dead keys)")
    echo "US International"
    ;;
  *)
    echo "$keymap"
    ;;
  esac
}

switch_keyboard_keymap() {
  local keyboard="$1"

  _info "Switching keymap for keyboard: $(_blue "$keyboard")"

  if ! hyprctl switchxkblayout "$keyboard" next; then
    _error "Failed to switch keymap for keyboard: $keyboard"
    return 1
  fi

  sleep 0.1

  local new_keymap
  new_keymap=$(hyprctl devices -j | jq -r ".keyboards[] | select(.name == \"$keyboard\") | .active_keymap")

  if [ -n "$new_keymap" ]; then
    local friendly_name
    friendly_name=$(get_friendly_keymap_name "$new_keymap")

    _info "Keyboard $(_blue "$keyboard") switched to: $(_green "$friendly_name")"

    notify-send -t 1000 'Keyboard Layout' "$friendly_name"
  else
    _warn "Could not determine new keymap for keyboard: $keyboard"
  fi
}

main() {
  _info "Starting keymap switch operation"

  local keyboards
  keyboards=$(get_active_keyboards)

  if [ -z "$keyboards" ]; then
    _error "No keyboards available for keymap switching"
    exit 1
  fi

  local available_keymaps
  available_keymaps=$(get_available_keymaps)
  _debug "Available keymaps: $(echo "$available_keymaps" | tr '\n' ', ' | sed 's/,$//')"

  local success_count=0
  local total_count=0

  while IFS= read -r keyboard; do
    if [ -n "$keyboard" ]; then
      total_count=$((total_count + 1))
      if switch_keyboard_keymap "$keyboard"; then
        success_count=$((success_count + 1))
      fi
    fi
  done <<<"$keyboards"

  if [ "$success_count" -eq "$total_count" ]; then
    _info "Successfully switched keymaps for $(_green "$success_count") keyboard(s)"
  else
    _warn "Switched keymaps for $(_green "$success_count") out of $(_red "$total_count") keyboards"
  fi
}

main "$@"
