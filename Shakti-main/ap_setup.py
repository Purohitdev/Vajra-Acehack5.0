#!/usr/bin/env python3
import subprocess
import yaml
import logging
import os
import time
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
WHITELISTED_PORTS = config.get('whitelisted_ports', [])

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

def setup_interfaces():
    logging.info("Setting up network interfaces...")
    ap_logger.info("ap_interface_setup_started", {"interface": AP_INTERFACE})
    # Bring up interfaces
    run_command(f"sudo ifconfig {AP_INTERFACE} up")
    run_command(f"sudo ifconfig {INTERNET_INTERFACE} up")

    # Assign IP to AP interface
    run_command(f"sudo ifconfig {AP_INTERFACE} 192.168.1.1 netmask 255.255.255.0")
    ap_logger.info("ap_interface_configured", {
        "interface": AP_INTERFACE,
        "ip": "192.168.1.1",
        "netmask": "255.255.255.0"
    })

def create_hostapd_config():
    config_content = f"""interface={AP_INTERFACE}
driver=nl80211
ssid={SSID}
hw_mode=g
channel={CHANNEL}
wpa=2
wpa_passphrase={WPA_PASSPHRASE}
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
auth_algs=1
macaddr_acl=0
ignore_broadcast_ssid=0
max_num_sta=100
"""
    # Use /tmp for temporary config (hostapd works fine here)
    conf_file = '/tmp/hostapd.conf'
    try:
        with open(conf_file, 'w') as f:
            f.write(config_content)
        os.chmod(conf_file, 0o644)
        logging.info(f"Created hostapd config at {conf_file}")
        ap_logger.info("hostapd_config_created", {
            "ssid": SSID,
            "channel": CHANNEL,
            "security": "WPA2",
            "config_file": conf_file
        })
        return conf_file
    except Exception as e:
        logging.error(f"Failed to create hostapd config: {e}")
        raise

def create_dnsmasq_config():
    config_content = f"""interface={AP_INTERFACE}
dhcp-range={DHCP_RANGE}
dhcp-option=3,192.168.1.1
dhcp-option=6,8.8.8.8,8.8.4.4
log-queries
log-dhcp
"""
    # Use /tmp for temporary config
    conf_file = '/tmp/dnsmasq.conf'
    try:
        with open(conf_file, 'w') as f:
            f.write(config_content)
        os.chmod(conf_file, 0o644)
        logging.info(f"Created dnsmasq config at {conf_file}")
        ap_logger.info("dnsmasq_config_created", {
            "dhcp_range": DHCP_RANGE,
            "gateway": "192.168.1.1",
            "dns_servers": "8.8.8.8,8.8.4.4",
            "config_file": conf_file
        })
        return conf_file
    except Exception as e:
        logging.error(f"Failed to create dnsmasq config: {e}")
        raise

def start_services(hostapd_conf_file, dnsmasq_conf_file):
    import subprocess
    import time
    logging.info("Starting dnsmasq...")
    # Start dnsmasq in background without blocking
    subprocess.Popen(f"sudo dnsmasq -C {dnsmasq_conf_file}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    ap_logger.info("dnsmasq_started", {"config_file": dnsmasq_conf_file})

    logging.info("Starting hostapd...")
    # Start hostapd in background without blocking
    subprocess.Popen(f"sudo hostapd {hostapd_conf_file}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    ap_logger.info("hostapd_started", {
        "config_file": hostapd_conf_file,
        "interface": AP_INTERFACE
    })
    time.sleep(2)  # Wait for services to initialize

def enable_ip_forwarding():
    logging.info("Enabling IP forwarding...")
    run_command("sudo sysctl -w net.ipv4.ip_forward=1")
    run_command(f"sudo iptables -t nat -A POSTROUTING -o {INTERNET_INTERFACE} -j MASQUERADE")
    run_command(f"sudo iptables -A FORWARD -i {AP_INTERFACE} -o {INTERNET_INTERFACE} -j ACCEPT")
    run_command(f"sudo iptables -A FORWARD -i {INTERNET_INTERFACE} -o {AP_INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT")
    ap_logger.info("ip_forwarding_enabled", {
        "internet_interface": INTERNET_INTERFACE,
        "ap_interface": AP_INTERFACE
    })

def whitelist_port(port):
    logging.info(f"Whitelisting port {port}...")
    # Using nftables to add rule for incoming TCP on port
    run_command(f"sudo nft add rule inet filter input tcp dport {port} accept")
    ap_logger.info("port_whitelisted", {"port": port})

def whitelist_ports(ports):
    for port in ports:
        whitelist_port(port)

if __name__ == "__main__":
    ap_logger.info("ap_setup_started", {
        "ap_interface": AP_INTERFACE,
        "internet_interface": INTERNET_INTERFACE,
        "ssid": SSID
    })
    setup_interfaces()
    hostapd_conf = create_hostapd_config()
    dnsmasq_conf = create_dnsmasq_config()
    enable_ip_forwarding()
    whitelist_ports(WHITELISTED_PORTS)
    start_services(hostapd_conf, dnsmasq_conf)
    ap_logger.info("ap_setup_completed", {"status": "success"})
    logging.info("Access Point setup complete")