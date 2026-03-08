# Vajra v1.0 - Advanced Cybersecurity Platform

A comprehensive cybersecurity platform combining wireless network security, intrusion detection, and modern web interfaces for threat monitoring and management.

## 🛡️ Overview

Vajra v1.0 is an integrated cybersecurity solution featuring:

- **Wireless Security Gateway** - Real-time WiFi intrusion detection and automated threat response
- **Tor Network Integration** - Anonymous communication monitoring and circuit analysis
- **Modern Web Dashboard** - Intuitive interface for security monitoring and control
- **Multi-layered Defense** - Combining hardware-level blocking with software monitoring

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Vajra v1.0 Platform                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │   Frontend      │    │   Backend       │                 │
│  │   Dashboard     │    │   Security      │                 │
│  │   (React/TypeScript)│    │   Gateway       │                 │
│  │                 │    │   (Python/Rust) │                 │
│  └─────────────────┘    └─────────────────┘                 │
│           │                       │                        │
│           └───────────────────────┼────────────────────────┘
│                                   │
│                    ┌─────────────────┐
│                    │   Security      │
│                    │   Services      │
│                    │   (WIDS, Tor,   │
│                    │    Firewall)    │
│                    └─────────────────┘
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
Vajra-v1.0/
├── Shakti-main/              # Backend Security Gateway
│   ├── api_server.py        # Flask REST API
│   ├── main.py              # WIDS Engine (Scapy)
│   ├── tor_monitor.py       # Tor Circuit Monitor
│   ├── database.py          # SQLite Database Operations
│   ├── firewall/            # Rust Firewall Backend
│   ├── config.yaml          # System Configuration
│   ├── start_all.sh         # System Startup Script
│   └── README.md            # Gateway Documentation
│
├── acehack(1)/              # Frontend Dashboard
│   └── acehack/
│       ├── src/             # React Application Source
│       ├── public/          # Static Assets
│       ├── package.json     # Node Dependencies
│       ├── vite.config.ts   # Vite Configuration
│       └── README.md        # Frontend Documentation
│
└── .venv*/                  # Python Virtual Environments
```

## 🚀 Components

### 1. Shakti-main (Backend Security Gateway)

**Technologies**: Python 3.13+, Rust, Flask, Scapy, SQLite

**Features**:
- **Wireless Intrusion Detection System (WIDS)** - Real-time WiFi attack monitoring
- **Automated Firewall Blocking** - Rust-based MAC address blocking
- **Tor Circuit Monitoring** - Anonymous network usage analysis
- **RESTful API** - System monitoring and control endpoints
- **Structured Logging** - JSON-based security event logging

**Key Capabilities**:
- Deauthentication attack detection
- Evil twin AP identification
- Beacon flood monitoring
- Tor circuit geolocation
- Device bandwidth tracking

### 2. acehack (Frontend Dashboard)

**Technologies**: React 19, TypeScript, Vite, Three.js, Tailwind CSS

**Features**:
- **Modern UI/UX** - Responsive dashboard with animations
- **Real-time Monitoring** - Live security metrics and alerts
- **3D Visualizations** - Interactive network topology views
- **Threat Management** - Block/unblock device controls
- **Analytics Dashboard** - Security event analysis and reporting

**UI Libraries**:
- Framer Motion - Smooth animations and transitions
- Three.js/React Three Fiber - 3D network visualizations
- Tailwind CSS - Modern styling framework
- Lucide React - Beautiful icons

## 🛠️ Installation & Setup

### Prerequisites

**System Requirements**:
- Linux (Kali Linux recommended)
- Python 3.8+
- Node.js 18+
- Rust (latest stable)
- Wireless adapters (monitor mode capable)

**Hardware Requirements**:
- 2GB RAM minimum (4GB recommended)
- Wireless interface supporting monitor mode
- Internet connection for Tor integration

### Backend Setup (Shakti-main)

```bash
# Navigate to backend directory
cd Shakti-main

# Install system dependencies
sudo apt update
sudo apt install hostapd dnsmasq iw wireless-tools python3-pip

# Install Python dependencies
pip3 install -r requirements.txt

