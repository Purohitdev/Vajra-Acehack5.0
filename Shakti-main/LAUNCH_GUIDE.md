# Secure WiFi Gateway System - Setup & Running Guide

## System Overview

The Secure WiFi Gateway is a comprehensive wireless intrusion detection and threat response system with the following components:

- **WIDS Engine**: Monitors WiFi traffic for attacks (deauthentication, beacon floods, probe request floods)
- **Access Point**: Provides SecureAP network at 192.168.1.1
- **Firewall**: Rust-based backend for MAC blocking and rate limiting
- **Tor Integration**: Routes traffic through Tor network with circuit monitoring
- **API Server**: RESTful interface for remote management and queries
- **Structured Logging**: JSON-based logging for all events

## Quick Start

### One-Command Full System Launch

```bash
cd /home/bhairavam/Vajra-v1.0/Shakti-main
./launch.sh
```

This will start ALL services simultaneously:
1. Firewall Backend (port 9000)
2. Access Point (SecureAP @ 192.168.1.1)
3. WIDS Engine (real-time monitoring)
4. Tor Monitor (circuit tracking)
5. API Server (port 5000)

### Expected Output

```
======================================
Secure WiFi Gateway - Service Launcher
======================================
Start Time: 2026-03-07 19:40:00

Cleaning up...
====== Starting Services ======

[19:40:01] Starting firewall...
  PID: 1234 | Log: logs/firewall.log
[19:40:02] Starting ap_setup...
  PID: 1235 | Log: logs/ap_setup.log
[19:40:03] Starting wids_engine...
  PID: 1236 | Log: logs/wids_engine.log
[19:40:04] Starting tor_monitor...
  PID: 1237 | Log: logs/tor_monitor.log
[19:40:05] Starting api_server...
  PID: 1238 | Log: logs/api_server.log

====== Services Running ======

Total services: 5
Firewall:   http://127.0.0.1:9000
API:        http://127.0.0.1:5000
AP:         SecureAP @ 192.168.1.1
Tor SOCKS:  127.0.0.1:9050
```

## Real-Time Monitoring

### View Live WIDS Alerts

```bash
tail -f logs/wids_engine.log
```

You'll see colored output like:
```
[BEACON] BSSID: aa:bb:cc:dd:ee:ff | SSID: SecureAP | Channel: 6 | Signal: -45
[AUTH] Device: 11:22:33:44:55:66 | Channel: 6 | Signal: -60
[ATTACK-DEAUTH] Attacker: xx:xx:xx:xx:xx:xx | Target: yy:yy:yy:yy:yy:yy | Channel: 6
```

### View Device Connections

```bash
tail -f logs/ap_setup.log
```

Shows hostapd/dnsmasq activity and DHCP assignments.

### View API Activity

```bash
tail -f logs/api_server.log
```

### View System Startup

```bash
tail -f logs/firewall.log
```

## API Endpoints

The system provides a REST API on port 5000:

### Get Detected Attacks

```bash
curl http://127.0.0.1:5000/api/attacks
```

Response:
```json
{
  "attacks": [
    {
      "attack_type": "deauthentication",
      "attacker_mac": "aa:bb:cc:dd:ee:ff",
      "target_mac": "11:22:33:44:55:66",
      "timestamp": "2026-03-07T19:40:00",
      "severity": "high"
    }
  ]
}
```

### Get Connected Devices

```bash
curl http://127.0.0.1:5000/api/devices
```

### Block a Device

```bash
curl -X POST http://127.0.0.1:5000/api/block \
  -H "Content-Type: application/json" \
  -d '{"mac": "aa:bb:cc:dd:ee:ff"}'
```

### Get Tor Circuit Info

```bash
curl http://127.0.0.1:5000/api/tor/circuits
```

## Database Access

The system uses SQLite for data storage. Access it with:

```bash
sqlite3 logs/wifi_attack_logs.db
```

### Available Tables

```sql
-- View all tables
.tables

-- Check attacks
SELECT * FROM logs LIMIT 10;

-- Check connected devices
SELECT * FROM devices;

-- Check Tor circuits
SELECT * FROM tor_circuits;

-- Check network usage
SELECT * FROM network_usage;

-- Check firewall blocks
SELECT * FROM firewall_actions;
```

## Configuration

Edit `config.yaml` to customize:

```yaml
# Network Interfaces
interface: wlan1               # Monitor mode interface
ap_interface: wlan2            # AP interface
internet_interface: eth0       # Uplink interface

# AP Settings
ssid: SecureAP
wpa_passphrase: mysecurepassword
channel: 6
dhcp_range: 192.168.1.10,192.168.1.100,255.255.255.0,24h

# Services
api_port: 5000
firewall_port: 9000

# Tor
tor_control_port: 9051
tor_socks_port: 9050
tor_transparent_port: 9040

# Bandwidth Limits (kbps)
default_download_limit: 1000
default_upload_limit: 500

# Logging
log_level: INFO  # DEBUG, INFO, WARNING, ERROR
```

