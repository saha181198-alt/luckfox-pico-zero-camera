#!/usr/bin/env bash
set -Eeuo pipefail

PINNED_SDK_COMMIT="824b817f889c2cbff1d48fcdb18ab494a68f69d1"
BOARD_CONFIG_REL="project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Zero-IPC.mk"
DTS_DIR_REL="sysdrv/source/kernel/arch/arm/boot/dts"
KCONFIG_DIR_REL="sysdrv/source/kernel/arch/arm/configs"
OVERLAY_DIR_REL="project/cfg/BoardConfig_IPC/overlay/overlay-camera-st7735"

usage() {
    echo "Usage: $0 /path/to/luckfox-pico" >&2
    echo "Set ALLOW_DIFFERENT_SDK=1 only if you deliberately test another SDK revision." >&2
}

if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

SDK_DIR="$1"
if [[ ! -d "$SDK_DIR/.git" ]]; then
    echo "ERROR: $SDK_DIR is not a Luckfox SDK Git clone." >&2
    exit 1
fi
SDK_DIR="$(cd "$SDK_DIR" && pwd)"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for required in "$BOARD_CONFIG_REL" "$DTS_DIR_REL/rv1106g-luckfox-pico-zero.dts"; do
    if [[ ! -e "$SDK_DIR/$required" ]]; then
        echo "ERROR: SDK file is missing: $required" >&2
        exit 1
    fi
done

actual_commit="$(git -C "$SDK_DIR" rev-parse HEAD)"
if [[ "$actual_commit" != "$PINNED_SDK_COMMIT" && "${ALLOW_DIFFERENT_SDK:-0}" != "1" ]]; then
    echo "ERROR: unsupported SDK revision: $actual_commit" >&2
    echo "Expected: $PINNED_SDK_COMMIT" >&2
    echo "Checkout the pinned revision, or explicitly set ALLOW_DIFFERENT_SDK=1." >&2
    exit 1
fi

install -m 0644 \
    "$PROJECT_DIR/dts/rv1106g-luckfox-pico-zero-camera-st7735.dtsi" \
    "$SDK_DIR/$DTS_DIR_REL/rv1106g-luckfox-pico-zero-camera-st7735.dtsi"
install -m 0644 \
    "$PROJECT_DIR/kernel/rv1106-camera-st7735.config" \
    "$SDK_DIR/$KCONFIG_DIR_REL/rv1106-camera-st7735.config"

PATCH_FILE="$PROJECT_DIR/patches/0001-pico-zero-camera-display.patch"
if git -C "$SDK_DIR" apply --reverse --check "$PATCH_FILE" >/dev/null 2>&1; then
    echo "SDK text patch is already applied."
elif git -C "$SDK_DIR" apply --check "$PATCH_FILE"; then
    git -C "$SDK_DIR" apply "$PATCH_FILE"
else
    echo "ERROR: the SDK patch does not apply cleanly." >&2
    echo "Use the pinned SDK revision and a clean SDK clone." >&2
    exit 1
fi

mkdir -p "$SDK_DIR/$OVERLAY_DIR_REL"
cp -a "$PROJECT_DIR/rootfs-overlay/." "$SDK_DIR/$OVERLAY_DIR_REL/"
chmod 0755 \
    "$SDK_DIR/$OVERLAY_DIR_REL/etc/init.d/S99camera-display" \
    "$SDK_DIR/$OVERLAY_DIR_REL/usr/bin/camera-display" \
    "$SDK_DIR/$OVERLAY_DIR_REL/usr/bin/camera-display-diagnostics" \
    "$SDK_DIR/$OVERLAY_DIR_REL/usr/bin/camera-display-test"

git -C "$SDK_DIR" diff --check

grep -q 'dr_mode = "host"' \
    "$SDK_DIR/$DTS_DIR_REL/rv1106g-luckfox-pico-zero-camera-st7735.dtsi"
grep -q 'compatible = "sitronix,st7735r"' \
    "$SDK_DIR/$DTS_DIR_REL/rv1106g-luckfox-pico-zero-camera-st7735.dtsi"
grep -q 'overlay-camera-st7735' "$SDK_DIR/$BOARD_CONFIG_REL"

echo "Camera/display additions applied to SDK commit $actual_commit."

