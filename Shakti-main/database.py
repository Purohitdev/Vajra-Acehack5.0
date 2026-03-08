import sqlite3
from datetime import datetime
import os
import logging
from structured_logger import system_logger

DB_DIR = "logs"
DB_PATH = os.path.join(DB_DIR, "wifi_attack_logs.db")

logging.basicConfig(level=logging.INFO)

def ensure_db_dir():
    if not os.path.exists(DB_DIR):
        os.makedirs(DB_DIR)
        logging.info(f"Created directory: {DB_DIR}")
        system_logger.info("database_directory_created", {"directory": DB_DIR})

def init_db():
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            # Existing logs table
            c.execute('''
                CREATE TABLE IF NOT EXISTS logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT,
                    mac TEXT,
                    signal TEXT,
                    channel TEXT,
                    message TEXT
                )
            ''')
            # Connected devices
            c.execute('''
                CREATE TABLE IF NOT EXISTS devices (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    mac TEXT UNIQUE,
                    ip TEXT,
                    hostname TEXT,
                    signal_strength TEXT,
                    connection_time TEXT,
                    last_seen TEXT,
                    bandwidth_limit_down TEXT,
                    bandwidth_limit_up TEXT,
                    data_uploaded_bytes INTEGER DEFAULT 0,
                    data_downloaded_bytes INTEGER DEFAULT 0,
                    packets_uploaded INTEGER DEFAULT 0,
                    packets_downloaded INTEGER DEFAULT 0,
                    latency_ms INTEGER DEFAULT 0
                )
            ''')
            # Tor circuits
            c.execute('''
                CREATE TABLE IF NOT EXISTS tor_circuits (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    circuit_id TEXT,
                    client_ip TEXT,
                    client_mac TEXT,
                    entry_node_ip TEXT,
                    entry_node_fingerprint TEXT,
                    entry_country TEXT,
                    entry_city TEXT,
                    middle_node_ip TEXT,
                    middle_node_fingerprint TEXT,
                    middle_country TEXT,
                    middle_city TEXT,
                    exit_node_ip TEXT,
                    exit_node_fingerprint TEXT,
                    exit_country TEXT,
                    exit_city TEXT,
                    circuit_build_time TEXT,
                    circuit_destroy_time TEXT,
                    exit_ip_visible TEXT,
                    exit_isp TEXT
                )
            ''')
            # Network usage
            c.execute('''
                CREATE TABLE IF NOT EXISTS network_usage (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    client_mac TEXT,
                    client_ip TEXT,
                    bytes_uploaded INTEGER,
                    bytes_downloaded INTEGER,
                    current_upload_speed REAL,
                    current_download_speed REAL,
                    peak_upload_speed REAL,
                    peak_download_speed REAL,
                    total_session_usage INTEGER,
                    traffic_class TEXT,
                    throttled INTEGER DEFAULT 0,
                    throttle_reason TEXT,
                    timestamp TEXT
                )
            ''')
            # Firewall actions
            c.execute('''
                CREATE TABLE IF NOT EXISTS firewall_actions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    action_type TEXT,
                    blocked_mac TEXT,
                    blocked_ip TEXT,
                    reason TEXT,
                    rule_id TEXT,
                    firewall_engine TEXT,
                    block_start_time TEXT,
                    block_expiration TEXT,
                    triggered_by_event TEXT,
                    triggered_by_log_id TEXT
                )
            ''')
            conn.commit()
        logging.info("Database initialized.")
        system_logger.info("database_initialized", {"tables_created": 5})
    except Exception as e:
        logging.error(f"Failed to initialize database: {e}")
        system_logger.critical("database_initialization_failed", {"error": str(e)})

def insert_log(mac, signal, channel, message):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            c.execute("INSERT INTO logs (timestamp, mac, signal, channel, message) VALUES (?, ?, ?, ?, ?)",
                      (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), mac, signal, channel, message))
            conn.commit()
        logging.info(f"Inserted log for MAC: {mac}")
        system_logger.info("attack_log_inserted", {
            "attacker_mac": mac,
            "signal_strength_dbm": signal,
            "channel": channel,
            "attack_type": message
        })
    except Exception as e:
        logging.error(f"Failed to insert log: {e}")
        system_logger.warning("attack_log_insertion_failed", {"error": str(e), "mac": mac})

