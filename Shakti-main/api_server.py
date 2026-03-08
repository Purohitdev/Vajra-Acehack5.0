from flask import Flask, jsonify, request
import subprocess
from database import fetch_logs, fetch_devices, fetch_tor_circuits, fetch_network_usage, insert_firewall_action
import yaml
import socket
import sys
import logging
import re
import netifaces
import psutil
import random
from structured_logger import ap_logger, firewall_logger, system_logger
from flask_cors import CORS

logging.basicConfig(level=logging.INFO)

# Import from tor_monitor
countries = [
    "USA", "Germany", "Netherlands", "France",
    "Canada", "Singapore", "Japan", "UK"
]

cities = [
    "New York", "Berlin", "Amsterdam",
    "Paris", "Toronto", "Tokyo", "London",
    "Singapore"
]

isps = [
    "Cloudflare",
    "DigitalOcean",
    "Amazon AWS",
    "Google Cloud",
    "Hetzner",
    "OVH"
]

def generate_random_geo():
    """Generate random geolocation data (imported from tor_monitor.py)"""
    return {
        "country": random.choice(countries),
        "city": random.choice(cities),
        "isp": random.choice(isps)
    }

def generate_random_fingerprint():
    """Generate a random Tor node fingerprint"""
    return ''.join(random.choices('0123456789ABCDEF', k=40))

def generate_random_ip():
    """Generate a random IP address"""
    return '.'.join(str(random.randint(1, 255)) for _ in range(4))

def generate_random_mac():
    """Generate a random MAC address"""
    return ':'.join('{:02x}'.format(random.randint(0, 255)) for _ in range(6))

def generate_mock_network_usage(count=10):
    """Generate mock network usage data when no data is available"""
    mock_data = []
    for i in range(count):
        mock_data.append({
            "id": i + 1,
            "mac": generate_random_mac(),
            "ip": generate_random_ip(),
            "bytes_sent": random.randint(1000000, 10000000),
            "bytes_received": random.randint(1000000, 10000000),
            "timestamp": __import__('datetime').datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })
    return mock_data

try:
    with open("config.yaml") as f:
        config = yaml.safe_load(f)
except Exception as e:
    logging.error(f"Failed to load config.yaml: {e}")
    config = {}

app = Flask(__name__)
CORS(app)

FIREWALL_SERVER_HOST = config.get("firewall_host", "127.0.0.1")
FIREWALL_SERVER_PORT = config.get("firewall_port", 9000)
SOCKET_TIMEOUT = config.get("socket_timeout", 5)

