#!/bin/bash
# One-line curl installer for UDP Relay on Termux (Android)
# Usage: curl -fsSL https://raw.githubusercontent.com/hoshiyomiX/udp-relay/main/install.sh | bash

set -e

echo ""
echo "╔════════════════════════════════════════╗"
echo "║     UDP Relay - Quick Installer        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if running in Termux
if [ -z "$TERMUX_VERSION" ]; then
    echo "⚠ Note: This script is designed for Termux on Android"
fi

# Update and install dependencies
echo "[1/4] Updating packages..."
pkg update -y && pkg upgrade -y

echo "[2/4] Installing Python and git..."
pkg install python git -y

# Clone repository
echo "[3/4] Cloning UDP Relay..."
cd ~
if [ -d "udp-relay" ]; then
    echo "   udp-relay already exists, updating..."
    cd udp-relay && git pull
else
    git clone https://github.com/hoshiyomiX/udp-relay.git
    cd udp-relay
fi

# Make scripts executable
echo "[4/4] Setting up scripts..."
chmod +x termux/*.sh install-termux.sh main.py 2>/dev/null || true

echo ""
echo "╔════════════════════════════════════════╗"
echo "║         Installation Complete!         ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "  cd ~/udp-relay"
echo "  ./termux/start-relay.sh        # Start server"
echo "  ./termux/stop-relay.sh         # Stop server"
echo ""
