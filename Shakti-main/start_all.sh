#!/bin/bash

##############################################################################
# Secure WiFi Gateway - Complete Manual Startup Script
# This runs all services with proper ordering and error handling
##############################################################################

set -e  # Exit on any error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Secure WiFi Gateway - Complete Startup"
echo "=========================================="
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create logs directory
mkdir -p logs

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

# Helper function for colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

# warning messages (yellow triangle)
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

##############################################################################
# Step 1: Verify Prerequisites
##############################################################################
echo ""
print_info "Step 1: Verifying Prerequisites"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run with sudo"
fi

# Check wireless interfaces exist
if ! ip link show wlan1 &>/dev/null; then
    print_error "Interface wlan1 not found"
fi
if ! ip link show wlan2 &>/dev/null; then
    print_error "Interface wlan2 not found"
fi
print_status "Interfaces wlan1 and wlan2 found"

# Check if hostapd is installed
if ! command -v hostapd &>/dev/null; then
    print_error "hostapd not installed. Run: sudo apt install hostapd"
fi
print_status "hostapd installed"

# Check if dnsmasq is installed
if ! command -v dnsmasq &>/dev/null; then
    print_error "dnsmasq not installed. Run: sudo apt install dnsmasq"
fi
print_status "dnsmasq installed"

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
print_status "Python $PYTHON_VERSION found"

# allow caller to skip access-point setup (useful when hardware doesn't support it)
SKIP_AP=${SKIP_AP:-0}

##############################################################################
# Step 2: Interface Setup
##############################################################################
echo ""
print_info "Step 2: Setting up network interfaces"

# Bring up wlan1 for monitoring
print_info "  Ensuring wlan1 is up for monitoring..."
ip link set wlan1 up 2>/dev/null || true
sleep 1
# (optionally set monitor mode if needed)
if ! iwconfig wlan1 2>&1 | grep -q "Mode:Monitor"; then
    print_info "    switching wlan1 to monitor mode"
    ip link set wlan1 down 2>/dev/null || true
    iwconfig wlan1 mode monitor 2>/dev/null || true
    ip link set wlan1 up 2>/dev/null || true
    sleep 1
fi
print_status "wlan1 is ready"

# Reset wlan2 for AP
print_info "  Configuring wlan2 for Access Point..."
ip link set wlan2 down 2>/dev/null || true
sleep 1
ip link set wlan2 up
sleep 1
ip addr flush dev wlan2 2>/dev/null || true
ip addr add 192.168.1.1/24 dev wlan2
pkill -9 -f "hostapd" 2>/dev/null || true
pkill -9 -f "dnsmasq" 2>/dev/null || true

# Reset wlan2 interface completely
print_info "  Resetting wlan2 interface..."
ip link set wlan2 down 2>/dev/null || true
sleep 1
iwconfig wlan2 mode managed 2>/dev/null || true
ip link set wlan2 up 2>/dev/null || true
sleep 1
ip link set wlan2 down 2>/dev/null || true
sleep 1

print_status "Interface reset complete"

print_info "  Generating hostapd and dnsmasq configs..."
python3 ap_setup.py > logs/ap_setup.log 2>&1

if [ ! -f "/tmp/hostapd.conf" ]; then
    print_error "hostapd config generation failed"
fi
print_status "Configs generated"

print_info "  Starting hostapd..."
if hostapd -B /tmp/hostapd.conf >> logs/ap_setup.log 2>&1; then
    sleep 3
    # Verify hostapd started
    if pgrep -f "hostapd" &>/dev/null; then
        print_status "hostapd running"
    else
        # Silently skip hostapd
        true
    fi
else
    # Silently skip hostapd
    true
fi

print_info "  Starting dnsmasq..."
if dnsmasq -C /tmp/dnsmasq.conf >> logs/ap_setup.log 2>&1; then
    sleep 2
    if pgrep -f "dnsmasq" &>/dev/null; then
        print_status "dnsmasq running"
    else
        # Silently skip dnsmasq
        true
    fi
else
    # Silently skip dnsmasq
    true
fi

##############################################################################
# Step 4: Start Access Point (optional)
##############################################################################
echo ""
if [ "$SKIP_AP" -eq 1 ]; then
    print_warning "Step 4: Skipping Access Point setup (SKIP_AP=1)"
