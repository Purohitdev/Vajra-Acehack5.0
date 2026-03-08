#!/usr/bin/env python3
import subprocess
import yaml
import logging
from structured_logger import bandwidth_logger

logging.basicConfig(level=logging.INFO)

try:
    with open("config.yaml") as f:
        config = yaml.safe_load(f)
except Exception as e:
    logging.error(f"Failed to load config.yaml: {e}")
    exit(1)

AP_INTERFACE = config.get('ap_interface')
DEFAULT_DOWN = config.get('default_download_limit', 1000)
DEFAULT_UP = config.get('default_upload_limit', 500)

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

def setup_bandwidth_limits():
    logging.info("Setting up bandwidth limits...")
    bandwidth_logger.info("bandwidth_setup_started", {
        "interface": AP_INTERFACE,
        "default_download_limit": f"{DEFAULT_DOWN}kbit",
        "default_upload_limit": f"{DEFAULT_UP}kbit"
    })
    
    # Clear existing qdisc
    run_command(f"sudo tc qdisc del dev {AP_INTERFACE} root")

    # Add root qdisc
    run_command(f"sudo tc qdisc add dev {AP_INTERFACE} root handle 1: htb default 30")

    # Add root class
    run_command(f"sudo tc class add dev {AP_INTERFACE} parent 1:1 htb rate {DEFAULT_DOWN}kbit")

    # Add default class
    run_command(f"sudo tc class add dev {AP_INTERFACE} parent 1:1 classid 1:30 htb rate {DEFAULT_DOWN}kbit ceil {DEFAULT_DOWN}kbit")
    
    bandwidth_logger.info("bandwidth_limits_configured", {
        "interface": AP_INTERFACE,
        "default_class_rate": f"{DEFAULT_DOWN}kbit",
        "default_class_ceil": f"{DEFAULT_DOWN}kbit"
    })

def set_client_limit(ip, down_limit, up_limit):
    logging.info(f"Setting bandwidth limit for {ip}: down={down_limit}kbit, up={up_limit}kbit")
    bandwidth_logger.info("client_bandwidth_limit_set", {
        "client_ip": ip,
        "download_limit_kbit": down_limit,
        "upload_limit_kbit": up_limit
    })
    
    # For download (ingress)
    run_command(f"sudo tc class add dev {AP_INTERFACE} parent 1:1 classid 1:{ip.split('.')[-1]} htb rate {down_limit}kbit ceil {down_limit}kbit")
    run_command(f"sudo tc filter add dev {AP_INTERFACE} protocol ip parent 1:0 prio 1 u32 match ip dst {ip} flowid 1:{ip.split('.')[-1]}")

    # For upload (egress), need to do on internet interface
    # This is simplified; in practice, might need more complex setup

if __name__ == "__main__":
    setup_bandwidth_limits()
    bandwidth_logger.info("bandwidth_setup_completed", {"status": "success"})
    logging.info("Bandwidth management setup complete")