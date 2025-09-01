#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
ISO_FILE="$(find "$PROJECT_ROOT/result/iso" -type f | head -n 1)"
DISK_DIR="$BUILD_DIR/qemu-disks"

mkdir -p "$DISK_DIR"

if [[ ! -f $ISO_FILE ]]; then
  echo "Error: ISO file not found at $ISO_FILE"
  exit 1
fi

DISK="$DISK_DIR/disk.qcow2"

for disk in "$DISK"; do
  if [[ ! -f $disk ]]; then
    echo "Creating disk image: $(basename "$disk")"
    qemu-img create -f qcow2 "$disk" 10G
  fi
done

exec qemu-system-x86_64 \
  -machine q35,accel=kvm:tcg \
  -cpu host \
  -m 4G \
  -smp 2 \
  -cdrom "$ISO_FILE" \
  -boot d \
  -device nvme,drive=nvme1,serial=nvme1 \
  -drive file="$DISK",format=qcow2,if=none,id=nvme1 \
  -device virtio-scsi-pci,id=scsi \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -display gtk
