#!/bin/bash

# Secure WiFi Access Point with WIDS and Tor Routing Startup Script
# Debug version with wlan1 (monitor) and wlan2 (AP)

set -e  # Exit on any error
set -x  # Debug mode - show all commands

echo "[*] Starting Secure WiFi Gateway System..."
echo "[*] Monitor Interface: wlan1"
echo "[*] AP Interface: wlan2"
echo "[*] Internet Interface: eth0"

# Function to check if interface exists
check_interface() {
    if ! iwconfig $1 &>/dev/null; then
        echo "[ERROR] Interface $1 not found!"
        exit 1
    fi
}

# Function to cleanup on exit
cleanup() {
    echo "[*] Cleaning up..."
    sudo ifconfig wlan1 down 2>/dev/null || true
    sudo iwconfig wlan1 mode managed 2>/dev/null || true
    sudo ifconfig wlan1 up 2>/dev/null || true
    echo "[*] Cleanup complete"
}

trap cleanup EXIT

# Check interfaces
echo "[*] Checking network interfaces..."
check_interface wlan1
check_interface wlan2
check_interface eth0

# Set monitor mode for wlan1
echo "[*] Setting wlan1 to monitor mode..."
sudo ifconfig wlan1 down
sudo iwconfig wlan1 mode monitor
sudo ifconfig wlan1 up
sudo iwconfig wlan1 | grep -E "(Mode|Channel)" || echo "[WARN] Could not verify monitor mode"

# Build and start firewall
echo "[*] Building and starting Rust firewall..."
if [ ! -f "firewall/target/release/widrsx-backend" ]; then
    (cd firewall && cargo build --release)
fi
(cd firewall && ./target/release/widrsx-backend &) 2>&1 | tee firewall.log &
FIREWALL_PID=$!
echo "[*] Firewall started with PID: $FIREWALL_PID"

# Wait a moment for firewall to start
sleep 2

# Setup Access Point
echo "[*] Setting up Access Point on wlan2..."
python3 ap_setup.py 2>&1 | tee ap_setup.log
if [ $? -ne 0 ]; then
    echo "[ERROR] AP setup failed!"
    exit 1
fi

# Setup Tor
echo "[*] Setting up Tor routing..."
python3 tor_setup.py 2>&1 | tee tor_setup.log
if [ $? -ne 0 ]; then
    echo "[ERROR] Tor setup failed!"
    exit 1
fi

# Setup bandwidth management
echo "[*] Setting up bandwidth management..."
python3 bandwidth_setup.py 2>&1 | tee bandwidth_setup.log
if [ $? -ne 0 ]; then
    echo "[ERROR] Bandwidth setup failed!"
    exit 1
fi

# Initialize database
echo "[*] Initializing database..."
python3 -c "from database import init_db; init_db()" 2>&1 | tee db_init.log
if [ $? -ne 0 ]; then
    echo "[ERROR] Database initialization failed!"
    exit 1
fi

# Start Tor monitor
echo "[*] Starting Tor circuit monitor..."
python3 tor_monitor.py 2>&1 | tee tor_monitor.log &
TOR_MONITOR_PID=$!
echo "[*] Tor monitor started with PID: $TOR_MONITOR_PID"

# Start WiFi sniffer
echo "[*] Starting WiFi intrusion detection..."
sudo python3 main.py 2>&1 | tee wids.log &
WIDS_PID=$!
echo "[*] WIDS started with PID: $WIDS_PID"

# Start API server
echo "[*] Starting API server..."
python3 api_server.py 2>&1 | tee api_server.log &
API_PID=$!
echo "[*] API server started with PID: $API_PID"

echo "[*] ==========================================="
echo "[*] Secure WiFi Gateway System Started!"
echo "[*] ==========================================="
echo "[*] Access Point SSID: SecureAP"
echo "[*] API Dashboard: http://localhost:5000/dashboard.html"
echo "[*] API Endpoints: http://localhost:5000"
echo "[*] Log files: *.log in current directory"
echo "[*] PIDs: Firewall($FIREWALL_PID), TorMonitor($TOR_MONITOR_PID), WIDS($WIDS_PID), API($API_PID)"
echo "[*] Press Ctrl+C to stop all services"
echo "[*] ==========================================="

# Wait for all background processes
wait