#!/usr/bin/env bash

set -e

OUTPUT_DIR="$(mktemp -d)"

cleanup() {
	rm -rf "${OUTPUT_DIR}"
}

trap cleanup EXIT

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
HOST_IDENTITY_FILE="/etc/ssh/ssh_host_ed25519_key.pub"
USER_IDENTITY_FILE="${HOME}/.ssh/id_ed25519.pub"
USER_IDENTITY_KEY_FILE="${HOME}/.ssh/id_ed25519"

export CAROOT="${OUTPUT_DIR}/ca-root"
mkdir -p "${CAROOT}"

pushd "${OUTPUT_DIR}" || exit 1

echo ":: Restoring CA files"
age -d -i "${USER_IDENTITY_KEY_FILE}" "${ROOT}"/secrets/rootCA.pem.age >"${CAROOT}/rootCA.pem"
age -d -i "${USER_IDENTITY_KEY_FILE}" "${ROOT}"/secrets/rootCA-key.pem.age >"${CAROOT}/rootCA-key.pem"

CMD="mkcert -cert-file localhost.crt -key-file localhost.key"

for file in "${ROOT}"/machines/*.nix; do
	MACHINE_NAME=$(basename "$file" .nix)
	CMD="${CMD} *.$MACHINE_NAME.local $MACHINE_NAME.local"
done

echo ":: Running command: ${CMD}"
${CMD}

echo ":: Encrypting generated keys..."

AGE="age -R ${USER_IDENTITY_FILE} -R ${HOST_IDENTITY_FILE}"
${AGE} localhost.crt >"${ROOT}"/secrets/localhost.crt.age
${AGE} localhost.key >"${ROOT}"/secrets/localhost.key.age

pushd "${ROOT}/secrets" || exit 1

agenix -r

echo ":: Done!"
