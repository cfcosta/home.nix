#!/usr/bin/env bash

set -e

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=/dev/null
. "${ROOT}/scripts/bash-lib.sh"

OUTPUT_DIR="$(mktemp -d)"

cleanup() {
	rm -rf "${OUTPUT_DIR}"
}

trap cleanup EXIT

HOST_IDENTITY_FILE="/etc/ssh/ssh_host_ed25519_key.pub"
USER_IDENTITY_FILE="${HOME}/.ssh/id_ed25519.pub"

AGE="age -R ${HOST_IDENTITY_FILE} -R ${USER_IDENTITY_FILE}"
MKCERT_CMD="mkcert -cert-file localhost.crt -key-file localhost.key"

cd "${OUTPUT_DIR}"

for file in "${ROOT}"/machines/*.nix; do
	MACHINE_NAME=$(basename "$file" .nix)
	MKCERT_CMD="${MKCERT_CMD} *.$MACHINE_NAME.local $MACHINE_NAME.local"
done

_info "Running command: $(_blue "${MKCERT_CMD}")"
CAROOT="/etc/mkcert" ${MKCERT_CMD}

_info "Encrypting generated keys"

${AGE} localhost.crt >"${ROOT}"/secrets/localhost.crt.age
${AGE} localhost.key >"${ROOT}"/secrets/localhost.key.age

_info "Re-encrypting secrets with all present keys"

cd "${ROOT}/secrets"

agenix -r

rm -rf "${OUTPUT_DIR}"

_info "Done!"
