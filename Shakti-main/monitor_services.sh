#!/bin/bash

##############################################################################
# Monitor Running Services
# Shows live logs and status of all running services
##############################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_status() {
    echo -e "${BLUE}=== SERVICE STATUS ===${NC}"
    echo ""
    
    # Check each service
    if [ -f "logs/tor_service.pid" ]; then
        TOR_PID=$(cat logs/tor_service.pid)
        if ps -p $TOR_PID > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Tor Service${NC} (PID: $TOR_PID)"
        else
            echo -e "${RED}✗ Tor Service${NC} (Not running)"
        fi
    fi
    
    if [ -f "logs/ap_service.pid" ]; then
        AP_PID=$(cat logs/ap_service.pid)
        if ps -p $AP_PID > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Access Point Service${NC} (PID: $AP_PID)"
        else
            echo -e "${RED}✗ Access Point Service${NC} (Not running)"
        fi
    fi
    
    if [ -f "logs/wids_engine.pid" ]; then
        WIDS_PID=$(cat logs/wids_engine.pid)
        if ps -p $WIDS_PID > /dev/null 2>&1; then
            echo -e "${GREEN}✓ WIDS Engine${NC} (PID: $WIDS_PID)"
        else
            echo -e "${RED}✗ WIDS Engine${NC} (Not running)"
        fi
    fi
    
    if [ -f "logs/api_server.pid" ]; then
        API_PID=$(cat logs/api_server.pid)
        if ps -p $API_PID > /dev/null 2>&1; then
            echo -e "${GREEN}✓ API Server${NC} (PID: $API_PID)"
            echo "   URL: http://localhost:5000"
        else
            echo -e "${RED}✗ API Server${NC} (Not running)"
        fi
    fi
    
    echo ""
}

show_menu() {
    echo -e "${BLUE}=========================================="
    echo "Service Monitoring Dashboard"
    echo "==========================================${NC}"
    echo ""
    show_status
    echo "Monitoring Options:"
    echo "  1. Tail Tor logs"
    echo "  2. Tail AP logs"
    echo "  3. Tail WIDS logs"
    echo "  4. Tail API logs"
    echo "  5. Show API endpoints"
    echo "  6. Check system status"
    echo "  7. Refresh status"
    echo "  0. Exit"
    echo ""
}

# Main monitoring loop
while true; do
    clear
    show_menu
    read -p "Select option (0-7): " choice
    
    case $choice in
        1)
            if [ -f "logs/tor_monitor.log" ]; then
                tail -f logs/tor_monitor.log
            else
                echo "Tor log not found"
                sleep 2
            fi
            ;;
        2)
            if [ -f "logs/ap_service.log" ]; then
                tail -f logs/ap_service.log
            else
                echo "AP log not found"
                sleep 2
            fi
            ;;
        3)
            if [ -f "logs/wids_engine.log" ]; then
                tail -f logs/wids_engine.log
            else
                echo "WIDS log not found"
                sleep 2
            fi
            ;;
        4)
            if [ -f "logs/api_server.log" ]; then
                tail -f logs/api_server.log
            else
                echo "API log not found"
                sleep 2
            fi
            ;;
        5)
            echo -e "${BLUE}=== API ENDPOINTS ===${NC}"
            echo ""
            echo "Attack Logs:"
            echo "  GET http://localhost:5000/logs"
            echo ""
            echo "Connected Devices:"
            echo "  GET http://localhost:5000/devices"
            echo ""
            echo "Tor Circuits:"
            echo "  GET http://localhost:5000/tor-circuits"
            echo ""
            echo "Network Usage:"
            echo "  GET http://localhost:5000/network-usage"
            echo ""
            echo "Block Device:"
            echo "  POST http://localhost:5000/block-mac (JSON: {\"mac\": \"xx:xx:xx:xx:xx:xx\"})"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        6)
            echo -e "${BLUE}=== SYSTEM STATUS ===${NC}"
            if curl -s http://localhost:5000/system-status 2>/dev/null | python3 -m json.tool 2>/dev/null; then
                :
            else
                echo "System status unavailable (API not responding)"
            fi
            read -p "Press Enter to continue..."
            ;;
        7)
            # Just refresh the loop
            ;;
        0)
            echo -e "${GREEN}Exiting monitor...${NC}"
            exit 0
            ;;
        *)
            echo "Invalid option"
            sleep 2
            ;;
    esac
done
