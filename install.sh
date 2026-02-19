#!/bin/bash
# One-line curl installer for UDP Relay on Termux (Android)
# Usage: curl -fsSL https://raw.githubusercontent.com/hoshiyomiX/udp-relay/main/install.sh | bash

set -e

# Set non-interactive mode for dpkg/apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo ""
echo "╔════════════════════════════════════════╗"
echo "║     UDP Relay - Quick Installer        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if running in Termux
TERMUX_MODE=false
if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ] || [ "$(uname -o 2>/dev/null)" = "Android" ]; then
    TERMUX_MODE=true
    echo "✓ Detected Termux/Android environment"
else
    echo "⚠ Note: This script is designed for Termux on Android"
fi

INSTALL_DIR="$HOME/udp-relay"

# Step 1: Fix any broken packages and update
echo ""
echo "[1/5] Fixing broken packages and updating..."
if [ "$TERMUX_MODE" = true ]; then
    # Fix any broken dpkg configurations
    dpkg --configure -a 2>/dev/null || true

    # Update with non-interactive options
    pkg update -y || { echo "Failed to update packages"; exit 1; }
else
    sudo apt update -y || { echo "Failed to update packages"; exit 1; }
fi

# Step 2: Upgrade packages with auto-config handling
echo ""
echo "[2/5] Upgrading packages..."
if [ "$TERMUX_MODE" = true ]; then
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || echo "Warning: Some packages could not be upgraded"
else
    sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || echo "Warning: Some packages could not be upgraded"
fi

# Step 3: Install Python and git
echo ""
echo "[3/5] Installing Python and git..."
if [ "$TERMUX_MODE" = true ]; then
    pkg install python git -y || { echo "Failed to install dependencies"; exit 1; }
else
    sudo apt install python3 git -y || { echo "Failed to install dependencies"; exit 1; }
fi

# Step 4: Clone or update repository
echo ""
echo "[4/5] Cloning UDP Relay..."
cd ~
if [ -d "udp-relay" ]; then
    echo "   udp-relay already exists, updating..."
    cd udp-relay && git pull || echo "Warning: Could not update repository"
else
    git clone https://github.com/hoshiyomiX/udp-relay.git || { echo "Failed to clone repository"; exit 1; }
fi

# Step 5: Setup scripts
echo ""
echo "[5/5] Setting up scripts..."
cd "$INSTALL_DIR"
chmod +x termux/*.sh install-termux.sh main.py 2>/dev/null || true

# Verify Python installation
echo ""
echo "Verifying installation..."
if command -v python &> /dev/null; then
    PYTHON_CMD="python"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
else
    echo "✗ Python not found!"
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo "  ✓ $PYTHON_VERSION"

# Test required modules
if $PYTHON_CMD -c "import socket; import threading; import argparse" 2>/dev/null; then
    echo "  ✓ All required Python modules available"
else
    echo "  ✗ Some Python modules are missing"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║         Installation Complete!         ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "Quick Start:"
echo ""
echo "  cd ~/udp-relay"
echo "  ./termux/start-relay.sh        # Start server"
echo "  ./termux/stop-relay.sh         # Stop server"
echo "  cat relay.log                  # View logs"
echo ""

# Show IP address if available
if command -v ifconfig &> /dev/null; then
    IP_ADDR=$(ifconfig wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | head -1)
    if [ -n "$IP_ADDR" ]; then
        echo "Your device IP: $IP_ADDR"
        echo "Other devices can connect to: $IP_ADDR:7300"
        echo ""
    fi
fi

echo "For more info, see: docs/TERMUX.md"
echo ""
