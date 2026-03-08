#!/bin/bash

##############################################################################
# Start Access Point Service Only
# Runs AP in background without blocking
##############################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Access Point Service...${NC}"
mkdir -p logs

# Start AP setup in background
python3 ap_setup.py > logs/ap_service.log 2>&1 &
AP_PID=$!

echo -e "${GREEN}✓ Access Point service started (PID: $AP_PID)${NC}"
echo "  Log: logs/ap_service.log"
echo "  SSID: SecureAP @ 192.168.1.1"
echo $AP_PID > logs/ap_service.pid

# Keep script running
sleep 2
echo "AP service is running. Monitor with: tail -f logs/ap_service.log"
