#!/bin/bash

##############################################################################
# Start API Server with  Endpoints
# Runs API server on port 5002 and provides easy access to all endpoints
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
echo "API Server -  Mode (Port 5002)"
echo "==========================================${NC}"
echo ""

mkdir -p logs

# Activate virtual environment
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

# Kill any existing API server on port 5002
pkill -f "api_server.py.*--port 5002" 2>/dev/null || true
sleep 1

# Start API server on port 5002
echo -e "${YELLOW}Starting API Server on port 5002...${NC}"
python api_server.py --port 5002 > logs/api_server_demo.log 2>&1 &
API_PID=$!

# Save PID
echo $API_PID > logs/api_demo.pid

# Wait for server to start
sleep 3

# Check if server is running
if ps -p $API_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API Server started successfully (PID: $API_PID)${NC}"
    echo ""
else
    echo -e "${RED}✗ API Server failed to start${NC}"
    cat logs/api_server_demo.log
    exit 1
fi

# Display API endpoints
echo -e "${BLUE}=========================================="
echo "Available API Endpoints (Port 5002)"
echo "==========================================${NC}"
echo ""

echo -e "${GREEN}1. TOR CIRCUITS${NC}"
echo "   Endpoint: http://localhost:5002/tor-circuits"
echo "   Test: curl http://localhost:5002/tor-circuits"
echo ""

echo -e "${GREEN}2. NETWORK USAGE${NC}"
echo "   Endpoint: http://localhost:5002/network-usage"
echo "   Test: curl http://localhost:5002/network-usage"
echo ""

echo -e "${GREEN}3. LOGS${NC}"
echo "   Endpoint: http://localhost:5002/logs"
echo "   Test: curl http://localhost:5002/logs"
echo ""

echo -e "${GREEN}4. DEVICES${NC}"
echo "   Endpoint: http://localhost:5002/devices"
echo "   Test: curl http://localhost:5002/devices"
echo ""

echo -e "${GREEN}5. SYSTEM STATUS${NC}"
echo "   Endpoint: http://localhost:5002/system-status"
echo "   Test: curl http://localhost:5002/system-status"
echo ""

echo -e "${BLUE}=========================================="
echo "Quick Test Commands"
echo "==========================================${NC}"
echo ""

echo -e "${YELLOW}Test Tor Circuits (with random location data):${NC}"
echo "curl -s http://localhost:5002/tor-circuits | python3 -m json.tool | head -20"
echo ""

echo -e "${YELLOW}Test Network Usage (with mock data if empty):${NC}"
echo "curl -s http://localhost:5002/network-usage | python3 -m json.tool"
echo ""

echo -e "${BLUE}=========================================="
echo "Server Information"
echo "==========================================${NC}"
echo ""
echo "API Server PID: $API_PID"
echo "Log File: logs/api_server_demo.log"
echo "Port: 5002"
echo ""

echo -e "${YELLOW}To view logs in real-time:${NC}"
echo "tail -f logs/api_server_demo.log"
echo ""

echo -e "${YELLOW}To stop the server:${NC}"
echo "kill $API_PID"
echo ""

# Keep script running
echo -e "${GREEN}API Server is running. Press Ctrl+C to stop.${NC}"
echo ""

# Monitor server
while true; do
    if ! ps -p $API_PID > /dev/null 2>&1; then
        echo -e "${RED}API Server stopped unexpectedly${NC}"
        exit 1
    fi
    sleep 5
done
