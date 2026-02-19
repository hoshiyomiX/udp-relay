#!/bin/bash
# Compatibility Check Script for UDP Relay on Termux/Android
# Run this to verify your environment is compatible

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║        UDP Relay - Compatibility Check Script            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS_COUNT++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAIL_COUNT++))
}

warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN_COUNT++))
}

info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

# 1. Check Environment
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Environment Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if running in Termux
if [ -n "$TERMUX_VERSION" ]; then
    pass "Running in Termux (v$TERMUX_VERSION)"
elif [ -d "/data/data/com.termux" ]; then
    pass "Termux installation detected"
elif [ "$(uname -o 2>/dev/null)" = "Android" ]; then
    warn "Android environment detected (not standard Termux)"
else
    warn "Not running in Termux/Android environment"
fi

# Architecture
ARCH=$(uname -m)
case $ARCH in
    aarch64|arm64-v8a)
        pass "Architecture: $ARCH (64-bit ARM, fully supported)"
        ;;
    armv7l|armv8l|armeabi-v7a)
        pass "Architecture: $ARCH (32-bit ARM, supported)"
        ;;
    x86_64)
        pass "Architecture: $ARCH (64-bit x86, supported)"
        ;;
    i686|x86)
        warn "Architecture: $ARCH (32-bit x86, may have limited package support)"
        ;;
    *)
        warn "Architecture: $ARCH (unknown, may have compatibility issues)"
        ;;
esac

# Kernel version
KERNEL=$(uname -r)
info "Kernel version: $KERNEL"

# 2. Check Package Manager
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Package Manager Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v pkg &> /dev/null; then
    pass "Termux package manager (pkg) available"
elif command -v apt &> /dev/null; then
    pass "APT package manager available"
elif command -v yum &> /dev/null; then
    pass "YUM package manager available"
else
    fail "No supported package manager found"
fi

# 3. Check Python
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Python Installation Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PYTHON_CMD=""

if command -v python &> /dev/null; then
    PYTHON_CMD="python"
    PYTHON_VERSION=$(python --version 2>&1)
    pass "Python found: $PYTHON_VERSION"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    PYTHON_VERSION=$(python3 --version 2>&1)
    pass "Python3 found: $PYTHON_VERSION"
else
    fail "Python not installed"
    echo "  Install with: pkg install python"
fi

# 4. Check Python Modules
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Python Module Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$PYTHON_CMD" ]; then
    # socket
    if $PYTHON_CMD -c "import socket" 2>/dev/null; then
        pass "socket module available"
    else
        fail "socket module missing (standard library, should be available)"
    fi

    # threading
    if $PYTHON_CMD -c "import threading" 2>/dev/null; then
        pass "threading module available"
    else
        fail "threading module missing (standard library, should be available)"
    fi

    # argparse
    if $PYTHON_CMD -c "import argparse" 2>/dev/null; then
        pass "argparse module available"
    else
        fail "argparse module missing (standard library, should be available)"
    fi
fi

# 5. Check Network Capabilities
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Network Capability Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$PYTHON_CMD" ]; then
    # Test TCP socket binding
    TCP_TEST=$($PYTHON_CMD -c "
import socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', 7300))
    s.close()
    print('OK')
except Exception as e:
    print(f'FAIL: {e}')
" 2>&1)

    if [ "$TCP_TEST" = "OK" ]; then
        pass "Can bind TCP socket to port 7300"
    else
        fail "Cannot bind TCP socket: $TCP_TEST"
    fi

    # Test UDP socket binding
    UDP_TEST=$($PYTHON_CMD -c "
import socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(('0.0.0.0', 7301))
    s.close()
    print('OK')
except Exception as e:
    print(f'FAIL: {e}')
" 2>&1)

    if [ "$UDP_TEST" = "OK" ]; then
        pass "Can bind UDP socket"
    else
        fail "Cannot bind UDP socket: $UDP_TEST"
    fi

    # Test outbound connectivity
    OUTBOUND_TEST=$($PYTHON_CMD -c "
import socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    s.connect(('8.8.8.8', 53))
    s.close()
    print('OK')
except Exception as e:
    print(f'FAIL: {e}')
" 2>&1)

    if [ "$OUTBOUND_TEST" = "OK" ]; then
        pass "Outbound network connectivity OK"
    else
        warn "Outbound connectivity test failed: $OUTBOUND_TEST"
    fi
fi

# 6. Check Network Interfaces
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Network Interface Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v ifconfig &> /dev/null; then
    # Check for wlan0
    if ifconfig wlan0 &> /dev/null; then
        IP_ADDR=$(ifconfig wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | head -1)
        if [ -n "$IP_ADDR" ]; then
            pass "WiFi interface (wlan0) available: $IP_ADDR"
        else
            warn "WiFi interface available but no IP assigned"
        fi
    else
        warn "WiFi interface (wlan0) not found - may be disconnected"
    fi
elif command -v ip &> /dev/null; then
    if ip link show wlan0 &> /dev/null; then
        IP_ADDR=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
        if [ -n "$IP_ADDR" ]; then
            pass "WiFi interface (wlan0) available: $IP_ADDR"
        else
            warn "WiFi interface available but no IP assigned"
        fi
    else
        warn "WiFi interface (wlan0) not found"
    fi
else
    warn "Cannot check network interfaces (ifconfig/ip not available)"
fi

# 7. Check Privileged Ports
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Privileged Port Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$(id -u)" -eq 0 ]; then
    warn "Running as root - privileged ports (<1024) allowed"
else
    pass "Running as regular user - privileged ports (<1024) NOT allowed"
    info "Use ports >= 1024 (default: 7300)"
fi

# 8. Check Utility Tools
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Utility Tools Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOOLS="curl wget nano procps htop"
for tool in $TOOLS; do
    if command -v $tool &> /dev/null; then
        pass "$tool installed"
    else
        info "$tool not installed (optional)"
    fi
done

# 9. Battery Optimization Check (Android specific)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9. Power Management Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v termux-wake-lock &> /dev/null; then
    pass "termux-api available (wake-lock support)"
else
    info "termux-api not installed - cannot use wake-lock"
    echo "  Install with: pkg install termux-api"
fi

if command -v dumpsys &> /dev/null; then
    BATTERY_OPT=$(dumpsys deviceidle whitelist 2>/dev/null | grep -i termux || true)
    if [ -n "$BATTERY_OPT" ]; then
        pass "Termux is in battery optimization whitelist"
    else
        warn "Termux may be affected by battery optimization"
        echo "  Go to: Settings > Apps > Termux > Battery > Unrestricted"
    fi
fi

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    SUMMARY                               ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo -e "║  ${GREEN}Passed:${NC} $PASS_COUNT                                              ║"
echo -e "║  ${YELLOW}Warnings:${NC} $WARN_COUNT                                            ║"
echo -e "║  ${RED}Failed:${NC} $FAIL_COUNT                                              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}Your system is compatible with UDP Relay!${NC}"
    echo ""
    echo "Quick start:"
    echo "  ./termux/start-relay.sh"
    echo ""
else
    echo -e "${RED}Some issues were found. Please fix them before running UDP Relay.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  Install Python:  pkg install python"
    echo "  Run setup:       ./termux/setup.sh"
    echo ""
fi

# Exit with appropriate code
if [ $FAIL_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi
