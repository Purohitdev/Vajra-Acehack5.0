# Manual Steps to Run Secure WiFi Gateway

## Issues & Solutions

### Issue 1: Hostapd PID Dies Immediately

**Why it happens:**
- Hostapd process dies because it can't bind to the interface properly
- Interface might not be in AP mode
- Config file syntax errors
- Permission issues with the wireless card

**Manual Steps:**

```bash
# Step 1: Stop any running services
sudo pkill -9 hostapd
sudo pkill -9 dnsmasq
sudo pkill -f "widrsx"
sudo pkill -f "python3"

# Step 2: Bring down the interface and reset it
sudo ip link set wlan2 down
sudo ip addr flush dev wlan2

# Step 3: Remove any existing connection
sudo nmcli dev set wlan2 managed no

# Step 4: Bring interface up in AP mode
sudo ip link set wlan2 up
sudo ip addr add 192.168.1.1/24 dev wlan2

# Step 5: Check your hostapd.conf location
# Your file is at: /home/bhairavam/Vajra-v1.0/Shakti-main/hostapd.conf
# Verify it has correct format (no extra spaces/tabs):
cat /home/bhairavam/Vajra-v1.0/Shakti-main/hostapd.conf

# Step 6: Start hostapd with verbose output to see errors
sudo hostapd -dd /home/bhairavam/Vajra-v1.0/Shakti-main/hostapd.conf

# The -dd flag will show debug output. If it fails, you'll see the exact error.
# Common errors:
#   - "Device or resource busy" = Another process using wlan2
#   - "No suitable channel" = Wireless card doesn't support that mode
#   - "Invalid argument" = Config syntax error
```

**If hostapd still fails, use this simplified config:**

```bash
# Create a minimal working config
sudo cat > /etc/hostapd/hostapd.conf << 'EOF'
interface=wlan2
driver=nl80211
ssid=PMF_TEST
hw_mode=g
channel=6
wpa=2
wpa_passphrase=StrongPassword123
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

# Start it
sudo hostapd -dd /etc/hostapd/hostapd.conf
```

---

### Issue 2: Mobile Device Connection Not Showing Logs

**Why it happens:**
- WIDS engine only monitors wlan1 (monitor mode), not wlan2 (AP mode)
- Device connections to AP are DHCP/Layer 2 events, not captured by packet sniffer
- API needs to be running to log device connections

**Manual Steps:**

```bash
# Step 1: In a NEW terminal, start the AP (from Step 6 above in another window)
sudo hostapd -dd /home/bhairavam/Vajra-v1.0/Shakti-main/hostapd.conf

# Step 2: In ANOTHER NEW terminal, start DNSMASQ
# First, create dnsmasq config
cat > /tmp/dnsmasq.conf << 'EOF'
interface=wlan2
dhcp-range=192.168.1.10,192.168.1.100,255.255.255.0,24h
dhcp-option=3,192.168.1.1
dhcp-option=6,8.8.8.8,8.8.4.4
EOF

# Start dnsmasq
sudo dnsmasq -C /tmp/dnsmasq.conf -d

# Step 3: In ANOTHER NEW terminal, start the WIDS engine
cd /home/bhairavam/Vajra-v1.0/Shakti-main
sudo python3 main.py

# Step 4: In ANOTHER NEW terminal, start the API server
cd /home/bhairavam/Vajra-v1.0/Shakti-main
sudo python3 api_server.py

# Step 5: Now connect your phone to "PMF_TEST" WiFi
# Password: StrongPassword123

# Step 6: Check logs in real-time
# Terminal 1: WIDS attacks
tail -f /home/bhairavam/Vajra-v1.0/Shakti-main/logs/wids_engine.log

# Terminal 2: API connections
tail -f /home/bhairavam/Vajra-v1.0/Shakti-main/logs/api_server.log

# Terminal 3: Check database for devices
sqlite3 /home/bhairavam/Vajra-v1.0/Shakti-main/wids.db "SELECT * FROM devices LIMIT 5;"
```

**Alternative: Log AP connections manually**

```bash
# Monitor connected devices
watch -n 1 'cat /proc/net/arp'

# Or use hostapd_cli to see who's connected
sudo hostapd_cli -i wlan2 list_sta
```

---

### Issue 3: Tor Not Working

**Why it happens:**
- Tor service not started
- Control port not configured (9051)
- stem module can't connect
- SOCKS port (9050) not accessible

**Manual Steps:**

```bash
# Step 1: Create Tor config
sudo cat > /etc/tor/torrc << 'EOF'
# Tor configuration for WIDS
SocksPort 9050
ControlPort 9051
ControlListenAddress 127.0.0.1
CookieAuthentication 1

# Enable logging
Log info file /var/log/tor/notices.log
DataDirectory /var/lib/tor
EOF

# Step 2: Fix permissions
sudo chown -R debian-tor:debian-tor /var/lib/tor
sudo chown -R debian-tor:debian-tor /var/log/tor

# Step 3: Start Tor
sudo service tor start

# Step 4: Check if it's running
sudo service tor status

# Or manually with debug output
sudo tor --quiet

# Step 5: Test SOCKS connection
curl --socks5 localhost:9050 https://ipinfo.io/ip

# Step 6: Test control port
telnet localhost 9051

# Step 7: Now your Python code can connect via stem:
python3 << 'EOF'
from stem.control import Controller

try:
    with Controller.from_port(port=9051) as controller:
        controller.authenticate()
        print("✓ Connected to Tor control port")
        print("Circuits:", len(controller.get_circuits()))
except Exception as e:
    print(f"✗ Error: {e}")
EOF
```

**Quick Tor test:**

```bash
# Check Tor logs
sudo tail -50 /var/log/tor/notices.log

# Check if ports are listening
sudo netstat -tuln | grep -E "9050|9051"
```

---

## Complete Manual Startup Sequence

**Terminal 1: Firewall**
```bash
cd /home/bhairavam/Vajra-v1.0/Shakti-main/firewall
./target/release/widrsx-backend
```

**Terminal 2: AP + DNSMASQ**
```bash
# Setup interfaces
sudo ip link set wlan2 down
sudo ip link set wlan2 up
sudo ip addr add 192.168.1.1/24 dev wlan2
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan2 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o wlan2 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Start hostapd
sudo hostapd -dd /home/bhairavam/Vajra-v1.0/Shakti-main/hostapd.conf
```

**Terminal 3: DNSMASQ (while Terminal 2 is running)**
```bash
sudo dnsmasq -C /tmp/dnsmasq.conf -d
```

**Terminal 4: Tor**
```bash
sudo service tor start
# or manually:
sudo tor --quiet
```

**Terminal 5: WIDS Engine**
```bash
cd /home/bhairavam/Vajra-v1.0/Shakti-main
sudo python3 main.py
```

**Terminal 6: API Server**
```bash
cd /home/bhairavam/Vajra-v1.0/Shakti-main
python3 api_server.py
```

**Terminal 7: Monitor logs**
```bash
cd /home/bhairavam/Vajra-v1.0/Shakti-main
watch -n 1 'echo "=== ACTIVE DEVICES ===" && sqlite3 wids.db "SELECT mac_address, last_seen FROM devices WHERE last_seen > datetime(\"now\", \"-1 minute\");" && echo && echo "=== ATTACKS ===" && sqlite3 wids.db "SELECT attack_type, COUNT(*) FROM logs WHERE timestamp > datetime(\"now\", \"-1 minute\") GROUP BY attack_type;"'
```

---

## Troubleshooting Checklist

- [ ] Hostapd can start without errors (`-dd` flag for debug)
- [ ] Interface wlan2 has IP 192.168.1.1
- [ ] DNSMASQ is running and serving DHCP
- [ ] Phone connects to AP
- [ ] Phone gets IP in 192.168.1.x range
- [ ] Phone can reach 8.8.8.8 DNS (test: `nslookup google.com`)
- [ ] Tor service running (check `sudo service tor status`)
- [ ] WIDS engine logging packets from wlan1
- [ ] API server accessible on port 5000
- [ ] Database has device/attack logs

---

## Database Queries for Verification

```bash
cd /home/bhairavam/Vajra-v1.0/Shakti-main

# See all tables
sqlite3 wids.db ".tables"

# Check connected devices
sqlite3 wids.db "SELECT * FROM devices;"

# Check attacks detected
sqlite3 wids.db "SELECT attack_type, COUNT(*) as count FROM logs GROUP BY attack_type;"

# Check Tor circuits
sqlite3 wids.db "SELECT * FROM tor_circuits LIMIT 10;"

# Check API requests
sqlite3 wids.db "SELECT * FROM network_usage LIMIT 10;"
```

