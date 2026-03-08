#!/usr/bin/env python3
import subprocess
import yaml
import logging
import time
from structured_logger import tor_logger

logging.basicConfig(level=logging.INFO)

try:
    with open("config.yaml") as f:
        config = yaml.safe_load(f)
except Exception as e:
    logging.error(f"Failed to load config.yaml: {e}")
    exit(1)

AP_INTERFACE = config.get('ap_interface')
INTERNET_INTERFACE = config.get('internet_interface')
TOR_CONTROL_PORT = config.get('tor_control_port', 9051)
TOR_SOCKS_PORT = config.get('tor_socks_port', 9050)
TOR_TRANSPARENT_PORT = config.get('tor_transparent_port', 9040)

def run_command(cmd, check=True):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if check and result.returncode != 0:
            logging.error(f"Command failed: {cmd}")
            logging.error(f"Error: {result.stderr}")
            return False
        return True
    except Exception as e:
        logging.error(f"Exception running command: {e}")
        return False

def create_tor_config():
    config_content = f"""
SocksPort {TOR_SOCKS_PORT}
ControlPort {TOR_CONTROL_PORT}
CookieAuthentication 1
ExitPolicy reject *:*
TransPort {TOR_TRANSPARENT_PORT}
DNSPort 5353
AutomapHostsOnResolve 1
"""
    with open('/tmp/torrc', 'w') as f:
        f.write(config_content)
    logging.info("Created Tor config")
    tor_logger.info("tor_config_created", {
        "socks_port": TOR_SOCKS_PORT,
        "control_port": TOR_CONTROL_PORT,
        "transparent_port": TOR_TRANSPARENT_PORT,
        "dns_port": 5353,
        "exit_policy": "reject_all"
    })

def start_tor():
    logging.info("Starting Tor...")
    run_command("sudo tor -f /tmp/torrc &")
    time.sleep(10)  # Wait for Tor to start
    tor_logger.info("tor_service_started", {
        "config_file": "/tmp/torrc",
        "control_port": TOR_CONTROL_PORT
    })

def setup_transparent_proxy():
    logging.info("Setting up transparent proxy...")
    tor_logger.info("transparent_proxy_setup_started", {
        "ap_interface": AP_INTERFACE,
        "internet_interface": INTERNET_INTERFACE
    })
    
    # Redirect DNS to Tor
    run_command(f"sudo iptables -t nat -A PREROUTING -i {AP_INTERFACE} -p udp --dport 53 -j REDIRECT --to-ports 5353")
    # Redirect TCP traffic to Tor
    run_command(f"sudo iptables -t nat -A PREROUTING -i {AP_INTERFACE} -p tcp --syn -j REDIRECT --to-ports {TOR_TRANSPARENT_PORT}")
    # Allow Tor traffic to internet
    run_command(f"sudo iptables -A OUTPUT -m owner --uid-owner tor -j ACCEPT")
    run_command(f"sudo iptables -A OUTPUT -o lo -j ACCEPT")
    run_command(f"sudo iptables -t nat -A OUTPUT -m owner --uid-owner tor -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports {TOR_SOCKS_PORT}")
    
    tor_logger.info("transparent_proxy_rules_applied", {
        "dns_redirect_port": 5353,
        "tcp_redirect_port": TOR_TRANSPARENT_PORT,
        "socks_redirect_port": TOR_SOCKS_PORT
    })

if __name__ == "__main__":
    tor_logger.info("tor_setup_started", {
        "ap_interface": AP_INTERFACE,
        "internet_interface": INTERNET_INTERFACE
    })
    create_tor_config()
    start_tor()
    setup_transparent_proxy()
    tor_logger.info("tor_setup_completed", {"status": "success"})
    logging.info("Tor setup complete")