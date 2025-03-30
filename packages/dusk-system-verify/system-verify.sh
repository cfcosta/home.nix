#!/usr/bin/env bash

set -e

ROOT="$(git rev-parse --show-toplevel)"

setup_linux() {
  _run_quietly which nix || _fatal "Error: 'nix' command not found in PATH"
  _run_quietly pgrep -x nix-daemon || _fatal "Error: nix-daemon is not running"
  _run_quietly nix-store --version || _fatal "Error: Cannot access nix-store"

  return 0
}

setup_darwin_xcode_cli_tools() {
  if xcode-select -p &>/dev/null; then
    _info "Found command-line tools: $(_blue "$(xcode-select -p)")"
    return 0
  fi

  _warn "Xcode Command Line Tools are not installed, installing..."

  _run_quietly xcode-select --install

  _info "Please follow the prompts to install Xcode Command Line Tools. After installation is complete, please run this script again."

  exit 1
}

setup_darwin_xcode_license() {
  if ! which xcodebuild &>/dev/null; then
    _warn "$(_blue xcodebuild) could not be found, things might behave weirdly."

    return 0
  fi

  XCODE_VERSION="$(xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/')"
  ACCEPTED_LICENSE_VERSION="$(defaults read /Library/Preferences/com.apple.dt.Xcode 2>/dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2)"

  _info "Found XCode version: $(_blue "${XCODE_VERSION}")"
  _info "Accepted XCode License Version: $(_blue "${ACCEPTED_LICENSE_VERSION}")"

  if [ "$XCODE_VERSION" != "$ACCEPTED_LICENSE_VERSION" ]; then
    _warn "You need to accept the current version XCode License, please input your password for sudo."
    _run_quietly sudo xcodebuild -license accept || _fatal "Could not accept XCode License"
  fi

  return 0
}

setup_darwin() {
  setup_darwin_xcode_cli_tools
  setup_darwin_xcode_license

  NIX_ROOT="/run/current-system/sw"

  export PATH="${NIX_ROOT}/bin:$PATH"

  if ! which nix &>/dev/null; then
    _warn "Nix not found, installing."

    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

    _info "Done, Nix installed successfully."
  fi

  _info "Loading Nix daemon..."

  # Make sure we are connected to the Nix Daemon
  if [ -e "${NIX_ROOT}/etc/profile.d/nix-daemon.sh" ]; then
    _info "Found Nix Daemon script: $(_blue "${NIX_ROOT}/etc/profile.d/nix-daemon.sh")"

    #shellcheck source=/dev/null
    . "${NIX_ROOT}/etc/profile.d/nix-daemon.sh"
  fi

  _run_quietly which nix || _fatal "Error: 'nix' command not found in PATH"

  BREW_PATH=/opt/homebrew/bin/brew

  if [ ! -e "${BREW_PATH}" ]; then
    _warn "Homebrew not found, installing..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  _info "Found Homebrew: $(_blue "${BREW_PATH}")"
}

get_pubkey() {
  if [ ! -f "${HOME}/.ssh/id_ed25519.pub" ]; then
    _error "Could not find a valid SSH key in $(_blue "${HOME}/.ssh")."
    _info "You can generate one by running this command: $(_blue "ssh-keygen -t ed25519")"

    return 127
  fi

  cut -f 2 -d" " <"${HOME}/.ssh/id_ed25519.pub"
}

check_ssh_key_requirements() {
  local github_user username

  github_user="$(nix eval --json --file "${ROOT}/user.nix" | jq -r '.config.dusk.accounts.github')"
  username="$(nix eval --json --file "${ROOT}/user.nix" | jq -r '.config.dusk.username')"
  HOME=$(eval echo "~${username}")

  _info "Checking if the user SSH key is properly registered on Github..."

  [[ -n ${github_user} ]] || _fatal "Could not find your github user on the $(_blue "${ROOT}/user.nix") file."
  _debug "Found username: $(_green "${github_user}")"
  _debug "Found Github User: $(_green "${github_user}")"

  if ! timeout 2s curl "https://github.com/${github_user}.keys" 2>&1 | grep -q "$(get_pubkey)"; then
    _warn "The SSH key you are using was not added to the configured GitHub account. This might mean you either need to add this key to your user, change the $(_blue "${ROOT}/user.nix") file, or verify your network connection."
  fi
}

check_secrets() {
  _info "Verifying if your user is allowed to decrypt secrets"

  cd "${ROOT}/secrets" || _fatal "Failed to cd to secrets folder in $(_blue "${ROOT}/secrets")."

  if ! agenix -d cloudflare-api-token.age &>/dev/null; then
    _warn "The secrets are inaccessible! Be careful. You should re-generate and re-encrypt them with your key."
  fi

  cd "${ROOT}" || _fatal "Failed to cd back to repository root at $(_blue "${ROOT}")"

  return 0
}

check_ssh_key_requirements
check_secrets

_debug "Found $(_red "$(uname -s)") machine."
_debug "Hostname: $(_blue "$(hostname)")"

case "$(uname -s)" in
"Darwin")
  setup_darwin
  ;;
"Linux")
  setup_linux
  ;;
*)
  _fatal "Invalid system"
  ;;
esac

_info "Everything seems correct!"
exit 0
