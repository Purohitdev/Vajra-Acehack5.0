#!/bin/bash

# Debug script for Secure WiFi Gateway System
# Checks all components and provides diagnostic information

echo "=========================================="
echo "Secure WiFi Gateway - Debug Report"
echo "=========================================="
echo "Date: $(date)"
echo "System: $(uname -a)"
echo ""

# Check Python version
echo "Python Version:"
python3 --version
echo ""

# Check if required packages are installed
echo "Checking required system packages:"
PACKAGES=("hostapd" "dnsmasq" "tor" "iptables" "iproute2")
for pkg in "${PACKAGES[@]}"; do
    if command -v $pkg &> /dev/null; then
        echo "✓ $pkg - $(which $pkg)"
    else
        echo "✗ $pkg - NOT FOUND"
    fi
done
echo ""

# Check network interfaces
echo "Network Interfaces:"
ip link show | grep -E "(wlan|eth)"
echo ""

# Check WiFi interfaces specifically
echo "WiFi Interfaces:"
for iface in wlan0 wlan1 wlan2; do
    if iwconfig $iface &>/dev/null; then
        echo "✓ $iface found:"
        iwconfig $iface | grep -E "(Mode|Channel|ESSID)"
    else
        echo "✗ $iface not found or not wireless"
    fi
done
echo ""

# Check Python modules
echo "Checking Python modules:"
MODULES=("flask" "scapy" "pyyaml" "stem" "requests" "netifaces" "psutil")
for module in "${MODULES[@]}"; do
    if python3 -c "import $module" &>/dev/null; then
        echo "✓ $module"
    else
        echo "✗ $module - NOT FOUND"
    fi
done
echo ""

# Check Rust/Cargo
echo "Rust/Cargo status:"
if command -v cargo &> /dev/null; then
    echo "✓ Cargo found: $(cargo --version)"
    if [ -f "firewall/Cargo.toml" ]; then
        echo "✓ Firewall Cargo.toml exists"
        if [ -f "firewall/target/release/widrsx-backend" ]; then
            echo "✓ Firewall binary exists"
        else
            echo "✗ Firewall binary not built"
        fi
    else
        echo "✗ Firewall Cargo.toml not found"
    fi
else
    echo "✗ Cargo not found"
fi
echo ""

# Check configuration
echo "Configuration check:"
if [ -f "config.yaml" ]; then
    echo "✓ config.yaml exists"
    echo "Current config:"
    cat config.yaml
else
    echo "✗ config.yaml not found"
fi
echo ""

# Check database
echo "Database check:"
if [ -f "logs/wifi_attack_logs.db" ]; then
    echo "✓ Database exists"
    # Try to query database
    if python3 -c "import sqlite3; conn = sqlite3.connect('logs/wifi_attack_logs.db'); cursor = conn.cursor(); cursor.execute('SELECT name FROM sqlite_master WHERE type=\"table\"'); print('Tables:', [row[0] for row in cursor.fetchall()]); conn.close()" 2>/dev/null; then
        echo "✓ Database accessible"
    else
        echo "✗ Database access failed"
    fi
else
    echo "✗ Database not found"
fi
echo ""

# Check log files
echo "Log files:"
for log in *.log logs/*.jsonl; do
    if [ -f "$log" ]; then
        echo "✓ $log ($(wc -l < $log) lines)"
    fi
done
echo ""

# Test component imports
echo "Testing component imports:"
COMPONENTS=("structured_logger" "database" "main" "api_server" "ap_setup" "tor_setup" "bandwidth_setup" "tor_monitor")
for comp in "${COMPONENTS[@]}"; do
    if python3 -c "import $comp" &>/dev/null; then
        echo "✓ $comp.py imports successfully"
    else
        echo "✗ $comp.py import failed"
    fi
done
echo ""

# Check running processes
echo "Checking for running processes:"
PROCESSES=("widrsx-backend" "hostapd" "dnsmasq" "tor" "python3")
for proc in "${PROCESSES[@]}"; do
    if pgrep -f $proc &>/dev/null; then
        echo "✓ $proc running (PID: $(pgrep -f $proc))"
    else
        echo "✗ $proc not running"
    fi
done
echo ""

# Check network configuration
echo "Network configuration:"
echo "IPTables rules:"
sudo iptables -t nat -L -n | grep -E "(MASQUERADE|REDIRECT)" || echo "No NAT rules found"
echo ""
echo "IP routes:"
ip route show | head -5
echo ""

# Check Tor status
echo "Tor status:"
if systemctl is-active --quiet tor 2>/dev/null; then
    echo "✓ Tor service active"
elif pgrep tor &>/dev/null; then
    echo "✓ Tor process running"
else
    echo "✗ Tor not running"
fi
echo ""

echo "=========================================="
echo "Debug report complete"
echo "=========================================="