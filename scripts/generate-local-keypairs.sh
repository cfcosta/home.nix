#!/usr/bin/env bash

set -e

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

OUTPUT_DIR="$(mktemp -d)"
export OUTPUT_DIR

export CAROOT="${OUTPUT_DIR}/ca-root"
mkdir -p "${CAROOT}"

cd "${OUTPUT_DIR}"

cleanup() {
	rm -rf "${OUTPUT_DIR}"
}
trap cleanup EXIT

CMD="mkcert -cert-file localhost.crt -key-file localhost.key"

echo ":: Generating encryption identity file"
grep ssh- secrets/secrets.nix | sed "s;\s*\";;g" | tee keys.txt

for file in "${ROOT}"/machines/*.nix; do
	MACHINE_NAME=$(basename "$file" .nix)
	CMD="${CMD} *.$MACHINE_NAME.local $MACHINE_NAME.local"
done

echo ":: Running command: ${CMD}"
${CMD}

age -R keys.txt localhost.crt >"${ROOT}"/secrets/localhost.crt.age
age -R keys.txt localhost.key >"${ROOT}"/secrets/localhost.key.age

bash