## Testing the System

### 1. Connect a Device to SecureAP

From another machine:
```bash
# Connect to the WiFi network
# SSID: SecureAP
# Password: mysecurepassword

# Check assigned IP
ifconfig  # Should be 192.168.1.x
```

### 2. Monitor Real-Time Activity

```bash
tail -f logs/wids_engine.log
```

### 3. Simulate a WiFi Attack

```bash
# Deauthentication attack (in another terminal)
sudo aireplay-ng --deauth 0 -a aa:bb:cc:dd:ee:ff -c 11:22:33:44:55:66 wlan0
```

You should see immediate alerts in the WIDS log:
```
[ATTACK-DEAUTH] Attacker: xx:xx:xx:xx:xx:xx | Target: yy:yy:yy:yy:yy:yy | Channel: 6
```

### 4. Check API for Detected Attacks

```bash
curl http://127.0.0.1:5000/api/attacks | python3 -m json.tool
```

## Stopping the System

Press `Ctrl+C` in the terminal running `./launch.sh`

All services will be gracefully shut down:
```
^C
Stopping all services...
All services stopped
```

## Troubleshooting

### WIDS not showing attacks

Check if wlan1 is in monitor mode:
```bash
iwconfig wlan1
# Should show: Mode:Monitor
```

If not, set it manually:
```bash
sudo ip link set wlan1 down
sudo iw wlan1 set type monitor
sudo ip link set wlan1 up
```

### Devices not connecting to AP

Check hostapd status:
```bash
sudo systemctl status hostapd
# Or check logs
sudo tail -f /var/log/hostapd.log
```

Check DHCP:
```bash
sudo systemctl status dnsmasq
sudo tail -f /var/log/dnsmasq.log
```

### Tor not working

Ensure Tor service is running:
```bash
sudo systemctl status tor
```

Check Tor control port:
```bash
telnet 127.0.0.1 9051
```

### API not responding

Check if API server started:
```bash
ps aux | grep "api_server.py"
```

Test connectivity:
```bash
curl http://127.0.0.1:5000/api/health
```

## Log Files Location

All logs are stored in the `logs/` directory:

```
logs/
├── firewall.log          # Firewall backend logs
├── ap_setup.log          # Access Point setup
├── wids_engine.log       # WIDS detection alerts (REAL-TIME)
├── tor_monitor.log       # Tor circuit monitoring
├── api_server.log        # API server activity
├── system_monitor.jsonl  # JSON Lines format logs
├── wids_engine.jsonl     # Structured WIDS logs
└── wifi_attack_logs.db   # SQLite database
```

## Performance Tips

1. **Monitor logs in separate terminal**:
   ```bash
   # Terminal 1: Start system
   ./launch.sh
   
   # Terminal 2: Monitor WIDS
   tail -f logs/wids_engine.log
   ```

2. **Use grep to filter logs**:
   ```bash
   tail -f logs/wids_engine.log | grep "ATTACK"
   ```

3. **Monitor specific events**:
   ```bash
   tail -f logs/wids_engine.log | grep -E "(BEACON|AUTH|ATTACK)"
   ```

## Production Deployment

For production use:

1. Change AP password in `config.yaml`:
   ```yaml
   wpa_passphrase: your_strong_password_here
   ```

2. Enable HTTPS API:
   ```python
   # In api_server.py
   app.run(ssl_context='adhoc', ...)
   ```

3. Set up log rotation:
   ```bash
   # In launch.sh
   logrotate -f /etc/logrotate.d/wifi_gateway
   ```

4. Use systemd service for auto-restart:
   ```bash
   sudo cp launch.sh /usr/local/bin/wifi-gateway
   # Create systemd unit file
   ```

## System Requirements

- **OS**: Linux (Kali/Ubuntu tested)
- **WiFi Adapters**: 2 (one for monitoring, one for AP)
- **Python**: 3.6+
- **Dependencies**: Flask, Scapy, Stem, PyYAML
- **Network Tools**: hostapd, dnsmasq, Tor, iptables
- **Rust**: For firewall compilation (pre-built binary included)

## Support

For issues:

1. Check logs in `logs/` directory
2. Verify interface modes: `iwconfig wlan1 wlan2`
3. Test API: `curl http://127.0.0.1:5000/api/health`
4. Check processes: `ps aux | grep python3`

---

**System Status**: All components ready for simultaneous execution
**Last Updated**: 2026-03-07
