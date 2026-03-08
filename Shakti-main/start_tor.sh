#!/bin/bash

##############################################################################
# Start Tor Service Only
# Runs Tor monitor in background without blocking
##############################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Tor Router Service...${NC}"
mkdir -p logs

# Start Tor monitor in background
python3 tor_monitor.py > logs/tor_monitor.log 2>&1 &
TOR_PID=$!

echo -e "${GREEN}✓ Tor service started (PID: $TOR_PID)${NC}"
echo "  Log: logs/tor_monitor.log"
echo $TOR_PID > logs/tor_service.pid

# Keep script running
sleep 2
echo "Tor service is running. Monitor with: tail -f logs/tor_monitor.log"
