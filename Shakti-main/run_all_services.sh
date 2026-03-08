
# Secure WiFi Gateway - Complete Service Launcher (Non-interactive)
# Runs all components concurrently with real-time logging

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

MAIN_LOG="$LOG_DIR/system_startup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}========================================${NC}" | tee -a "$MAIN_LOG"
echo -e "${BLUE}Secure WiFi Gateway - Service Launcher${NC}" | tee -a "$MAIN_LOG"
echo -e "${BLUE}========================================${NC}" | tee -a "$MAIN_LOG"
echo "Start Time: $TIMESTAMP" | tee -a "$MAIN_LOG"
echo "" | tee -a "$MAIN_LOG"

# PID file for cleanup
PID_FILE="$LOG_DIR/service_pids.txt"
> "$PID_FILE"

# Trap to kill all background processes on exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}" | tee -a "$MAIN_LOG"
    
    # Kill firewall backend
    if pgrep -f "widrsx-backend" > /dev/null; then
        echo "Stopping firewall backend..." | tee -a "$MAIN_LOG"
        pkill -f "widrsx-backend" || true
    fi
    
    # Kill dnsmasq and hostapd
    if pgrep dnsmasq > /dev/null; then
        echo "Stopping dnsmasq..." | tee -a "$MAIN_LOG"
        sudo pkill -9 dnsmasq || true
    fi
    
    if pgrep hostapd > /dev/null; then
        echo "Stopping hostapd..." | tee -a "$MAIN_LOG"
        sudo pkill -9 hostapd || true
    fi
    
    # Kill Python services
    while IFS= read -r pid; do
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "Killing process $pid..." | tee -a "$MAIN_LOG"
            kill -9 "$pid" 2>/dev/null || true
        fi
    done < "$PID_FILE"
    
    echo -e "${YELLOW}All services stopped${NC}" | tee -a "$MAIN_LOG"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Function to run a service and log output
run_service() {
    local name=$1
    local cmd=$2
    local log_file="$LOG_DIR/${name}.log"
    
    echo -e "${BLUE}Starting $name...${NC}" | tee -a "$MAIN_LOG"
    
    # Run in background with tee for real-time logging
    eval "$cmd" > >(tee -a "$log_file" | sed "s/^/[${name}] /") 2>&1 &
    local pid=$!
    echo "$pid" >> "$PID_FILE"
    
    echo "  PID: $pid" | tee -a "$MAIN_LOG"
    echo "  Log: $log_file" | tee -a "$MAIN_LOG"
}

# Pre-startup checks
echo -e "${BLUE}Pre-startup checks...${NC}" | tee -a "$MAIN_LOG"

# Check interfaces
echo -e "Checking interfaces..." | tee -a "$MAIN_LOG"
iwconfig wlan1 > /dev/null 2>&1 && echo -e "  ${GREEN}✓ wlan1 found${NC}" | tee -a "$MAIN_LOG" || echo -e "  ${RED}✗ wlan1 NOT found${NC}" | tee -a "$MAIN_LOG"
iwconfig wlan2 > /dev/null 2>&1 && echo -e "  ${GREEN}✓ wlan2 found${NC}" | tee -a "$MAIN_LOG" || echo -e "  ${RED}✗ wlan2 NOT found${NC}" | tee -a "$MAIN_LOG"

# Check if wlan1 is in monitor mode
WLAN1_MODE=$(iwconfig wlan1 2>/dev/null | grep "Mode:" | awk '{print $NF}' | cut -d: -f2)
if [ "$WLAN1_MODE" = "Monitor" ]; then
    echo -e "  ${GREEN}✓ wlan1 in Monitor mode${NC}" | tee -a "$MAIN_LOG"
else
    echo -e "  ${YELLOW}Setting wlan1 to monitor mode...${NC}" | tee -a "$MAIN_LOG"
    sudo ip link set wlan1 down
    sudo iw wlan1 set type monitor
    sudo ip link set wlan1 up
    sleep 2
    echo -e "  ${GREEN}✓ wlan1 now in Monitor mode${NC}" | tee -a "$MAIN_LOG"