# Install Rust and build firewall
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
cd firewall && cargo build --release && cd ..

# Configure wireless interfaces
sudo nano config.yaml
# Set wlan1 for monitor mode, wlan2 for AP (optional)
```

### Frontend Setup (acehack)

```bash
# Navigate to frontend directory
cd acehack(1)/acehack

# Install dependencies
npm install
# or
pnpm install

# Start development server
npm run dev
# or
pnpm dev
```

## 🚀 Quick Start

### Full System Launch

```bash
# Start backend security services
cd Shakti-main
sudo bash start_all.sh

# In another terminal, start frontend
cd ../acehack(1)/acehack
npm run dev
```

### Access Points

- **Backend API**: http://localhost:5000
- **Frontend Dashboard**: http://localhost:5173 (Vite dev server)
- **Firewall Backend**: http://localhost:9000

## 📖 API Reference

### Backend Endpoints

#### System Monitoring
```bash
GET  /system-status     # Overall system health
GET  /logs             # Security events and alerts
GET  /devices          # Connected wireless devices
GET  /tor-circuits     # Active Tor circuits
GET  /network-usage    # Bandwidth statistics
```

#### Security Controls
```bash
POST /block/{mac}      # Block malicious device
```

#### Configuration
```bash
GET  /config           # Current system configuration
POST /config           # Update system settings
```

### Frontend Routes

- `/` - Main dashboard
- `/monitoring` - Real-time security monitoring
- `/devices` - Device management
- `/analytics` - Security analytics
- `/settings` - System configuration

## 🔧 Configuration

### Backend Configuration (config.yaml)

```yaml
# Wireless interfaces
interface: wlan1              # Monitor mode interface
ap_interface: wlan2           # AP mode interface (optional)

# Network settings
internet_interface: eth0      # Internet uplink
log_path: logs/wifi_attack_logs.db

# Security settings
scan_interval: 2              # Scan frequency (seconds)
block_method: nftables        # Firewall method

# API settings
api_port: 5000
firewall_host: 127.0.0.1
firewall_port: 9000

# Access Point (optional)
ssid: SecureAP
wpa_passphrase: yourpassword
channel: 6
```

### Environment Variables

```bash
SKIP_AP=1           # Skip AP mode if hardware doesn't support it
DEBUG=1             # Enable debug logging
```

## 🎯 Usage Examples

### Monitor Wireless Attacks

```bash
# Start monitoring
sudo bash start_all.sh

# View live security events
tail -f logs/wids_engine.log

# Check API for recent attacks
curl http://localhost:5000/logs | jq
```

### Tor Circuit Analysis

```bash
# View active circuits
curl http://localhost:5000/tor-circuits | jq

# Monitor Tor activity
tail -f logs/tor_monitor.log
```

### Device Management

```bash
# List connected devices
curl http://localhost:5000/devices | jq

# Block suspicious device
curl -X POST http://localhost:5000/block/AA:BB:CC:DD:EE:FF
```

### Frontend Development

```bash
# Start development server with hot reload
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🔍 Troubleshooting

### Common Backend Issues

#### "hostapd failed to start"
```bash
# Check wireless interface capabilities
iw list

# Skip AP mode for monitor-only hardware
export SKIP_AP=1
sudo bash start_all.sh
```

#### "API server failed to start"
```bash
# Install missing dependencies
pip3 install flask flask-cors

# Check port availability
sudo lsof -i :5000
```

#### "Tor authentication failed"
```bash
# Check Tor service status
sudo systemctl status tor

# Verify control port configuration
sudo nano /etc/tor/torrc
```

#### "Network interface not found"
```bash
# List available interfaces
iwconfig

# Update configuration with correct interface names
sudo nano config.yaml
```

### Common Frontend Issues

#### "Port 5173 already in use"
```bash
# Kill process using the port
sudo lsof -ti:5173 | xargs kill -9

# Or use a different port
npm run dev -- --port 3000
```

#### "Module not found" errors
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

## 📊 Security Features

