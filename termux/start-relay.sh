#!/bin/bash
# Start UDP Relay Server on Termux/Android

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default port
PORT=${1:-7300}

# PID file location
PID_FILE="$PROJECT_DIR/.relay.pid"
LOG_FILE="$PROJECT_DIR/relay.log"

# Colors (may not work in all terminals)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "  UDP Relay - Starting Server"
echo "========================================"
echo ""

# Detect Python executable
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

# Check if Python is installed
if [ -z "$PYTHON_CMD" ]; then
    echo -e "${RED}Error: Python is not installed.${NC}"
    echo "Please run: ./termux/setup.sh"
    exit 1
fi

# Display Python version
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo "Using: $PYTHON_VERSION"

# Check if main.py exists
if [ ! -f "$PROJECT_DIR/main.py" ]; then
    echo -e "${RED}Error: main.py not found in $PROJECT_DIR${NC}"
    exit 1
fi

# Verify required Python modules
echo ""
echo "Checking required modules..."

check_module() {
    if $PYTHON_CMD -c "import $1" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1"
        return 1
    fi
}

MODULES_OK=true
check_module "socket" || MODULES_OK=false
check_module "threading" || MODULES_OK=false
check_module "argparse" || MODULES_OK=false

if [ "$MODULES_OK" = false ]; then
    echo -e "${RED}Error: Missing required Python modules${NC}"
    echo "These are standard library modules. Your Python installation may be broken."
    exit 1
fi

# Validate port number
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo -e "${RED}Error: Invalid port number: $PORT${NC}"
    echo "Port must be between 1 and 65535"
    exit 1
fi

# Check for privileged port
if [ "$PORT" -lt 1024 ]; then
    echo -e "${YELLOW}Warning: Port $PORT is a privileged port (< 1024)${NC}"
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: Binding to port $PORT requires root privileges${NC}"
        echo "Use a port >= 1024 or run with sudo/root"
        exit 1
    fi
fi

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo -e "${YELLOW}Warning: Relay server is already running (PID: $OLD_PID)${NC}"
        echo "To restart, first run: ./termux/stop-relay.sh"
        exit 1
    else
        # Clean up stale PID file
        rm -f "$PID_FILE"
    fi
fi

# Check if port is already in use
if command -v netstat &> /dev/null; then
    if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo -e "${RED}Error: Port $PORT is already in use${NC}"
        netstat -tuln | grep ":$PORT "
        exit 1
    fi
elif command -v ss &> /dev/null; then
    if ss -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo -e "${RED}Error: Port $PORT is already in use${NC}"
        ss -tuln | grep ":$PORT "
        exit 1
    fi
fi

echo ""
echo "Starting UDP Relay on port $PORT..."
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Start the server in background
nohup $PYTHON_CMD main.py --port "$PORT" >> "$LOG_FILE" 2>&1 &
PID=$!

# Wait a moment to check if it started successfully
sleep 2

if kill -0 "$PID" 2>/dev/null; then
    # Save PID to file
    echo "$PID" > "$PID_FILE"

    echo -e "${GREEN}✓ UDP Relay started successfully!${NC}"
    echo ""
    echo "  PID:  $PID"
    echo "  Port: $PORT"
    echo "  Log:  $LOG_FILE"
    echo ""

    # Show IP address if available
    if command -v ifconfig &> /dev/null; then
        IP_ADDR=$(ifconfig wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | head -1)
        if [ -n "$IP_ADDR" ]; then
            echo "  Local IP: $IP_ADDR"
            echo ""
        fi
    elif command -v ip &> /dev/null; then
        IP_ADDR=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
        if [ -n "$IP_ADDR" ]; then
            echo "  Local IP: $IP_ADDR"
            echo ""
        fi
    fi

    echo "Commands:"
    echo "  Stop server: ./termux/stop-relay.sh"
    echo "  View logs:   tail -f $LOG_FILE"
    echo "  Test client: python client_example.py"
else
    echo -e "${RED}✗ Failed to start UDP Relay${NC}"
    echo ""
    echo "Last 20 lines of log file:"
    echo "---"
    tail -20 "$LOG_FILE" 2>/dev/null || echo "(No log output)"
    echo "---"
    rm -f "$PID_FILE"
    exit 1
fi

echo ""
echo "========================================"
