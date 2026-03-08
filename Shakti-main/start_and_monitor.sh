#!/bin/bash

##############################################################################
# Secure WiFi Gateway - Startup + Real-Time Monitoring
# This starts all services and then shows live monitoring
##############################################################################

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Secure WiFi Gateway - Startup + Monitoring"
echo "=========================================="
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# respect SKIP_AP env var for optional access point
SKIP_AP=${SKIP_AP:-0}

# Function to show monitoring menu
show_monitoring_menu() {
    echo ""
    echo "=========================================="
    echo "🎯 SYSTEM IS RUNNING - MONITORING MODE"
    echo "=========================================="
    echo ""
    echo "Available monitoring commands:"
    echo "1. ${GREEN}tail -f logs/wids_engine.log${NC}     - Live attack detection"
    echo "2. ${GREEN}tail -f logs/api_server.log${NC}     - API requests"
    echo "3. ${GREEN}tail -f logs/firewall.log${NC}       - Firewall actions"
    if [ "${SKIP_AP:-0}" -eq 0 ]; then
        echo "4. ${GREEN}watch -n 5 'hostapd_cli -i wlan2 list_sta'${NC} - Connected devices"
        echo "5. ${GREEN}curl http://localhost:5000/system-status${NC} - System stats"
        echo "6. ${GREEN}curl http://localhost:5000/logs${NC}         - Attack logs via API"
        echo "7. ${GREEN}curl http://localhost:5000/devices${NC}      - Connected devices via API"
    else
        echo "4. ${GREEN}curl http://localhost:5000/system-status${NC} - System stats"
        echo "5. ${GREEN}curl http://localhost:5000/logs${NC}         - Attack logs via API"
    fi
    echo "5. ${GREEN}curl http://localhost:5000/system-status${NC} - System stats"
    echo "6. ${GREEN}curl http://localhost:5000/logs${NC}         - Attack logs via API"
    echo "7. ${GREEN}curl http://localhost:5000/devices${NC}      - Connected devices via API"
    echo ""
    echo "Press Ctrl+C to stop all services and exit"
    echo "=========================================="
    echo ""
}

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down all services...${NC}"
    pkill -f "hostapd" 2>/dev/null || true
    pkill -f "dnsmasq" 2>/dev/null || true
    pkill -f "python3 main.py" 2>/dev/null || true
    pkill -f "python3 api_server.py" 2>/dev/null || true
    pkill -f "python3 tor_monitor.py" 2>/dev/null || true
    pkill -f "widrsx-backend" 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}All services stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start the system
echo "Starting all services..."
SKIP_AP=${SKIP_AP:-0} sudo bash start_all.sh

# Show monitoring menu
show_monitoring_menu

# Keep the script running and show live monitoring
echo "Starting live monitoring... (Press Ctrl+C to stop)"
echo ""

# Show initial status
echo -e "${BLUE}=== CURRENT STATUS ===${NC}"
ps aux | grep -E "hostapd|dnsmasq|python3|widrsx" | grep -v grep | wc -l
echo "services running"
echo ""

# Start monitoring the main log
echo -e "${GREEN}=== LIVE ATTACK DETECTION ===${NC}"
echo "Showing real-time wireless attack detection:"
echo ""

# Monitor the WIDS engine log
tail -f logs/wids_engine.log &

# Wait for user interrupt
wait