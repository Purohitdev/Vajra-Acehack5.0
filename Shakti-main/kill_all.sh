#!/bin/bash

##############################################################################
# Clean Kill Script - Stop All WiFi Security Gateway Services
##############################################################################

echo "🛑 Killing all WiFi Security Gateway processes..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${GREEN}ℹ️${NC} $1"
}

# Step 1: Kill all Python services
print_info "Killing Python services..."
pkill -9 -f "python3 main.py" 2>/dev/null || true
pkill -9 -f "python3 api_server.py" 2>/dev/null || true
pkill -9 -f "python3 tor_monitor.py" 2>/dev/null || true
pkill -9 -f "python3 database.py" 2>/dev/null || true
print_success "Python services killed"

# Step 2: Kill firewall backend
print_info "Killing firewall backend..."
pkill -9 -f "widrsx-backend" 2>/dev/null || true
print_success "Firewall backend killed"

# Step 3: Kill AP services
print_info "Killing AP services..."
pkill -9 -f "hostapd" 2>/dev/null || true
pkill -9 -f "dnsmasq" 2>/dev/null || true
print_success "AP services killed"

# Step 4: Reset network interfaces
print_info "Resetting network interfaces..."
ip link set wlan1 down 2>/dev/null || true
ip link set wlan2 down 2>/dev/null || true
sleep 1
print_success "Interfaces reset"

# Step 5: Clean up any remaining processes
print_info "Cleaning up any remaining processes..."
pkill -9 -f "start_all.sh" 2>/dev/null || true
pkill -9 -f "demo_start.sh" 2>/dev/null || true
pkill -9 -f "start_and_monitor.sh" 2>/dev/null || true

# Step 6: Verify cleanup
sleep 2
REMAINING=$(ps aux | grep -E "(widrsx|main.py|api_server.py|tor_monitor.py|hostapd|dnsmasq)" | grep -v grep | wc -l)

if [ "$REMAINING" -eq 0 ]; then
    print_success "All processes killed successfully"
else
    print_warning "Some processes may still be running: $REMAINING found"
fi

echo ""
print_success "System ready for clean restart!"
echo "Run: sudo ./demo_start.sh"