### Wireless Security
- **Real-time Attack Detection** - Deauth, evil twin, beacon floods
- **Automated Response** - Immediate MAC address blocking
- **Signal Strength Monitoring** - Proximity-based threat assessment
- **Channel Hopping** - Multi-channel wireless surveillance

### Network Security
- **Tor Integration** - Anonymous communication monitoring
- **Circuit Analysis** - Entry/middle/exit node tracking
- **Traffic Shaping** - Bandwidth control and throttling
- **Device Fingerprinting** - MAC address and behavior analysis

### System Security
- **Structured Logging** - Comprehensive audit trails
- **API Authentication** - Secure endpoint access
- **Configuration Validation** - Input sanitization and validation
- **Process Isolation** - Separate service compartments

## 🔒 Security Considerations

### Operational Security
- **Root Privileges Required** - Wireless interface control needs sudo
- **Firewall Rule Management** - System modifies iptables/nftables
- **Network Isolation** - Consider dedicated security network segments
- **Log Security** - Attack logs contain sensitive network data

### Legal Compliance
- **Authorized Use Only** - Wireless monitoring requires proper authorization
- **Regulatory Compliance** - Adhere to local wireless communication laws
- **Data Privacy** - Handle captured data according to privacy regulations
- **Ethical Monitoring** - Use for defensive security purposes only

## 🤝 Development

### Backend Development

```bash
# Activate virtual environment
source .venv/bin/activate

# Run tests
python3 -m pytest

# Code formatting
black .
isort .

# Type checking
mypy .
```

### Frontend Development

```bash
# Code formatting
npm run lint

# Type checking
npx tsc --noEmit

# Build optimization
npm run build
```

### Adding New Features

#### Backend Extensions
1. Add detection logic to `main.py`
2. Update database schema in `database.py`
3. Add API endpoints in `api_server.py`
4. Update configuration in `config.yaml`

#### Frontend Extensions
1. Create components in `src/components/`
2. Add routes in `src/App.tsx`
3. Update API calls for new backend endpoints
4. Add styling with Tailwind CSS

## 📈 Performance Optimization

### Backend Optimization
- **Rust Firewall Backend** - High-performance packet filtering
- **Asynchronous Processing** - Non-blocking I/O operations
- **Database Indexing** - Optimized query performance
- **Memory Pooling** - Efficient resource management

### Frontend Optimization
- **Code Splitting** - Lazy-loaded components
- **Asset Optimization** - Compressed bundles and images
- **Caching Strategy** - Service worker implementation
- **Virtual Scrolling** - Large dataset handling

## 🧪 Testing

### Backend Testing
```bash
# Unit tests
python3 -m pytest tests/

# Integration tests
python3 -m pytest tests/integration/

# Performance testing
python3 -m pytest tests/performance/
```

### Frontend Testing
```bash
# Unit tests
npm run test

# E2E tests
npm run test:e2e

# Visual regression tests
npm run test:visual
```

## 📚 Documentation

### API Documentation
- **Swagger UI**: http://localhost:5000/docs (when running)
- **Postman Collection**: Available in `docs/` directory
- **OpenAPI Spec**: Generated from Flask endpoints

### User Guides
- **Installation Guide**: Step-by-step setup instructions
- **Configuration Guide**: Detailed configuration options
- **Troubleshooting Guide**: Common issues and solutions
- **API Reference**: Complete endpoint documentation

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Development Guidelines
- Follow PEP 8 for Python code
- Use TypeScript strict mode for frontend
- Write comprehensive tests
- Update documentation for new features
- Ensure cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see LICENSE files in respective directories.

## ⚠️ Disclaimer

This cybersecurity platform is designed for authorized security testing and defensive purposes only. Users are responsible for complying with applicable laws and regulations. Unauthorized use of wireless monitoring capabilities may violate local laws regarding network surveillance and security testing.

## 🙏 Acknowledgments

- **Scapy** - Network packet manipulation framework
- **Stem** - Tor control library
- **React Three Fiber** - 3D React renderer
- **Framer Motion** - Animation library
- **Tailwind CSS** - Utility-first CSS framework

---

**Built with ❤️ for advanced cybersecurity research and network defense**