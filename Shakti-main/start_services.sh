#!/bin/bash

##############################################################################
# Start All Services Concurrently
# Runs Tor, AP, and API services in background without blocking
# No Ctrl+C required to keep running
##############################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "Starting All Services"
echo "==========================================${NC}"
echo ""

mkdir -p logs

# Start Tor Service
echo -e "${YELLOW}[1/4]${NC} Starting Tor Router..."
python3 tor_monitor.py > logs/tor_monitor.log 2>&1 &
TOR_PID=$!
echo $TOR_PID > logs/tor_service.pid
echo -e "${GREEN}✓ Tor Service started (PID: $TOR_PID)${NC}"
sleep 1

# Start AP Service
echo -e "${YELLOW}[2/4]${NC} Starting Access Point..."
python3 ap_setup.py > logs/ap_service.log 2>&1 &
AP_PID=$!
echo $AP_PID > logs/ap_service.pid
echo -e "${GREEN}✓ Access Point Service started (PID: $AP_PID)${NC}"
sleep 1

# Start WIDS Engine
echo -e "${YELLOW}[3/4]${NC} Starting WIDS Engine..."
python3 main.py > logs/wids_engine.log 2>&1 &
WIDS_PID=$!
echo $WIDS_PID > logs/wids_engine.pid
echo -e "${GREEN}✓ WIDS Engine started (PID: $WIDS_PID)${NC}"
sleep 1

# Start API Server
echo -e "${YELLOW}[4/4]${NC} Starting API Server..."
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi
python api_server.py > logs/api_server.log 2>&1 &
API_PID=$!
echo $API_PID > logs/api_server.pid
echo -e "${GREEN}✓ API Server started (PID: $API_PID)${NC}"

echo ""
echo -e "${GREEN}=========================================="
echo "All Services Started Successfully!"
echo "==========================================${NC}"
echo ""

# Wait for API to be ready
sleep 3

# Check status
echo -e "${BLUE}=== SERVICE STATUS ===${NC}"
echo -e "${GREEN}✓ Tor Service${NC}           (PID: $TOR_PID)  - Tor circuits monitoring"
echo -e "${GREEN}✓ Access Point Service${NC}  (PID: $AP_PID)  - WiFi @ 192.168.1.1"
echo -e "${GREEN}✓ WIDS Engine${NC}          (PID: $WIDS_PID) - Wireless intrusion detection"
echo -e "${GREEN}✓ API Server${NC}           (PID: $API_PID) - http://localhost:5000"
echo ""

echo -e "${BLUE}=== MONITORING COMMANDS ===${NC}"
echo "Tor logs:     tail -f logs/tor_monitor.log"
echo "AP logs:      tail -f logs/ap_service.log"
echo "WIDS logs:    tail -f logs/wids_engine.log"
echo "API logs:     tail -f logs/api_server.log"
echo ""

echo -e "${BLUE}=== API ENDPOINTS ===${NC}"
echo "Logs:         curl http://localhost:5000/logs"
echo "Devices:      curl http://localhost:5000/devices"
echo "Tor circuits: curl http://localhost:5000/tor-circuits"
echo "Network:      curl http://localhost:5000/network-usage"
echo "Block MAC:    curl -X POST http://localhost:5000/block-mac -H 'Content-Type: application/json' -d '{\"mac\":\"xx:xx:xx:xx:xx:xx\"}'"
echo ""

echo -e "${BLUE}=== TO MONITOR SERVICES ===${NC}"
echo "Interactive monitor: bash monitor_services.sh"
echo ""

# Keep script alive
while true; do
    sleep 60
done
