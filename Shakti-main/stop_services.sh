#!/bin/bash

##############################################################################
# Stop All Services Safely
# Gracefully stops Tor, AP, and API services
##############################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Stopping All Services...${NC}"
echo ""

# Function to stop a service
stop_service() {
    local name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        PID=$(cat "$pid_file")
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${YELLOW}Stopping $name (PID: $PID)...${NC}"
            kill -TERM $PID 2>/dev/null || true
            sleep 1
            if ps -p $PID > /dev/null 2>&1; then
                echo -e "${RED}Force killing $name...${NC}"
                kill -9 $PID 2>/dev/null || true
            fi
            echo -e "${GREEN}✓ $name stopped${NC}"
            rm -f "$pid_file"
        else
            echo -e "${RED}✗ $name not running${NC}"
            rm -f "$pid_file"
        fi
    else
        echo -e "${BLUE}$name PID file not found${NC}"
    fi
}

# Stop all services
stop_service "Tor Service" "logs/tor_service.pid"
stop_service "Access Point" "logs/ap_service.pid"
stop_service "WIDS Engine" "logs/wids_engine.pid"
stop_service "API Server" "logs/api_server.pid"

# Also kill any remaining processes
pkill -f "tor_monitor.py" 2>/dev/null || true
pkill -f "ap_setup.py" 2>/dev/null || true
pkill -f "main.py" 2>/dev/null || true
pkill -f "api_server.py" 2>/dev/null || true

echo ""
echo -e "${GREEN}All services stopped${NC}"
