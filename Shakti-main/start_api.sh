#!/bin/bash

##############################################################################
# Start API Server Only
# Runs API server in background without blocking
##############################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting API Server...${NC}"
mkdir -p logs

# Activate virtual environment if it exists
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

# Start API server in background
python api_server.py > logs/api_server.log 2>&1 &
API_PID=$!

echo -e "${GREEN}✓ API Server started (PID: $API_PID)${NC}"
echo "  URL: http://localhost:5000"
echo "  Log: logs/api_server.log"
echo $API_PID > logs/api_server.pid

# Wait for server to start
sleep 2

# Check if server is responding
if curl -s http://localhost:5000/logs > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API Server is responding${NC}"
    echo ""
    echo "Available endpoints:"
    echo "  GET  http://localhost:5000/logs            - Attack logs"
    echo "  GET  http://localhost:5000/devices         - Connected devices"
    echo "  GET  http://localhost:5000/tor-circuits    - Tor circuits"
    echo "  GET  http://localhost:5000/network-usage   - Network stats"
    echo "  POST http://localhost:5000/block-mac       - Block device"
else
    echo -e "${BLUE}API Server starting, may take a moment...${NC}"
fi

echo ""
echo "Monitor with: tail -f logs/api_server.log"
