# WiFi Security Gateway (Vajra v1.0)

A comprehensive wireless security monitoring and intrusion detection system built with Python, Rust, and Tor integration. This system provides real-time WiFi attack detection, automated firewall blocking, and Tor circuit monitoring capabilities.

## 🚀 Features

### Core Security Features
- **Real-time WIDS (Wireless Intrusion Detection System)** - Monitors wireless networks for attacks
- **Automated Firewall Blocking** - Rust-based backend for high-performance MAC address blocking
- **Tor Circuit Monitoring** - Tracks and analyzes Tor network usage
- **Attack Logging & Analytics** - SQLite database for storing attack patterns and device information

### Network Components
- **Access Point Mode** - Optional secure WiFi hotspot (hardware-dependent)
- **Monitor Mode** - Passive wireless packet sniffing and analysis
- **API Server** - RESTful API for system monitoring and control
- **Tor Integration** - Anonymous networking with circuit monitoring

### Monitoring & Analytics
- **Live Attack Detection** - Real-time identification of wireless attacks
- **Device Tracking** - Connected device monitoring and bandwidth analysis
- **Network Usage Statistics** - Traffic monitoring and throttling capabilities
- **Structured Logging** - JSON-based logging for all system events

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Server    │    │   WIDS Engine   │    │  Tor Monitor    │
│   (Flask)       │    │   (Scapy)       │    │   (Stem)        │
│   Port: 5000    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Firewall Backend│
                    │   (Rust)        │
                    │   Port: 9000    │
                    └─────────────────┘
                             │
                    ┌─────────────────┐
                    │   SQLite DB     │
                    │ (Attack logs,   │
                    │  Tor circuits,  │
                    │  Devices)       │
                    └─────────────────┘
```

## 📋 Requirements

### Hardware Requirements
- **Wireless Interfaces**: At least 1 wireless adapter (2 recommended for AP + Monitor)
- **Monitor Mode Support**: Wireless card must support monitor mode
- **RAM**: Minimum 2GB (4GB recommended)
- **Storage**: 500MB free space

### Software Requirements
- **Operating System**: Kali Linux (recommended) or Debian-based Linux
- **Python**: 3.8+ with pip
- **Rust**: Latest stable version
- **System Packages**:
  - `hostapd`
  - `dnsmasq`
  - `iw`
  - `wireless-tools`

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd Vajra-v1.0/Shakti-main
```

### 2. Install Dependencies
```bash
# Install system packages
sudo apt update
sudo apt install hostapd dnsmasq iw wireless-tools

# Install Python dependencies
pip3 install -r requirements.txt

# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Build Rust firewall backend
cd firewall
cargo build --release
cd ..
```

### 3. Configure System
```bash
# Edit configuration
nano config.yaml

# Set wireless interfaces (change wlan0/wlan1 to your actual interfaces)
# wlan1: monitor mode interface
# wlan2: AP mode interface (optional)
```

### 4. Start the System
```bash
# Full system startup (recommended)
sudo bash start_all.sh

# Or start individual components
sudo bash start_and_monitor.sh  # Interactive monitoring mode
```

### 5. Access the System
- **API Server**: http://localhost:5000
- **Firewall Backend**: http://localhost:9000
- ** Control**: localhost:9051
- ** SOCKS**: localhost:9050

## 📖 API Documentation

### Core Endpoints

#### System Status
```bash
GET /system-status
```
Returns system health, running services, and resource usage.

#### Attack Logs
```bash
GET /logs
GET /logs?limit=50
```
Returns recent attack detections with filtering options.

#### Connected Devices
```bash
GET /devices
```
Lists all connected wireless devices with signal strength and bandwidth usage.

#### Tor Circuits
```bash
GET /tor-circuits
```
Returns active Tor circuits with entry/middle/exit node information.

#### Network Usage
```bash
GET /network-usage
```
Shows bandwidth usage statistics and throttling status.

### Firewall Control
```bash
POST /block/{mac_address}
```
Blocks a MAC address using the firewall backend.

## 🔧 Configuration

### config.yaml
```yaml
interface: wlan1              # Monitor mode interface
ap_interface: wlan2           # AP mode interface (optional)
internet_interface: eth0      # Internet uplink
log_path: logs/wifi_attack_logs.db
scan_interval: 2
block_method: nftables
firewall_host: 127.0.0.1
firewall_port: 9000
socket_timeout: 5
api_port: 5000
debug: false
log_level: INFO

# Access Point settings
ssid: SecureAP
wpa_passphrase: mysecurepassword
channel: 6

# DHCP settings
dhcp_range: 192.168.1.10,192.168.1.100,255.255.255.0,24h
```

