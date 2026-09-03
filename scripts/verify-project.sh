#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$PROJECT_DIR/scripts/apply-to-sdk.sh"
bash -n "$PROJECT_DIR/scripts/build-local.sh"
sh -n "$PROJECT_DIR/rootfs-overlay/etc/init.d/S99camera-display"
sh -n "$PROJECT_DIR/rootfs-overlay/usr/bin/camera-display"
sh -n "$PROJECT_DIR/rootfs-overlay/usr/bin/camera-display-diagnostics"
sh -n "$PROJECT_DIR/rootfs-overlay/usr/bin/camera-display-test"

# Parse the unified diff without changing files. This catches malformed hunk
# lengths before a long SDK build is started.
git apply --numstat "$PROJECT_DIR/patches/0001-pico-zero-camera-display.patch" >/dev/null

grep -q 'RV1106_Luckfox_Pico_Zero' "$PROJECT_DIR/.github/workflows/build-firmware.yml"
grep -q 'GPIO1_D2' "$PROJECT_DIR/dts/rv1106g-luckfox-pico-zero-camera-st7735.dtsi"
grep -q 'GPIO1_D3' "$PROJECT_DIR/dts/rv1106g-luckfox-pico-zero-camera-st7735.dtsi"
grep -q 'spidev@0' "$PROJECT_DIR/dts/rv1106g-luckfox-pico-zero-camera-st7735.dtsi"
grep -q 'spi0m0_clk &spi0m0_mosi &spi0m0_cs0' \
    "$PROJECT_DIR/dts/rv1106g-luckfox-pico-zero-camera-st7735.dtsi"

for executable in \
    "$PROJECT_DIR/scripts/apply-to-sdk.sh" \
    "$PROJECT_DIR/scripts/build-local.sh" \
    "$PROJECT_DIR/rootfs-overlay/etc/init.d/S99camera-display" \
    "$PROJECT_DIR/rootfs-overlay/usr/bin/camera-display"; do
    test -x "$executable"
done

echo "Project syntax and required-file checks passed."
