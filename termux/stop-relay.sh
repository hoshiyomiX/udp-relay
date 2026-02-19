#!/bin/bash
# Stop UDP Relay Server on Termux/Android

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PID_FILE="$PROJECT_DIR/.relay.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "  UDP Relay - Stopping Server"
echo "========================================"
echo ""

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}No running relay server found${NC}"
    echo "(PID file does not exist)"
    echo ""

    # Try to find and kill any running main.py processes
    echo "Searching for any running relay processes..."
    FOUND_PIDS=$(pgrep -f "python.*main.py" 2>/dev/null || true)

    if [ -n "$FOUND_PIDS" ]; then
        echo "Found process(es): $FOUND_PIDS"
        read -p "Kill these processes? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for pid in $FOUND_PIDS; do
                kill "$pid" 2>/dev/null && echo -e "${GREEN}✓ Killed PID $pid${NC}" || echo -e "${RED}✗ Could not kill PID $pid${NC}"
            done
        fi
    else
        echo "No relay processes found."
    fi
    exit 0
fi

# Read PID
PID=$(cat "$PID_FILE")

# Validate PID is a number
if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid PID in file: $PID${NC}"
    rm -f "$PID_FILE"
    exit 1
fi

# Check if process is running
if ! kill -0 "$PID" 2>/dev/null; then
    echo -e "${YELLOW}Relay server is not running${NC}"
    echo "(Stale PID file found)"
    rm -f "$PID_FILE"
    exit 0
fi

# Get process info
PROCESS_INFO=$(ps -p "$PID" -o comm= 2>/dev/null || echo "unknown")
echo "Found relay server:"
echo "  PID: $PID"
echo "  Process: $PROCESS_INFO"
echo ""

# Stop the server
echo "Stopping UDP Relay..."
kill "$PID" 2>/dev/null

# Wait for process to terminate (with timeout)
TIMEOUT=10
for i in $(seq 1 $TIMEOUT); do
    if ! kill -0 "$PID" 2>/dev/null; then
        break
    fi
    sleep 1
    echo "  Waiting... ($i/$TIMEOUT)"
done

# Force kill if still running
if kill -0 "$PID" 2>/dev/null; then
    echo -e "${YELLOW}Process did not exit gracefully, force killing...${NC}"
    kill -9 "$PID" 2>/dev/null
    sleep 1
fi

# Verify process is stopped
if kill -0 "$PID" 2>/dev/null; then
    echo -e "${RED}✗ Failed to stop process $PID${NC}"
    exit 1
fi

# Clean up
rm -f "$PID_FILE"

echo ""
echo -e "${GREEN}✓ UDP Relay stopped successfully!${NC}"
echo ""
echo "========================================"