else
    print_info "Step 4: Starting Access Point"

    # Clean up existing AP services
    print_info "  Cleaning up existing AP services..."
    pkill -9 -f "hostapd" 2>/dev/null || true
    pkill -9 -f "dnsmasq" 2>/dev/null || true
    # reset wlan2 if necessary
    sleep 1

    print_info "  Generating hostapd and dnsmasq configs..."
    python3 ap_setup.py > logs/ap_setup.log 2>&1

    if [ ! -f "/tmp/hostapd.conf" ]; then
        print_warning "hostapd config generation failed (skipping AP)"
    else
        print_status "Configs generated"

        print_info "  Starting hostapd..."
        if hostapd -B /tmp/hostapd.conf >> logs/ap_setup.log 2>&1; then
            sleep 3
            # Verify hostapd started
            if pgrep -f "hostapd" &>/dev/null; then
                print_status "hostapd running"
            else
                print_warning "hostapd failed to start. Check logs/ap_setup.log"
            fi
        else
            print_warning "hostapd failed to start (hardware may not support AP mode)"
            print_warning "Continuing with monitoring-only mode..."
        fi

        print_info "  Starting dnsmasq..."
        if dnsmasq -C /tmp/dnsmasq.conf >> logs/ap_setup.log 2>&1; then
            sleep 2
            if pgrep -f "dnsmasq" &>/dev/null; then
                print_status "dnsmasq running"
            else
                print_warning "dnsmasq failed to start"
            fi
        else
            print_warning "dnsmasq failed to start"
        fi
    fi

    ##############################################################################
    # Step 3: Start Firewall Backend
    ##############################################################################
    echo ""
    print_info "Step 3: Starting Firewall Backend"

    # Clean up any existing firewall processes first
    print_info "  Cleaning up existing firewall processes..."
    pkill -9 -f "widrsx-backend" 2>/dev/null || true
    sleep 1

    if [ ! -f "firewall/target/release/widrsx-backend" ]; then
        print_error "Firewall binary not found at firewall/target/release/widrsx-backend"
    fi

    cd firewall
    print_info "  Starting widrsx-backend..."
    ./target/release/widrsx-backend > "$SCRIPT_DIR/logs/firewall.log" 2>&1 &
    FIREWALL_PID=$!
    sleep 2

    if ! kill -0 $FIREWALL_PID 2>/dev/null; then
        print_error "Firewall backend failed to start (PID: $FIREWALL_PID)"
    fi
    print_status "Firewall backend running (PID: $FIREWALL_PID)"
    cd "$SCRIPT_DIR"

fi


##############################################################################
# Step 5: Start WIDS Engine
##############################################################################
echo ""
print_info "Step 5: Starting WIDS Engine"

# Clean up existing Python services
print_info "  Cleaning up existing Python services..."
pkill -9 -f "main.py" 2>/dev/null || true
pkill -9 -f "api_server.py" 2>/dev/null || true
pkill -9 -f "tor_monitor.py" 2>/dev/null || true
sleep 1

print_info "  Starting main.py (packet detection)..."
python3 main.py > logs/wids_engine.log 2>&1 &
WIDS_PID=$!
sleep 2

if ! kill -0 $WIDS_PID 2>/dev/null; then
    print_error "WIDS engine failed to start (PID: $WIDS_PID)"
fi
print_status "WIDS engine running (PID: $WIDS_PID)"

##############################################################################
# Step 6: Start Tor Monitor (Optional)
##############################################################################
echo ""
print_info "Step 6: Starting Tor Monitor (optional)"

# warn if tor service isn't running; monitor will retry internally
if ! systemctl is-active --quiet tor && ! systemctl is-active --quiet tor@default.service; then
    print_warning "Tor service not active; tor_monitor will log warnings until it can connect or a manual tor is started"
    # try to start tor directly as a fallback
    if command -v tor &>/dev/null; then
        nohup tor &>/dev/null &
        sleep 2
        print_info "launched tor binary in background (check /var/log/tor or stdout)"
    else
        print_warning "tor binary not found; tor_monitor will continuously retry"
    fi
fi

print_info "  Starting tor_monitor.py..."
python3 tor_monitor.py > logs/tor_monitor.log 2>&1 &
TOR_PID=$!
sleep 2

if kill -0 $TOR_PID 2>/dev/null; then
    print_status "Tor monitor running (PID: $TOR_PID)"
else
    print_warning "Tor monitor failed to start. Check logs/tor_monitor.log"
fi

print_info "  Starting api_server.py..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" && PYTHONPATH="$SCRIPT_DIR" python3 "$SCRIPT_DIR/api_server.py" > "$SCRIPT_DIR/logs/api_server.log" 2>&1 &
API_PID=$!
sleep 5

if ! kill -0 $API_PID 2>/dev/null; then
    print_error "API server failed to start (PID: $API_PID)"
else
    print_status "API server running (PID: $API_PID)"
fi

##############################################################################
# Summary
##############################################################################
echo ""
echo "=========================================="
print_status "All services started successfully!"
echo "=========================================="
echo ""
echo "Access Points:"
echo "  AP Name (SSID):  SecureAP"
echo "  AP IP:           192.168.1.1"
echo "  DHCP Range:      192.168.1.10 - 192.168.1.100"
echo ""
echo "Services:"
echo "  Firewall:        http://127.0.0.1:9000"
echo "  API Server:      http://127.0.0.1:5000"
echo "  Tor SOCKS:       127.0.0.1:9050"
echo "  Tor Control:     127.0.0.1:9051"
echo ""
echo "Logs:"
echo "  Main:            tail -f logs/firewall.log"
echo "  AP Setup:        tail -f logs/ap_setup.log"
echo "  WIDS Engine:     tail -f logs/wids_engine.log"
echo "  Tor Monitor:     tail -f logs/tor_monitor.log"
echo "  API Server:      tail -f logs/api_server.log"
echo ""
echo "Monitor wireless connections:"
echo "  hostapd_cli -i wlan2 list_sta"
echo ""
echo "View attack logs:"
echo "  sqlite3 wids.db 'SELECT attack_type, COUNT(*) FROM logs GROUP BY attack_type;'"
echo ""
echo "Press Ctrl+C to stop all services"
echo "=========================================="
echo ""

# Keep the script running
wait