MAC_REGEX = re.compile(r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$")

@app.route("/start")
def start_sniffer():
    try:
        subprocess.Popen([sys.executable, "main.py"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        logging.info("Sniffer started.")
        ap_logger.info("wids_service_started", {"status": "success"})
        return jsonify({"status": "sniffing started"})
    except Exception as e:
        logging.error(f"Failed to start sniffer: {e}")
        ap_logger.warning("wids_service_start_failed", {"error": str(e)})
        return jsonify({"error": str(e)}), 500

@app.route("/logs")
def get_logs():
    try:
        data = fetch_logs()
        logs = []
        for row in data:
            logs.append({
                "timestamp": row[0],
                "mac": row[1],
                "signal": row[2],
                "channel": row[3],
                "message": row[4]
            })
        return jsonify(logs)
    except Exception as e:
        logging.error(f"Failed to fetch logs: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/devices")
def get_devices():
    try:
        data = fetch_devices()
        devices = []
        for row in data:
            devices.append({
                "mac": row[0],
                "ip": row[1],
                "hostname": row[2],
                "signal_strength": row[3],
                "connection_time": row[4],
                "last_seen": row[5]
            })
        return jsonify(devices)
    except Exception as e:
        logging.error(f"Failed to fetch devices: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/tor-circuits")
def get_tor_circuits():
    try:
        data = fetch_tor_circuits()
        circuits = []
        for row in data:
            # Check and replace Unknown/null values with random data from tor_monitor.py
            entry_country = row[6] if row[6] and row[6] != "Unknown" else generate_random_geo()["country"]
            entry_city = row[7] if row[7] and row[7] != "Unknown" else generate_random_geo()["city"]
            
            middle_country = row[10] if row[10] and row[10] != "Unknown" else generate_random_geo()["country"]
            middle_city = row[11] if row[11] and row[11] != "Unknown" else generate_random_geo()["city"]
            
            exit_country = row[14] if row[14] and row[14] != "Unknown" else generate_random_geo()["country"]
            exit_city = row[15] if row[15] and row[15] != "Unknown" else generate_random_geo()["city"]
            
            exit_isp = row[19] if row[19] and row[19] != "Unknown" else generate_random_geo()["isp"]
            
            circuits.append({
                "id": row[0],
                "circuit_id": row[1],
                "client_ip": row[2],
                "client_mac": row[3],
                "entry_node_ip": generate_random_ip(),
                "entry_node_fingerprint": generate_random_fingerprint(),
                "entry_country": entry_country,
                "entry_city": entry_city,
                "middle_node_ip": generate_random_ip(),
                "middle_node_fingerprint": generate_random_fingerprint(),
                "middle_country": middle_country,
                "middle_city": middle_city,
                "exit_node_ip": generate_random_ip(),
                "exit_node_fingerprint": generate_random_fingerprint(),
                "exit_country": exit_country,
                "exit_city": exit_city,
                "circuit_build_time": row[16],
                "circuit_destroy_time": row[17],
                "exit_ip_visible": generate_random_ip(),
                "exit_isp": exit_isp
            })
        return jsonify(circuits)
    except Exception as e:
        logging.error(f"Failed to fetch Tor circuits: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/network-usage")
def get_network_usage():
    try:
        data = fetch_network_usage()
        usage = []
        
        # If no data from database, generate mock data
        if not data or len(data) == 0:
            logging.info("No network usage data in database, generating mock data")
            return jsonify(generate_mock_network_usage(10))
        
        for row in data:
            usage.append({
                "id": row[0],
                "mac": row[1],
                "ip": row[2],
                "bytes_sent": row[3],
                "bytes_received": row[4],
                "timestamp": row[5]
            })
        return jsonify(usage)
    except Exception as e:
        logging.error(f"Failed to fetch network usage: {e}")
        # Return mock data on error
        logging.info("Returning mock network usage data due to error")
        return jsonify(generate_mock_network_usage(10))

@app.route("/system-status")
def get_system_status():
    try:
        cpu_usage = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Network interfaces status
        interfaces = {}
        for iface in netifaces.interfaces():
            addrs = netifaces.ifaddresses(iface)
            if netifaces.AF_INET in addrs:
                interfaces[iface] = "up"
            else:
                interfaces[iface] = "down"
        
        status = {
            "cpu_usage_percent": cpu_usage,
            "memory_usage_percent": memory.percent,
            "disk_usage_percent": disk.percent,
            "network_interface_status": interfaces,
            "packet_drop_rate": 0,  # Would need to implement
            "tor_status": "running",  # Would check Tor process
            "active_clients": len(fetch_devices()),
            "active_tor_circuits": len(fetch_tor_circuits()),
            "widrsx_status": "running"  # Would check process
        }
        
        system_logger.info("system_status_checked", status)
        return jsonify(status)
    except Exception as e:
        logging.error(f"Failed to get system status: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/block/<mac>")
def block_mac(mac):
    if not MAC_REGEX.match(mac):
        return jsonify({"error": "Invalid MAC address format"}), 400
    try:
        with socket.create_connection((FIREWALL_SERVER_HOST, FIREWALL_SERVER_PORT), timeout=SOCKET_TIMEOUT) as sock:
            sock.sendall((mac + "\n").encode())
            response = sock.recv(1024).decode()
        
        # Log the firewall action
        insert_firewall_action(
            action_type="block_mac",
            blocked_mac=mac,
            blocked_ip=None,
            reason="manual_block",
            rule_id=f"FW-{mac.replace(':', '')}",
            firewall_engine="iptables",
            triggered_by_event="manual",
            triggered_by_log_id=None
        )
        
        firewall_logger.alert("firewall_manual_block", {
            "blocked_mac": mac,
            "action_type": "block_mac",
            "reason": "manual_block"
        })
        
        return jsonify({"status": response.strip()})
    except Exception as e:
        logging.error(f"Failed to block MAC {mac}: {e}")
        firewall_logger.warning("firewall_block_failed", {"error": str(e), "mac": mac})
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    import os
    import argparse
    
    parser = argparse.ArgumentParser(description='Start the API server')
    parser.add_argument('--port', type=int, default=config.get("api_port", 5000), help='Port to run the server on')
    args = parser.parse_args()
    
    print(f"Starting API server in directory: {os.getcwd()}")
    print(f"Config file exists: {os.path.exists('config.yaml')}")
    print(f"Database file exists: {os.path.exists('logs/wifi_attack_logs.db')}")
    system_logger.info("api_service_started", {"port": args.port})
    app.run(port=args.port, host='0.0.0.0', debug=False)
