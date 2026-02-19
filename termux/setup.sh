#!/bin/bash
# Termux Setup Script for UDP Relay
# Run this script first to install all dependencies

set -e

# Set non-interactive mode for dpkg/apt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo "========================================"
echo "  UDP Relay - Termux Setup Script"
echo "========================================"
echo ""

# Check if running in Termux
TERMUX_MODE=false
if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]; then
    TERMUX_MODE=true
    echo "✓ Running in Termux environment"
    echo ""
elif [ "$(uname -o 2>/dev/null)" = "Android" ]; then
    TERMUX_MODE=true
    echo "✓ Running in Android environment"
    echo ""
else
    echo "⚠ Warning: This script is designed for Termux on Android."
    echo "  Continuing anyway on this system..."
    echo ""
fi

# Architecture check
ARCH=$(uname -m)
echo "System Architecture: $ARCH"

# Check for required commands
check_command() {
    if command -v "$1" &> /dev/null; then
        echo "  ✓ $1: available"
        return 0
    else
        echo "  ✗ $1: NOT FOUND"
        return 1
    fi
}

echo ""
echo "[1/5] Checking existing environment..."
echo ""

# In Termux, use 'pkg', otherwise try 'apt' or 'yum'
if [ "$TERMUX_MODE" = true ]; then
    PKG_MANAGER="pkg"
else
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    else
        echo "Error: No supported package manager found"
        exit 1
    fi
fi

echo "Package Manager: $PKG_MANAGER"
echo ""

# Update package lists
echo "[2/5] Updating package lists..."
if [ "$PKG_MANAGER" = "pkg" ]; then
    # Fix any broken packages first
    dpkg --configure -a 2>/dev/null || true
    pkg update -y || { echo "Failed to update packages"; exit 1; }
else
    sudo $PKG_MANAGER update -y || { echo "Failed to update packages"; exit 1; }
fi

# Upgrade existing packages
echo ""
echo "[3/5] Upgrading packages..."
if [ "$PKG_MANAGER" = "pkg" ]; then
    # Use -o to set dpkg options to handle config conflicts automatically
    pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || echo "Warning: Some packages could not be upgraded"
else
    sudo $PKG_MANAGER upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || echo "Warning: Some packages could not be upgraded"
fi

# Install Python
echo ""
echo "[4/5] Installing Python..."
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    if [ "$PKG_MANAGER" = "pkg" ]; then
        pkg install python -y
    else
        sudo $PKG_MANAGER install python3 -y
    fi
fi

# Create python symlink if only python3 exists
if command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo "Creating 'python' symlink to 'python3'..."
    if [ "$TERMUX_MODE" = true ]; then
        ln -sf "$(which python3)" "$PREFIX/bin/python" 2>/dev/null || true
    fi
fi

# Install additional useful packages
echo ""
echo "[5/5] Installing additional packages..."
if [ "$PKG_MANAGER" = "pkg" ]; then
    pkg install nano curl wget procps -y 2>/dev/null || echo "Some optional packages could not be installed"
else
    sudo $PKG_MANAGER install nano curl wget procps -y 2>/dev/null || echo "Some optional packages could not be installed"
fi

# Verify Python installation
echo ""
echo "========================================"
echo "  Verifying Installation"
echo "========================================"
echo ""

# Check Python
PYTHON_PATH=""
if command -v python &> /dev/null; then
    PYTHON_PATH=$(which python)
    PYTHON_VERSION=$(python --version 2>&1)
    echo "✓ Python: $PYTHON_VERSION"
    echo "  Path: $PYTHON_PATH"
elif command -v python3 &> /dev/null; then
    PYTHON_PATH=$(which python3)
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "✓ Python3: $PYTHON_VERSION"
    echo "  Path: $PYTHON_PATH"
else
    echo "✗ Python: NOT INSTALLED"
    exit 1
fi

# Verify standard library modules
echo ""
echo "Checking Python standard library modules..."

check_python_module() {
    if python -c "import $1" 2>/dev/null || python3 -c "import $1" 2>/dev/null; then
        echo "  ✓ $1: available"
        return 0
    else
        echo "  ✗ $1: NOT FOUND"
        return 1
    fi
}

MODULES_OK=true
check_python_module "socket" || MODULES_OK=false
check_python_module "threading" || MODULES_OK=false
check_python_module "argparse" || MODULES_OK=false

if [ "$MODULES_OK" = true ]; then
    echo ""
    echo "✓ All required Python modules are available"
else
    echo ""
    echo "✗ Some Python modules are missing. This may cause issues."
fi

# Network check
echo ""
echo "Checking network capabilities..."

# Check if we can bind to port 7300
if python -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.bind(('0.0.0.0', 7300))
    print('  ✓ Can bind to port 7300')
    s.close()
except Exception as e:
    print(f'  ✗ Cannot bind to port 7300: {e}')
" 2>/dev/null || python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.bind(('0.0.0.0', 7300))
    print('  ✓ Can bind to port 7300')
    s.close()
except Exception as e:
    print(f'  ✗ Cannot bind to port 7300: {e}')
"; then
    :
fi

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "Summary:"
echo "  - Python: Installed"
echo "  - Required modules: socket, threading, argparse"
echo "  - Default port: 7300"
echo ""
echo "Next steps:"
echo "  1. Start server: ./termux/start-relay.sh"
echo "  2. Or manually: python main.py --port 7300"
echo ""
