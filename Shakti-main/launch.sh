#!/bin/bash

# Secure WiFi Gateway - Unified Service Launcher
# Runs all components simultaneously with real-time monitoring

set +e  # Don't exit on error, handle gracefully

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

LOG_DIR="logs"
mkdir -p "$LOG_DIR"

echo "======================================"
echo "Secure WiFi Gateway - Service Launcher"
echo "======================================"
echo "Start Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Store PIDs
declare -a PIDS

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping all services..."
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid"
        fi
    done
    pkill -9 -f "python3.*main.py"
    pkill -9 -f "python3.*api_server.py"
    pkill -9 -f "python3.*tor_monitor.py"
    pkill -f "widrsx-backend"
    echo "All services stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Function to start a service
start_service() {
    local name=$1
    local cmd=$2
    local log_file="$LOG_DIR/${name}.log"
    
    echo "[$(date '+%H:%M:%S')] Starting $name..."
    eval "$cmd" > "$log_file" 2>&1 &
    local pid=$!
    PIDS+=($pid)
    echo "  PID: $pid | Log: $log_file"
}

# Kill existing processes
echo "Cleaning up..."
pkill -9 -f "python3.*main.py" 2>/dev/null
pkill -9 -f "python3.*api_server.py" 2>/dev/null
pkill -9 -f "python3.*tor_monitor.py" 2>/dev/null
pkill -f "widrsx-backend" 2>/dev/null
sleep 1

echo ""
echo "====== Starting Services ======"
echo ""

# 1. Firewall Backend
start_service "firewall" "cd firewall && ./target/release/widrsx-backend"
sleep 2

# 2. AP Setup
start_service "ap_setup" "python3 ap_setup.py"
sleep 2

# 3. WIDS Engine (with sudo)
start_service "wids_engine" "sudo python3 main.py"

# 4. Tor Monitor
start_service "tor_monitor" "python3 tor_monitor.py"

# 5. API Server
start_service "api_server" "python3 api_server.py"

echo ""
echo "====== Services Running ======"
echo ""
echo "Total services: ${#PIDS[@]}"
echo "Firewall:   http://127.0.0.1:9000"
echo "API:        http://127.0.0.1:5000"
echo "AP:         SecureAP @ 192.168.1.1"
echo "Tor SOCKS:  127.0.0.1:9050"
echo ""
echo "Real-time logs:"
echo "  Main: tail -f $LOG_DIR/firewall.log"
echo "  WIDS: tail -f $LOG_DIR/wids_engine.log"
echo "  AP:   tail -f $LOG_DIR/ap_setup.log"
echo "  API:  tail -f $LOG_DIR/api_server.log"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Monitor services
while true; do
    sleep 5
    # Check if any service died
    for i in "${!PIDS[@]}"; do
        if ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
            echo "[$(date '+%H:%M:%S')] WARNING: Service PID ${PIDS[$i]} died!"
        fi
    done
done
