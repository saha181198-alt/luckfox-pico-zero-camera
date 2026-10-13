#!/usr/bin/env bash
set -Eeuo pipefail

SDK_COMMIT="824b817f889c2cbff1d48fcdb18ab494a68f69d1"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${1:-$PROJECT_DIR/luckfox-sdk}"
BOARD_CONFIG="project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Zero-IPC.mk"
export USB_DEBUG="${USB_DEBUG:-0}"

case "$USB_DEBUG" in
    0|1) ;;
    *) echo "ERROR: USB_DEBUG must be 0 or 1." >&2; exit 2 ;;
esac
if [[ -n "${SYSDRV_KERNEL_OBJS_OUTPUT_DIR:-}" ]]; then
    echo "ERROR: unset SYSDRV_KERNEL_OBJS_OUTPUT_DIR to use the verified SDK output path." >&2
    exit 2
fi

if [[ ! -d "$SDK_DIR/.git" ]]; then
    if [[ -e "$SDK_DIR" ]]; then
        echo "ERROR: $SDK_DIR exists but is not a Git clone." >&2
        exit 1
    fi
    git init "$SDK_DIR"
    git -C "$SDK_DIR" remote add origin https://github.com/LuckfoxTECH/luckfox-pico.git
    git -C "$SDK_DIR" fetch --depth=1 --filter=blob:none origin "$SDK_COMMIT"
    git -C "$SDK_DIR" checkout --detach FETCH_HEAD
fi

actual_commit="$(git -C "$SDK_DIR" rev-parse HEAD)"
if [[ "$actual_commit" != "$SDK_COMMIT" ]]; then
    echo "ERROR: $SDK_DIR is at $actual_commit, expected $SDK_COMMIT." >&2
    exit 1
fi
SDK_DIR="$(cd "$SDK_DIR" && pwd)"

bash "$PROJECT_DIR/scripts/apply-to-sdk.sh" "$SDK_DIR"
ln -sfn "$BOARD_CONFIG" "$SDK_DIR/.BoardConfig.mk"

cd "$SDK_DIR"
build_stamp="$(mktemp "$SDK_DIR/.kernel-build-start.XXXXXX")"
trap 'rm -f "$build_stamp"' EXIT
./build.sh sysdrv
kernel_config="$SDK_DIR/sysdrv/source/objs_kernel/.config"
if [[ ! -s "$kernel_config" || ! "$kernel_config" -nt "$build_stamp" ]]; then
    echo "ERROR: the build did not produce a fresh kernel .config." >&2
    exit 1
fi
if [[ "$USB_DEBUG" = 1 ]]; then
    bash "$PROJECT_DIR/scripts/verify-usb-debug-config.sh" "$kernel_config"
fi
./build.sh firmware

test -s output/image/update.img
cp "$kernel_config" output/image/kernel.config
cp project/cfg/BoardConfig_IPC/overlay/overlay-camera-st7735/etc/pico-camera-build-info \
    output/image/pico-camera-build-info.txt
sha256sum output/image/update.img
echo "Ready: $SDK_DIR/output/image/update.img"