fi

# Check if wlan2 is in AP mode
WLAN2_MODE=$(iwconfig wlan2 2>/dev/null | grep "Mode:" | awk '{print $NF}' | cut -d: -f2)
if [ "$WLAN2_MODE" = "Master" ]; then
    echo -e "  ${GREEN}✓ wlan2 in AP mode${NC}" | tee -a "$MAIN_LOG"
else
    echo -e "  ${YELLOW}Setting wlan2 to AP mode...${NC}" | tee -a "$MAIN_LOG"
    sudo ip link set wlan2 down
    sudo iw wlan2 set type __ap
    sudo ip link set wlan2 up
    sleep 2
    echo -e "  ${GREEN}✓ wlan2 now in AP mode${NC}" | tee -a "$MAIN_LOG"
fi

echo "" | tee -a "$MAIN_LOG"

# Kill any existing processes
echo -e "${BLUE}Cleaning up existing processes...${NC}" | tee -a "$MAIN_LOG"
sudo pkill -f hostapd || true
pkill -f dnsmasq || true
pkill -f "python3.*main.py" || true
pkill -f "python3.*api_server.py" || true
pkill -f "python3.*tor_monitor.py" || true
pkill -f "widrsx-backend" || true

sleep 2

echo "" | tee -a "$MAIN_LOG"

# Start services in order (with dependencies first)

# 1. Start Firewall Backend
echo -e "${BLUE}=== Starting Firewall Backend ===${NC}" | tee -a "$MAIN_LOG"
run_service "firewall" "cd firewall && ./target/release/widrsx-backend"
sleep 2

# 2. Setup and start AP (hostapd + dnsmasq)
echo -e "${BLUE}=== Setting up Access Point ===${NC}" | tee -a "$MAIN_LOG"
# Run AP setup but don't wait for it to block
python3 << 'PYEOF' > >(tee -a "$LOG_DIR/ap_setup.log") 2>&1 &
import subprocess
import yaml
import logging
import os
from structured_logger import ap_logger

logging.basicConfig(level=logging.INFO)

try:
    with open("config.yaml") as f:
        config = yaml.safe_load(f)
except Exception as e:
    logging.error(f"Failed to load config.yaml: {e}")
    exit(1)

AP_INTERFACE = config.get('ap_interface')
INTERNET_INTERFACE = config.get('internet_interface')
SSID = config.get('ssid')
WPA_PASSPHRASE = config.get('wpa_passphrase')
CHANNEL = config.get('channel')
DHCP_RANGE = config.get('dhcp_range')

def run_command(cmd, check=False):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0 and check:
            logging.error(f"Command failed: {cmd}")
            logging.error(f"Error: {result.stderr}")
        return result
    except Exception as e:
        logging.error(f"Exception: {e}")
        return None

# Setup interfaces
logging.info("Configuring AP interface...")
run_command(f"sudo ip link set {AP_INTERFACE} down")
run_command(f"sudo ip addr flush dev {AP_INTERFACE}")
run_command(f"sudo ip link set {AP_INTERFACE} up")
run_command(f"sudo ip addr add 192.168.1.1/24 dev {AP_INTERFACE}")

ap_logger.info("ap_interface_configured", {"interface": AP_INTERFACE, "ip": "192.168.1.1"})

# Create configs
hostapd_config = f"""
interface={AP_INTERFACE}
driver=nl80211
ssid={SSID}
hw_mode=g
channel={CHANNEL}
wpa=2
wpa_passphrase={WPA_PASSPHRASE}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
auth_algs=1
macaddr_acl=0
"""

with open('/tmp/hostapd.conf', 'w') as f:
    f.write(hostapd_config)

dnsmasq_config = f"""
interface={AP_INTERFACE}
dhcp-range={DHCP_RANGE}
dhcp-option=3,192.168.1.1
dhcp-option=6,8.8.8.8,8.8.4.4
no-daemon
log-queries
log-facility=/dev/stdout
"""

