#!/bin/bash

##############################################################################
# Start WIDS Engine Service Only
# Runs WIDS (Wireless Intrusion Detection System) in background without blocking
##############################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Starting WIDS Engine Service...${NC}"
mkdir -p logs

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}WIDS requires root privileges. Running with sudo...${NC}"
    sudo -u bhairavam bash "$0"
    exit 0
fi

# Start WIDS engine (main.py) in background
# main.py performs packet sniffing and attack detection
python3 main.py > logs/wids_engine.log 2>&1 &
WIDS_PID=$!

echo -e "${GREEN}✓ WIDS Engine started (PID: $WIDS_PID)${NC}"
echo "  Log: logs/wids_engine.log"
echo "  Function: Wireless packet sniffing and intrusion detection"
echo $WIDS_PID > logs/wids_engine.pid

# Keep script running
sleep 2
echo ""
echo "WIDS Engine is running. Monitor with: tail -f logs/wids_engine.log"
