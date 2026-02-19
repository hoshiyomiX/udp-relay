#!/bin/bash
# One-line curl uninstaller for UDP Relay on Termux (Android)
# Usage: curl -fsSL https://raw.githubusercontent.com/hoshiyomiX/udp-relay/main/uninstall.sh | bash

set -e

echo ""
echo "╔════════════════════════════════════════╗"
echo "║     UDP Relay - Uninstaller            ║"
echo "╚════════════════════════════════════════╝"
echo ""

RELAY_DIR="$HOME/udp-relay"

# Stop the server if running
if [ -f "$RELAY_DIR/.relay.pid" ]; then
    echo "[1/3] Stopping relay server..."
    cd "$RELAY_DIR"
    ./termux/stop-relay.sh 2>/dev/null || true
    echo "      ✓ Server stopped"
else
    echo "[1/3] No running server found"
fi

# Remove boot script if exists
echo "[2/3] Removing boot script..."
if [ -f "$HOME/.termux/boot/relay.sh" ]; then
    rm -f "$HOME/.termux/boot/relay.sh"
    echo "      ✓ Boot script removed"
else
    echo "      ✓ No boot script found"
fi

# Remove the directory
echo "[3/3] Removing UDP Relay..."
if [ -d "$RELAY_DIR" ]; then
    rm -rf "$RELAY_DIR"
    echo "      ✓ Directory removed"
else
    echo "      ✓ Directory not found"
fi

# Release wake lock if termux-api is available
if command -v termux-wake-unlock &> /dev/null; then
    termux-wake-unlock 2>/dev/null || true
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║       Uninstallation Complete!         ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "UDP Relay has been removed from your device."
echo "Python remains installed (may be used by other apps)."
echo ""