with open('/tmp/dnsmasq.conf', 'w') as f:
    f.write(dnsmasq_config)

ap_logger.info("configs_created", {"hostapd": "/tmp/hostapd.conf", "dnsmasq": "/tmp/dnsmasq.conf"})

# Enable IP forwarding
logging.info("Enabling IP forwarding...")
run_command("sudo sysctl -w net.ipv4.ip_forward=1")
run_command(f"sudo iptables -t nat -A POSTROUTING -o {INTERNET_INTERFACE} -j MASQUERADE")
run_command(f"sudo iptables -A FORWARD -i {AP_INTERFACE} -o {INTERNET_INTERFACE} -j ACCEPT")
run_command(f"sudo iptables -A FORWARD -i {INTERNET_INTERFACE} -o {AP_INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT")

ap_logger.info("forwarding_enabled", {"internet_interface": INTERNET_INTERFACE})

# Start services in background without waiting
logging.info("Starting dnsmasq...")
subprocess.Popen(f"sudo dnsmasq -C /tmp/dnsmasq.conf", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

logging.info("Starting hostapd...")
subprocess.Popen(f"sudo hostapd /tmp/hostapd.conf", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

ap_logger.info("ap_services_started", {"status": "success"})
logging.info("AP services started successfully")

PYEOF
AP_PID=$!
echo "$AP_PID" >> "$PID_FILE"
sleep 3

# 3. Start Tor
echo -e "${BLUE}=== Starting Tor ===${NC}" | tee -a "$MAIN_LOG"
if ! pgrep tor > /dev/null; then
    run_service "tor" "sudo tor"
    sleep 3
fi

# 4. Start WIDS Engine (Packet Sniffer)
echo -e "${BLUE}=== Starting WIDS Engine ===${NC}" | tee -a "$MAIN_LOG"
run_service "wids_engine" "sudo python3 main.py"

# 5. Start Tor Monitor
echo -e "${BLUE}=== Starting Tor Circuit Monitor ===${NC}" | tee -a "$MAIN_LOG"
run_service "tor_monitor" "python3 tor_monitor.py"

# 6. Start API Server
echo -e "${BLUE}=== Starting API Server ===${NC}" | tee -a "$MAIN_LOG"
run_service "api_server" "python3 api_server.py"

echo "" | tee -a "$MAIN_LOG"
echo -e "${GREEN}========================================${NC}" | tee -a "$MAIN_LOG"
echo -e "${GREEN}All services started successfully!${NC}" | tee -a "$MAIN_LOG"
echo -e "${GREEN}========================================${NC}" | tee -a "$MAIN_LOG"
echo "" | tee -a "$MAIN_LOG"
echo -e "${BLUE}Service Status:${NC}" | tee -a "$MAIN_LOG"
echo "  Firewall:     http://127.0.0.1:9000" | tee -a "$MAIN_LOG"
echo "  AP:           SecureAP @ 192.168.1.1" | tee -a "$MAIN_LOG"
echo "  API Server:   http://127.0.0.1:5000" | tee -a "$MAIN_LOG"
echo "  Tor Control:  127.0.0.1:9051" | tee -a "$MAIN_LOG"
echo "  Tor SOCKS:    127.0.0.1:9050" | tee -a "$MAIN_LOG"
echo "" | tee -a "$MAIN_LOG"
echo -e "${BLUE}Log Files:${NC}" | tee -a "$MAIN_LOG"
ls -lh "$LOG_DIR"/*.log 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}' | tee -a "$MAIN_LOG"
echo "" | tee -a "$MAIN_LOG"
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}" | tee -a "$MAIN_LOG"
echo "" | tee -a "$MAIN_LOG"

# Keep script running and monitor logs
while true; do
    sleep 1
    # Check if critical services are still running
    if ! pgrep -f "widrsx-backend" > /dev/null 2>&1; then
        echo -e "${RED}[$(date '+%H:%M:%S')] Firewall backend crashed!${NC}" | tee -a "$MAIN_LOG"
    fi
done
