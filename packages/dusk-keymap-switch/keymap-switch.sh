#!/usr/bin/env bash

set -e

declare -a HYPR_LAYOUTS=()
declare -a HYPR_VARIANTS=()
declare -a FCITX_INPUT_METHODS=()
LAST_SWITCHED_KEYMAP=""

get_active_keyboards() {
  local keyboards
  keyboards=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .name')

  if [ -z "$keyboards" ]; then
    _error "No active keyboards found that support keymap switching"
    exit 1
  fi

  echo "$keyboards"
}

load_keymap_config() {
  local layouts variants
  layouts=$(hyprctl getoption input:kb_layout | grep "str:" | cut -d' ' -f2-)
  variants=$(hyprctl getoption input:kb_variant | grep "str:" | cut -d' ' -f2-)

  IFS=',' read -ra HYPR_LAYOUTS <<<"$layouts"
  IFS=',' read -ra HYPR_VARIANTS <<<"$variants"

  for i in "${!HYPR_LAYOUTS[@]}"; do
    local variant="${HYPR_VARIANTS[i]:-}"
    HYPR_VARIANTS[i]="$variant"

    local im="keyboard-${HYPR_LAYOUTS[i]}"
    if [ -n "$variant" ]; then
      im="${im}-${variant}"
    fi

    FCITX_INPUT_METHODS[i]="$im"
  done
}

get_available_keymaps() {
  local keymaps=()
  for i in "${!HYPR_LAYOUTS[@]}"; do
    local layout="${HYPR_LAYOUTS[i]}"
    local variant="${HYPR_VARIANTS[i]:-}"

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

get_friendly_keymap_from_parts() {
  local layout="$1"
  local variant="${2:-}"

  if [ "$layout" = "us" ] && [ -z "$variant" ]; then
    echo "US Layout"
    return
  fi

  if [ "$layout" = "us" ] && [ "$variant" = "intl" ]; then
    echo "US International"
    return
  fi

  if [ -n "$variant" ]; then
    echo "$layout ($variant)"
    return
  fi

  echo "$layout"
}

is_fcitx_running() {
  if ! command -v fcitx5-remote >/dev/null 2>&1; then
    return 1
  fi

  fcitx5-remote --check >/dev/null 2>&1
}

switch_keyboard_keymap() {
  local keyboard="$1"
  local switch_target="${2:-next}"

  _info "Switching keymap for keyboard: $(_blue "$keyboard")"

  if ! hyprctl switchxkblayout "$keyboard" "$switch_target"; then
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

    LAST_SWITCHED_KEYMAP="$new_keymap"
  else
    _warn "Could not determine new keymap for keyboard: $keyboard"
  fi
}

switch_keymaps_with_fcitx() {
  local keyboards="$1"

  if [ "${#HYPR_LAYOUTS[@]}" -lt 2 ]; then
    _warn "Fcitx5 is running but only one keymap is configured; falling back to Hyprland switching"
    return 1
  fi

  local current_im
  current_im=$(fcitx5-remote -n 2>/dev/null || true)

  local target_index=1
  for i in "${!FCITX_INPUT_METHODS[@]}"; do
    if [ "${FCITX_INPUT_METHODS[i]}" = "$current_im" ]; then
      target_index=$(((i + 1) % ${#FCITX_INPUT_METHODS[@]}))
      break
    fi
  done

  local target_im="${FCITX_INPUT_METHODS[target_index]}"
  local target_layout="${HYPR_LAYOUTS[target_index]}"
  local target_variant="${HYPR_VARIANTS[target_index]}"

  _info "Fcitx5 detected, syncing Hyprland to layout index $target_index ($target_im)"

  if ! fcitx5-remote -s "$target_im"; then
    _warn "Failed to switch fcitx5 to input method $target_im"
    return 1
  fi

  local success_count=0
  local total_count=0
  LAST_SWITCHED_KEYMAP=""

  while IFS= read -r keyboard; do
    if [ -n "$keyboard" ]; then
      total_count=$((total_count + 1))
      if switch_keyboard_keymap "$keyboard" "$target_index"; then
        success_count=$((success_count + 1))
      fi
    fi
  done <<<"$keyboards"

  local friendly_name
  if [ -n "$LAST_SWITCHED_KEYMAP" ]; then
    friendly_name=$(get_friendly_keymap_name "$LAST_SWITCHED_KEYMAP")
  else
    friendly_name=$(get_friendly_keymap_from_parts "$target_layout" "$target_variant")
  fi

  if [ "$success_count" -eq "$total_count" ]; then
    _info "Successfully switched keymaps for $(_green "$success_count") keyboard(s) via fcitx5"
  else
    _warn "Switched keymaps for $(_green "$success_count") out of $(_red "$total_count") keyboards via fcitx5"
  fi

  return 0
}

main() {
  _info "Starting keymap switch operation"

  load_keymap_config

  local keyboards
  keyboards=$(get_active_keyboards)

  if [ -z "$keyboards" ]; then
    _error "No keyboards available for keymap switching"
    exit 1
  fi

  local available_keymaps
  available_keymaps=$(get_available_keymaps)
  _debug "Available keymaps: $(echo "$available_keymaps" | tr '\n' ', ' | sed 's/,$//')"

  if is_fcitx_running; then
    if switch_keymaps_with_fcitx "$keyboards"; then
      return
    fi

    _warn "Fcitx5 switching failed, falling back to Hyprland only"
  fi

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
