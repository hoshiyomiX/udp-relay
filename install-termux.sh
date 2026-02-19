#!/bin/bash
# Quick Install Script for UDP Relay on Termux (Android)
# Run this after cloning the repository

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   UDP Relay - Termux Quick Installer   ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Detect environment
TERMUX_MODE=false
if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ] || [ "$(uname -o 2>/dev/null)" = "Android" ]; then
    TERMUX_MODE=true
    echo "✓ Detected Termux/Android environment"
else
    echo "⚠ Not running in Termux/Android"
    echo "  This script is optimized for Termux on Android."
    echo "  It may work on other Linux systems with modifications."
fi

echo ""
echo "System Info:"
echo "  Architecture: $(uname -m)"
echo "  Kernel: $(uname -r)"
echo "  OS: $(uname -s)"
echo ""

# Check if main.py exists
if [ ! -f "$SCRIPT_DIR/main.py" ]; then
    echo "✗ Error: main.py not found!"
    echo "  Please run this script from the udp-relay directory."
    exit 1
fi

# Step 1: Make scripts executable
echo "[1/4] Setting up scripts..."
if [ -d "$SCRIPT_DIR/termux" ]; then
    # Try to make executable (may fail on some file systems)
    chmod +x "$SCRIPT_DIR/termux"/*.sh 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/main.py" 2>/dev/null || true
    echo "  ✓ Scripts configured"
else
    echo "  ✗ termux directory not found"
    exit 1
fi

# Step 2: Run setup
echo ""
echo "[2/4] Installing dependencies..."
"$SCRIPT_DIR/termux/setup.sh"

# Step 3: Verify Python
echo ""
echo "[3/4] Verifying Python installation..."

detect_python() {
    if command -v python &> /dev/null; then
        echo "python"
    elif command -v python3 &> /dev/null; then
        echo "python3"
    else
        echo ""
    fi
}

PYTHON_CMD=$(detect_python)

if [ -z "$PYTHON_CMD" ]; then
    echo "  ✗ Python not found!"
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo "  ✓ $PYTHON_VERSION"

# Step 4: Quick test
echo ""
echo "[4/4] Running quick sanity check..."

# Test Python can import required modules
if $PYTHON_CMD -c "import socket; import threading; import argparse" 2>/dev/null; then
    echo "  ✓ All required modules available"
else
    echo "  ✗ Some required modules are missing"
    exit 1
fi

# Test main.py syntax
if $PYTHON_CMD -m py_compile "$SCRIPT_DIR/main.py" 2>/dev/null; then
    echo "  ✓ main.py syntax OK"
else
    echo "  ✗ main.py has syntax errors"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║         Installation Complete!         ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Quick Start:"
echo ""
echo "  Start server:  ./termux/start-relay.sh [port]"
echo "  Stop server:   ./termux/stop-relay.sh"
echo "  View logs:     cat relay.log"
echo "  Test client:   python client_example.py"
echo ""
echo "Default port: 7300"
echo "Note: Ports below 1024 require root"
echo ""
echo "Examples:"
echo "  ./termux/start-relay.sh          # Use default port 7300"
echo "  ./termux/start-relay.sh 8080     # Use custom port 8080"
echo ""

# Show network info
if command -v ifconfig &> /dev/null; then
    IP_ADDR=$(ifconfig wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | head -1)
    if [ -n "$IP_ADDR" ]; then
        echo "Your device IP: $IP_ADDR"
        echo "Other devices can connect to: $IP_ADDR:7300"
        echo ""
    fi
elif command -v ip &> /dev/null; then
    IP_ADDR=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    if [ -n "$IP_ADDR" ]; then
        echo "Your device IP: $IP_ADDR"
        echo "Other devices can connect to: $IP_ADDR:7300"
        echo ""
    fi
fi

echo "For more info, see: docs/TERMUX.md"
echo ""