def insert_device(mac, ip, hostname, signal_strength):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            c.execute('''
                INSERT OR REPLACE INTO devices (mac, ip, hostname, signal_strength, connection_time, last_seen)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (mac, ip, hostname, signal_strength, now, now))
            conn.commit()
        logging.info(f"Inserted/Updated device: {mac}")
        system_logger.info("device_connected", {
            "client_mac": mac,
            "client_ip": ip,
            "hostname": hostname,
            "signal_strength_dbm": signal_strength,
            "connection_start_time": now
        })
    except Exception as e:
        logging.error(f"Failed to insert device: {e}")
        system_logger.warning("device_insertion_failed", {"error": str(e), "mac": mac})

def update_device_last_seen(mac):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            c.execute("UPDATE devices SET last_seen = ? WHERE mac = ?", (now, mac))
            conn.commit()
    except Exception as e:
        logging.error(f"Failed to update device last seen: {e}")

def insert_tor_circuit(circuit_id, entry_ip, entry_country, entry_city, middle_ip, middle_country, middle_city, exit_ip, exit_country, exit_city):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            c.execute('''
                INSERT INTO tor_circuits (circuit_id, entry_node_ip, entry_country, entry_city, middle_node_ip, middle_country, middle_city, exit_node_ip, exit_country, exit_city, circuit_build_time)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (circuit_id, entry_ip, entry_country, entry_city, middle_ip, middle_country, middle_city, exit_ip, exit_country, exit_city, now))
            conn.commit()
        logging.info(f"Inserted Tor circuit: {circuit_id}")
        system_logger.info("tor_circuit_created", {
            "tor_circuit_id": circuit_id,
            "entry_node_ip": entry_ip,
            "entry_country": entry_country,
            "entry_city": entry_city,
            "middle_node_ip": middle_ip,
            "middle_country": middle_country,
            "middle_city": middle_city,
            "exit_node_ip": exit_ip,
            "exit_country": exit_country,
            "exit_city": exit_city,
            "circuit_build_time": now
        })
    except Exception as e:
        logging.error(f"Failed to insert Tor circuit: {e}")
        system_logger.warning("tor_circuit_insertion_failed", {"error": str(e), "circuit_id": circuit_id})

def insert_network_usage(mac, ip, bytes_sent, bytes_received):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            c.execute('''
                INSERT INTO network_usage (client_mac, client_ip, bytes_uploaded, bytes_downloaded, timestamp)
                VALUES (?, ?, ?, ?, ?)
            ''', (mac, ip, bytes_sent, bytes_received, now))
            conn.commit()
        system_logger.info("bandwidth_usage_logged", {
            "client_mac": mac,
            "client_ip": ip,
            "bytes_uploaded": bytes_sent,
            "bytes_downloaded": bytes_received
        })
    except Exception as e:
        logging.error(f"Failed to insert network usage: {e}")
        system_logger.warning("bandwidth_usage_log_failed", {"error": str(e), "mac": mac})

def insert_firewall_action(action_type, blocked_mac, blocked_ip, reason, rule_id, firewall_engine, triggered_by_event, triggered_by_log_id):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            c.execute('''
                INSERT INTO firewall_actions (action_type, blocked_mac, blocked_ip, reason, rule_id, firewall_engine, block_start_time, triggered_by_event, triggered_by_log_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (action_type, blocked_mac, blocked_ip, reason, rule_id, firewall_engine, now, triggered_by_event, triggered_by_log_id))
            conn.commit()
        system_logger.alert("firewall_action_taken", {
            "action_type": action_type,
            "blocked_mac": blocked_mac,
            "blocked_ip": blocked_ip,
            "reason": reason,
            "rule_id": rule_id,
            "firewall_engine": firewall_engine,
            "block_start_time": now,
            "triggered_by_event": triggered_by_event,
            "triggered_by_log_id": triggered_by_log_id
        })
    except Exception as e:
        logging.error(f"Failed to insert firewall action: {e}")
        system_logger.critical("firewall_action_log_failed", {"error": str(e), "blocked_mac": blocked_mac})

def fetch_logs(limit=50):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            c.execute("SELECT timestamp, mac, signal, channel, message FROM logs ORDER BY id DESC LIMIT ?", (limit,))
            rows = c.fetchall()
        return rows
    except Exception as e:
        logging.error(f"Failed to fetch logs: {e}")
        return []

def fetch_devices():
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            c.execute("SELECT mac, ip, hostname, signal_strength, connection_time, last_seen FROM devices")
            rows = c.fetchall()
        return rows
    except Exception as e:
        logging.error(f"Failed to fetch devices: {e}")
        return []

def fetch_tor_circuits(limit=10):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            c.execute("SELECT * FROM tor_circuits ORDER BY id DESC LIMIT ?", (limit,))
            rows = c.fetchall()
        return rows
    except Exception as e:
        logging.error(f"Failed to fetch Tor circuits: {e}")
        return []

def fetch_network_usage(limit=100):
    ensure_db_dir()
    try:
        with sqlite3.connect(DB_PATH) as conn:
            c = conn.cursor()
            c.execute("SELECT * FROM network_usage ORDER BY id DESC LIMIT ?", (limit,))
            rows = c.fetchall()
        return rows
    except Exception as e:
        logging.error(f"Failed to fetch network usage: {e}")
        return []
