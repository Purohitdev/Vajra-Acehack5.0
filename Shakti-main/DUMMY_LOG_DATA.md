# Dummy Log Data - Secure WiFi Gateway API Responses

## API Endpoints and Sample Data

### 1. `/logs` - Get Attack Logs
**Response Format:** JSON Array of detected wireless attacks

```json
[
  {
    "timestamp": "2026-03-07 19:52:34.122",
    "mac": "c0:74:ad:93:d5:e1",
    "signal": -39,
    "channel": 1,
    "message": "Beacon Flood Attack Detected - SSID: UEMJ_ACD_1, Rate: 11 packets/sec"
  },
  {
    "timestamp": "2026-03-07 19:52:35.456",
    "mac": "06:18:d6:0b:2e:fd",
    "signal": -57,
    "channel": 6,
    "message": "Deauthentication Attack - Target: UEMJ_ACD_1, Frames: 5"
  },
  {
    "timestamp": "2026-03-07 19:52:36.789",
    "mac": "a4:12:69:78:45:2c",
    "signal": -62,
    "channel": 11,
    "message": "Probe Request Flood - 23 requests from single source in 1 second"
  },
  {
    "timestamp": "2026-03-07 19:52:37.234",
    "mac": "c0:74:ad:93:d5:e1",
    "signal": -40,
    "channel": 1,
    "message": "Beacon Flood Attack Detected - SSID: UEMJ_ACD_1, Rate: 12 packets/sec"
  },
  {
    "timestamp": "2026-03-07 19:52:38.567",
    "mac": "f8:32:e4:92:15:7d",
    "signal": -48,
    "channel": 4,
    "message": "Authentication Attempt - Device: f8:32:e4:92:15:7d from -48 dBm"
  }
]
```

---

### 2. `/devices` - Get Connected Devices
**Response Format:** JSON Array of devices connected to the AP

```json
[
  {
    "mac": "a8:5e:60:12:34:56",
    "ip": "192.168.1.10",
    "hostname": "samsung-phone",
    "signal_strength": -45,
    "connection_time": "2026-03-07 19:50:10",
    "last_seen": "2026-03-07 19:52:45"
  },
  {
    "mac": "b4:6d:83:45:67:89",
    "ip": "192.168.1.11",
    "hostname": "iphone-user",
    "signal_strength": -52,
    "connection_time": "2026-03-07 19:51:20",
    "last_seen": "2026-03-07 19:52:43"
  },
  {
    "mac": "d0:22:be:78:90:cd",
    "ip": "192.168.1.12",
    "hostname": "laptop-work",
    "signal_strength": -38,
    "connection_time": "2026-03-07 19:45:30",
    "last_seen": "2026-03-07 19:52:48"
  },
  {
    "mac": "6c:41:6a:23:45:ef",
    "ip": "192.168.1.13",
    "hostname": "unknown-device",
    "signal_strength": -68,
    "connection_time": "2026-03-07 19:52:15",
    "last_seen": "2026-03-07 19:52:40"
  }
]
```

---

### 3. `/tor-circuits` - Get Tor Circuit Information
**Response Format:** JSON Array of active Tor circuits

```json
[
  {
    "id": 1,
    "circuit_id": "1e8f9a2b",
    "entry_ip": "185.220.101.45",
    "entry_country": "United States",
    "entry_city": "Los Angeles",
    "middle_ip": "193.23.244.244",
    "middle_country": "Netherlands",
    "middle_city": "Amsterdam",
    "exit_ip": "171.25.193.77",
    "exit_country": "Germany",
    "exit_city": "Berlin",
    "timestamp": "2026-03-07 19:50:22"
  },
  {
    "id": 2,
    "circuit_id": "3d5c1e9a",
    "entry_ip": "45.33.32.156",
    "entry_country": "United States",
    "entry_city": "New York",
    "middle_ip": "154.35.175.10",
    "middle_country": "France",
    "middle_city": "Paris",
    "exit_ip": "185.129.61.28",
    "exit_country": "Canada",
    "exit_city": "Toronto",
    "timestamp": "2026-03-07 19:51:45"
  },
  {
    "id": 3,
    "circuit_id": "7a2f4b8c",
    "entry_ip": "178.175.129.20",
    "entry_country": "Russia",
    "entry_city": "Moscow",
    "middle_ip": "212.102.49.9",
    "middle_country": "Sweden",
    "middle_city": "Stockholm",
    "exit_ip": "151.236.30.238",
    "exit_country": "Spain",
    "exit_city": "Madrid",
    "timestamp": "2026-03-07 19:52:10"
  }
]
```

---

### 4. `/network-usage` - Get Network Usage Statistics
**Response Format:** JSON Array of per-device network usage

```json
[
  {
    "id": 1,
    "mac": "a8:5e:60:12:34:56",
    "ip": "192.168.1.10",
    "bytes_sent": 5242880,
    "bytes_received": 15728640,
    "timestamp": "2026-03-07 19:52:48"
  },
  {
    "id": 2,
    "mac": "b4:6d:83:45:67:89",
    "ip": "192.168.1.11",
    "bytes_sent": 2097152,
    "bytes_received": 8388608,
    "timestamp": "2026-03-07 19:52:47"
  },
  {
    "id": 3,
    "mac": "d0:22:be:78:90:cd",
    "ip": "192.168.1.12",
    "bytes_sent": 10485760,
    "bytes_received": 31457280,
    "timestamp": "2026-03-07 19:52:49"
  },
  {
    "id": 4,
    "mac": "6c:41:6a:23:45:ef",
    "ip": "192.168.1.13",
    "bytes_sent": 1048576,
    "bytes_received": 3145728,
    "timestamp": "2026-03-07 19:52:46"
  }
]
```

