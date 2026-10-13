#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 || ! -s "$1" ]]; then
    echo "Usage: $0 /path/to/generated/kernel/.config" >&2
    echo "Pass the final Kconfig output, not an input fragment." >&2
    exit 2
fi

config_file="$1"
failed=0

require_setting() {
    local setting="$1"
    if ! grep -Fqx -- "$setting" "$config_file"; then
        echo "ERROR: final kernel config is missing $setting" >&2
        failed=1
    fi
}

# Include selected, hidden symbols: accepting just the fragment would miss
# Kconfig dependency failures and could produce firmware without trace events.
for symbol in \
    USB USB_XHCI_HCD USB_XHCI_PLATFORM USB_DWC3 USB_DWC3_OF_SIMPLE \
    PHY_ROCKCHIP_INNO_USB2 USB_VIDEO_CLASS \
    PRINTK PRINTK_TIME PROC_FS IKCONFIG IKCONFIG_PROC \
    DEBUG_FS DEBUG_FS_ALLOW_ALL DYNAMIC_DEBUG DYNAMIC_DEBUG_CORE \
    FTRACE TRACING EVENT_TRACING TRACEPOINTS RING_BUFFER NOP_TRACER; do
    require_setting "CONFIG_${symbol}=y"
done

if ! grep -Eq '^CONFIG_USB_DWC3_(HOST|DUAL_ROLE)=y$' "$config_file"; then
    echo "ERROR: DWC3 must include Host support (HOST=y or DUAL_ROLE=y)." >&2
    failed=1
fi

# The capture utility uses debugfs/tracing; keep the SDK tracefs automount.
if grep -Fqx 'CONFIG_TRACEFS_DISABLE_AUTOMOUNT=y' "$config_file"; then
    echo "ERROR: tracefs automount under debugfs is disabled." >&2
    failed=1
fi

if [[ $failed -ne 0 ]]; then
    exit 1
fi

echo "Final kernel config includes USB Host, UVC, dynamic debug and trace events."
