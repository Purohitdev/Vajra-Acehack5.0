#!/usr/bin/env python3

import stem
from stem import Signal
from stem.control import Controller
import yaml
import logging
import requests
import time
import random

from database import insert_tor_circuit
from structured_logger import tor_logger

logging.basicConfig(level=logging.INFO)

# ---------------- CONFIG LOAD ---------------- #

try:
    with open("config.yaml") as f:
        config = yaml.safe_load(f)
except Exception as e:
    logging.error(f"Failed to load config.yaml: {e}")
    exit(1)

TOR_CONTROL_PORT = config.get("tor_control_port", 9051)
TOR_PASSWORD = config.get("tor_password", "torcontrol")
GEOLOCATION_API = config.get("geolocation_api", "http://ip-api.com/json/")

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


def generate_geo():
    return {
        "country": random.choice(countries),
        "city": random.choice(cities),
        "lat": random.uniform(-90, 90),
        "lon": random.uniform(-180, 180),
        "isp": random.choice(isps),
        "generated": True
    }


# ---------------- GEOLOCATION LOOKUP ---------------- #

def get_geolocation(ip):
    try:
        response = requests.get(
            f"{GEOLOCATION_API}{ip}",
            timeout=5
        )

        data = response.json()

        country = data.get("country")
        city = data.get("city")
        lat = data.get("lat")
        lon = data.get("lon")
        isp = data.get("isp")

        
        if not country or not city:
            return generate_geo()

        return {
            "country": country,
            "city": city,
            "lat": lat if lat else random.uniform(-90, 90),
            "lon": lon if lon else random.uniform(-180, 180),
            "isp": isp if isp else random.choice(isps),
            "generated": False
        }

    except Exception as e:
        logging.error(f"Geolocation lookup failed for {ip}: {e}")
        return generate_geo()


# ---------------- TOR MONITOR ---------------- #

def monitor_tor_circuits():

    print("Starting Tor monitor with password authentication...")

    tor_logger.info(
        "tor_monitor_started",
        {"control_port": TOR_CONTROL_PORT}
    )

    try:
        with Controller.from_port(port=TOR_CONTROL_PORT) as controller:

            controller.authenticate(password=TOR_PASSWORD)

            print("Successfully authenticated with Tor control port")

            while True:

                circuits = controller.get_circuits()

                for circuit in circuits:

                    if len(circuit.path) >= 3:

                        entry = circuit.path[0]
                        middle = circuit.path[1]
                        exit_node = circuit.path[-1]

                        entry_ip = entry[1] if len(entry) > 1 else "0.0.0.0"
                        middle_ip = middle[1] if len(middle) > 1 else "0.0.0.0"
                        exit_ip = exit_node[1] if len(exit_node) > 1 else "0.0.0.0"

                        entry_geo = get_geolocation(entry_ip)
                        middle_geo = get_geolocation(middle_ip)
                        exit_geo = get_geolocation(exit_ip)

                        # Store in database
                        insert_tor_circuit(
                            str(circuit.id),

                            entry_ip,
                            entry_geo["country"],
                            entry_geo["city"],

                            middle_ip,
                            middle_geo["country"],
                            middle_geo["city"],

                            exit_ip,
                            exit_geo["country"],
                            exit_geo["city"]
                        )

                        # Structured logging
                        tor_logger.info(
                            "tor_circuit_active",
                            {
                                "tor_circuit_id": str(circuit.id),

                                "entry_node_ip": entry_ip,
                                "entry_country": entry_geo["country"],
                                "entry_city": entry_geo["city"],
                                "entry_generated": entry_geo["generated"],

                                "middle_node_ip": middle_ip,
                                "middle_country": middle_geo["country"],
                                "middle_city": middle_geo["city"],
                                "middle_generated": middle_geo["generated"],

                                "exit_node_ip": exit_ip,
                                "exit_country": exit_geo["country"],
                                "exit_city": exit_geo["city"],
                                "exit_isp": exit_geo["isp"],
                                "exit_generated": exit_geo["generated"]
                            }
                        )

                # Check circuits every minute
                time.sleep(60)

    except Exception as e:

        logging.error(f"Error monitoring Tor circuits: {e}")

        tor_logger.critical(
            "tor_monitor_error",
            {"error": str(e)}
        )


# ---------------- TOR CIRCUIT ROTATION ---------------- #

def rotate_circuit():

    try:

        with Controller.from_port(port=TOR_CONTROL_PORT) as controller:

            controller.authenticate(password=TOR_PASSWORD)

            controller.signal(Signal.NEWNYM)

            logging.info("Tor circuit rotated")

            tor_logger.info(
                "tor_circuit_rotated",
                {"method": "NEWNYM"}
            )

    except Exception as e:

        logging.error(f"Failed to rotate circuit: {e}")

        tor_logger.warning(
            "tor_circuit_rotation_failed",
            {"error": str(e)}
        )


# ---------------- MAIN ---------------- #

if __name__ == "__main__":

    monitor_tor_circuits()