### Environment Variables
```bash
SKIP_AP=1    # Skip AP mode if hardware doesn't support it
```

## 🎯 Usage Examples

### Monitor Wireless Attacks
```bash
# Start monitoring
sudo bash start_all.sh

# View live attacks
tail -f logs/wids_engine.log

# Check recent attacks via API
curl http://localhost:5000/logs | jq
```

### Tor Circuit Analysis
```bash
# View active Tor circuits
curl http://localhost:5000/tor-circuits | jq

# Monitor Tor logs
tail -f logs/tor_monitor.log
```

### Device Management
```bash
# List connected devices
curl http://localhost:5000/devices | jq

# Block a malicious device
curl -X POST http://localhost:5000/block/AA:BB:CC:DD:EE:FF
```

### System Monitoring
```bash
# System status
curl http://localhost:5000/system-status | jq

# Network usage
curl http://localhost:5000/network-usage | jq
```

## 🛠️ Development

### Project Structure
```
Shakti-main/
├── api_server.py          # Flask REST API
├── main.py                 # WIDS engine (Scapy)
├── tor_monitor.py          # Tor circuit monitor
├── database.py             # SQLite database operations
├── config.yaml             # System configuration
├── requirements.txt        # Python dependencies
├── start_all.sh           # Full system startup
├── start_and_monitor.sh   # Interactive monitoring
├── kill_all.sh           # Service cleanup
├── firewall/              # Rust firewall backend
│   ├── Cargo.toml
│   └── src/main.rs
├── logs/                  # Log files and database
└── structured_logger.py   # JSON logging system
```

### Adding New Attack Detections
1. Edit `main.py` to add new detection logic
2. Update `database.py` for new log types
3. Add API endpoints in `api_server.py`

### Extending the API
```python
@app.route("/custom-endpoint")
def custom_function():
    # Your custom logic here
    return jsonify({"status": "success"})
```

## 🔍 Troubleshooting

### Common Issues

#### "hostapd failed to start"
- Hardware may not support AP mode
- Set `SKIP_AP=1` environment variable
- Check wireless interface capabilities: `iw list`

#### "API server failed to start"
- Missing Python dependencies: `pip3 install -r requirements.txt`
- Port 5000 already in use: `sudo lsof -i :5000`
- Permission issues with database

#### "Tor monitor authentication failed"
- Tor service not running: `sudo systemctl start tor`
- Incorrect control password in config
- Check Tor logs: `journalctl -u tor`

#### "Network is down" errors
- Wireless interface not in monitor mode
- Check interface status: `iwconfig`
- Ensure proper permissions: run with `sudo`

### Logs and Debugging
```bash
# View all logs
tail -f logs/*.log

# Check system status
curl http://localhost:5000/system-status

# Database inspection
sqlite3 logs/wifi_attack_logs.db ".tables"
sqlite3 logs/wifi_attack_logs.db "SELECT * FROM logs LIMIT 5;"
```

## 📊 Attack Types Detected

- **Deauthentication Attacks** - Unauthorized disconnect attempts
- **Probe Requests** - Network scanning activities
- **Evil Twin APs** - Rogue access point detection
- **WPA Handshake Captures** - Authentication monitoring
- **Beacon Floods** - Spam beacon frame attacks
- **Association Floods** - Connection exhaustion attacks

## 🔒 Security Considerations

- **Run as root**: Required for wireless interface control and firewall operations
- **Firewall Rules**: System modifies iptables/nftables - review before production use
- **Network Isolation**: Consider running in isolated network segments
- **Log Security**: Attack logs may contain sensitive network information
- **Tor Usage**: Monitor Tor circuit usage for anonymity requirements

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and test thoroughly
4. Submit a pull request with detailed description

### Development Guidelines
- Follow PEP 8 for Python code
- Add docstrings to new functions
- Update README for new features
- Test on multiple wireless hardware configurations

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This tool is for educational and authorized security testing purposes only. Users are responsible for complying with applicable laws and regulations. Unauthorized use of this software may violate local laws regarding wireless network monitoring and security testing.

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review logs in the `logs/` directory
3. Open an issue with system information and error logs

---

---

**Built with ❤️ for wireless security research and education**
