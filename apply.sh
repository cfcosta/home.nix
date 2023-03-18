#!/usr/bin/env bash

set -e

[ "$(whoami)" == "root" ] || (
    echo "This script needs to be run as root."
    exit 1
)

get_arch() {
  case "$(uname -m)" in
    "arm64") echo "aarch64";;
    *) echo "x86_64";;
  esac
}

get_system() {
  case "$(uname)" in
    "Linux") echo "linux";;
    *) echo "darwin";;
  esac
}

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
SYSTEM="$(get_arch)-$(get_system)"

nix build \
  --extra-experimental-features nix-command --extra-experimental-features flakes \
 "${ROOT}#profiles.${SYSTEM}.$(hostname -s).system.config.system.build.toplevel"

exec "${ROOT}/result/bin/switch-to-configuration" switch
