#!/usr/bin/env bash
set -Eeuo pipefail

SDK_COMMIT="824b817f889c2cbff1d48fcdb18ab494a68f69d1"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${1:-$PROJECT_DIR/luckfox-sdk}"
BOARD_CONFIG="project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Zero-IPC.mk"

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

bash "$PROJECT_DIR/scripts/apply-to-sdk.sh" "$SDK_DIR"
ln -sfn "$BOARD_CONFIG" "$SDK_DIR/.BoardConfig.mk"

cd "$SDK_DIR"
./build.sh sysdrv
./build.sh firmware

test -s output/image/update.img
sha256sum output/image/update.img
echo "Ready: $SDK_DIR/output/image/update.img"

