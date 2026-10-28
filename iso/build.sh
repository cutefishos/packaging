#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

cd "$(dirname "$0")"

ARCH="$(dpkg --print-architecture)"
# A BIOS-bootable hybrid image exists only for amd64; arm64 boots UEFI alone.
if [[ "$ARCH" == amd64 ]]; then
    IMAGE=iso-hybrid
    OPTIONS=()
    ISO="live-image-$ARCH.hybrid.iso"
else
    IMAGE=iso
    OPTIONS=(--bootloaders grub-efi)
    ISO="live-image-$ARCH.iso"
fi

lb clean --purge || true

lb config \
    --mode debian \
    --distribution trixie \
    --architecture "$ARCH" \
    --binary-image "$IMAGE" \
    "${OPTIONS[@]}" \
    --archive-areas "main contrib non-free-firmware" \
    --apt-recommends false \
    --debootstrap-options "--include=ca-certificates" \
    --bootappend-live "boot=live components quiet splash username=cutefish hostname=cutefish"

lb build

if [[ ! -f "$ISO" ]]; then
    echo "Expected ISO was not produced: $ISO" >&2
    exit 1
fi

NAME="${1:-cutefish-debian-13-$ARCH}"
mv "$ISO" "$NAME.iso"
if [[ -f "live-image-$ARCH.packages" ]]; then
    mv "live-image-$ARCH.packages" "$NAME.packages"
fi