---

### 5. `/system-status` - Get System Status
**Response Format:** JSON object with overall system health

```json
{
  "cpu_usage_percent": 23.5,
  "memory_usage_percent": 41.2,
  "disk_usage_percent": 34.8,
  "network_interface_status": {
    "lo": "up",
    "eth0": "up",
    "wlan1": "up",
    "wlan2": "up",
    "docker0": "down"
  },
  "packet_drop_rate": 0.2,
  "tor_status": "running",
  "active_clients": 4,
  "active_tor_circuits": 3,
  "widrsx_status": "running"
}
```

---

### 6. `/block/<mac>` - Block a Device MAC Address
**Example Request:** `GET /block/c0:74:ad:93:d5:e1`

**Success Response:**
```json
{
  "status": "MAC c0:74:ad:93:d5:e1 blocked successfully"
}
```

**Error Response:**
```json
{
  "error": "Invalid MAC address format"
}
```

---

## Structured Logger Output (Stored in Logs)

### Attack Detection Logs (from WIDS Engine)
```json
{
  "timestamp": "2026-03-07T19:52:34.122000",
  "logger": "wids_engine",
  "event_type": "wireless_attack_detected",
  "data": {
    "attack_type": "beacon_flood",
    "attacker_mac": "c0:74:ad:93:d5:e1",
    "ssid_targeted": "UEMJ_ACD_1",
    "channel": 1,
    "frequency": 2405,
    "signal_strength_dbm": -39,
    "frame_type": "management",
    "frame_subtype": "beacon",
    "packet_rate_per_second": 11,
    "detection_confidence": 0.9,
    "detected_by_sensor": "widrsx-engine",
    "sensor_interface": "wlan1"
  }
}
```

### Device Connection Logs (from AP Setup)
```json
{
  "timestamp": "2026-03-07T19:50:10.500000",
  "logger": "ap_controller",
  "event_type": "wireless_auth_attempt",
  "data": {
    "device_mac": "a8:5e:60:12:34:56",
    "signal_strength": -45,
    "channel": 6,
    "timestamp": 1772893354.1221576,
    "connection_status": "authenticated"
  }
}
```

### Firewall Action Logs
```json
{
  "timestamp": "2026-03-07T19:52:50.234000",
  "logger": "firewall_engine",
  "event_type": "firewall_manual_block",
  "data": {
    "blocked_mac": "c0:74:ad:93:d5:e1",
    "action_type": "block_mac",
    "reason": "manual_block",
    "firewall_engine": "iptables",
    "rule_id": "FW-C074AD93D5E1"
  }
}
```

### API Service Logs
```json
{
  "timestamp": "2026-03-07T19:52:33.194000",
  "logger": "system_monitor",
  "event_type": "api_service_started",
  "data": {
    "port": 5000,
    "status": "running"
  }
}
```

### System Status Logs
```json
{
  "timestamp": "2026-03-07T19:52:45.567000",
  "logger": "system_monitor",
  "event_type": "system_status_checked",
  "data": {
    "cpu_usage_percent": 23.5,
    "memory_usage_percent": 41.2,
    "disk_usage_percent": 34.8,
    "active_clients": 4,
    "active_tor_circuits": 3,
    "packet_drop_rate": 0.2
  }
}
```

---

## Sample API Request/Response Flow

### 1. Check System Status
```bash
curl http://localhost:5000/system-status
```
Response: 200 OK with system metrics

### 2. Get Connected Devices
```bash
curl http://localhost:5000/devices
```
Response: 200 OK with device list

### 3. Monitor Attack Logs
```bash
curl http://localhost:5000/logs
```
Response: 200 OK with recent attack logs

### 4. Check Network Usage
```bash
curl http://localhost:5000/network-usage
```
Response: 200 OK with bandwidth usage per device

### 5. View Tor Circuits
```bash
curl http://localhost:5000/tor-circuits
```
Response: 200 OK with active Tor circuits

### 6. Block a Malicious Device
```bash
curl http://localhost:5000/block/c0:74:ad:93:d5:e1
```
Response: 200 OK - MAC blocked

---

## Database Tables That Generate This Data

### `logs` Table
- Stores all wireless attack detections
- Indexed by timestamp and attack_type
- Includes signal strength, channel, and SSID info

### `devices` Table
- Tracks devices connected to AP
- Stores MAC, IP, hostname, signal strength
- Records connection and last seen times

### `tor_circuits` Table
- Tracks active Tor circuits
- Stores entry/middle/exit nodes with geolocation
- Updates timestamp on each circuit change

### `network_usage` Table
- Per-device bandwidth tracking
- Bytes sent and received
- Updated in real-time as devices use network

### `firewall_actions` Table
- Records all firewall blocks/rules
- Tracks blocked MACs and IPs
- Stores rule IDs and timestamps

