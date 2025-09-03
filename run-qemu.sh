#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
BUILD_DIR="${ROOT}/build"
ISO_FILE="$(find "${ROOT}/result/iso" -type f | head -n 1)"
DISK_DIR="${BUILD_DIR}/qemu-disks"
DISK="${DISK_DIR}/disk.qcow2"

mkdir -p "${DISK_DIR}"

if [[ ! -f ${ISO_FILE} ]]; then
  echo "Error: ISO file not found at ${ISO_FILE}"
  exit 1
fi

rm -rf "${DISK}" || true
echo "Creating disk image: $(basename "${DISK}")"
qemu-img create -f qcow2 "${DISK}" 10G

exec qemu-system-x86_64 \
  -machine q35,accel=kvm:tcg \
  -cpu host \
  -m 8G \
  -smp 2 \
  -cdrom "${ISO_FILE}" \
  -boot d \
  -device nvme,drive=nvme1,serial=nvme1 \
  -drive file="${DISK}",format=qcow2,if=none,id=nvme1 \
  -device virtio-scsi-pci,id=scsi \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -display gtk
