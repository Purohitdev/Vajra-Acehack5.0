#!/bin/bash

##############################################################################
# Secure WiFi Gateway - Real-Time Monitoring Dashboard
# Run this after starting the system to monitor everything
##############################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "🎯 Secure WiFi Gateway - MONITORING MODE"
echo "=========================================="
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if system is running
check_services() {
    local running=$(ps aux | grep -E "hostapd|dnsmasq|python3|widrsx" | grep -v grep | wc -l)
    if [ "$running" -lt 4 ]; then
        echo -e "${RED}⚠️  WARNING: Only $running services running. Start system first!${NC}"
        echo "Run: sudo bash start_all.sh"
        exit 1
    fi
}

# Show system status
show_status() {
    echo -e "${BLUE}=== SYSTEM STATUS ===${NC}"
    echo "Services running: $(ps aux | grep -E "hostapd|dnsmasq|python3|widrsx" | grep -v grep | wc -l)"
    echo "WiFi AP: SecureAP (192.168.1.1)"
    echo "API: http://localhost:5000"
    echo "Attack logs: $(sqlite3 logs/wifi_attack_logs.db "SELECT COUNT(*) FROM logs;" 2>/dev/null || echo "N/A") detected"
    echo ""
}

# Show monitoring menu
show_menu() {
    echo -e "${GREEN}=== MONITORING COMMANDS ===${NC}"
    echo "Choose what to monitor (run in separate terminals):"
    echo ""
    echo "1. ${YELLOW}Live Attack Detection${NC}"
    echo "   tail -f logs/wids_engine.log"
    echo ""
    echo "2. ${YELLOW}API Server Activity${NC}"
    echo "   tail -f logs/api_server.log"
    echo ""
    echo "3. ${YELLOW}Connected Devices${NC}"
    echo "   watch -n 5 'hostapd_cli -i wlan2 list_sta'"
    echo ""
    echo "4. ${YELLOW}System Statistics${NC}"
    echo "   watch -n 10 'curl -s http://localhost:5000/system-status'"
    echo ""
    echo "5. ${YELLOW}Attack Statistics${NC}"
    echo "   watch -n 30 'sqlite3 logs/wifi_attack_logs.db \"SELECT attack_type, COUNT(*) FROM (SELECT CASE WHEN message LIKE '\\'%Beacon%\\' THEN '\\'Beacon Flood\\' WHEN message LIKE '\\'%Deauth%\\' THEN '\\'Deauthentication\\' ELSE '\\'Other\\' END as attack_type FROM logs) GROUP BY attack_type;\"'"
    echo ""
    echo "6. ${YELLOW}Network Usage${NC}"
    echo "   watch -n 10 'curl -s http://localhost:5000/network-usage'"
    echo ""
    echo "7. ${YELLOW}Firewall Actions${NC}"
    echo "   tail -f logs/firewall.log"
    echo ""
    echo -e "${RED}Press Ctrl+C to exit monitoring${NC}"
    echo "=========================================="
    echo ""
}

# Main monitoring loop
main() {
    check_services
    show_status
    show_menu

    echo -e "${GREEN}Starting live attack monitoring...${NC}"
    echo "Showing real-time wireless security events:"
    echo ""

    # Start monitoring
    tail -f logs/wids_engine.log
}

# Cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Monitoring stopped. Services still running.${NC}"
    echo "To stop all services: sudo pkill -f 'hostapd\|dnsmasq\|python3\|widrsx'"
    exit 0
}

trap cleanup SIGINT SIGTERM

main