from scapy.all import sniff, Dot11Deauth, Dot11Beacon, Dot11ProbeReq, Dot11Auth, Dot11Elt
import yaml
from database import insert_log
import logging
import time
from structured_logger import wids_logger

try:
    with open("config.yaml") as f:
        config = yaml.safe_load(f)
    interface = config.get('interface')
    log_level = getattr(logging, config.get('log_level', 'INFO').upper(), logging.INFO)
except Exception as e:
    logging.basicConfig(level=logging.INFO)
    logging.error(f"Failed to load config.yaml: {e}")
    exit(1)

logging.basicConfig(level=log_level)

if not interface:
    logging.error("No interface specified in config.yaml.")
    exit(1)

attack_counts = {}

def get_channel(pkt):
    channel_val = "Unknown"
    elt = pkt.getlayer('Dot11Elt')
    while elt is not None:
        if hasattr(elt, 'ID') and elt.ID == 3:
            try:
                channel_val = str(elt.info[0])
            except Exception:
                channel_val = "Unknown"
            break
        elt = elt.payload.getlayer('Dot11Elt')
    return channel_val

def handle_packet(pkt):
    # Log beacon frames for connected devices
    if pkt.haslayer(Dot11Beacon):
        beacon = pkt.getlayer(Dot11Beacon)
        bssid = pkt.addr3
        signal = getattr(pkt, 'dBm_AntSignal', '?')
        channel = get_channel(pkt)
        
        # Try to extract SSID
        essid = "Hidden"
        if pkt.haslayer(Dot11Elt):
            elt = pkt.getlayer(Dot11Elt)
            while elt is not None:
                if hasattr(elt, 'ID') and elt.ID == 0:  # SSID element
                    try:
                        essid = elt.info.decode('utf-8', errors='ignore')
                        break
                    except:
                        pass
                elt = elt.payload.getlayer('Dot11Elt')
        
        # Real-time output
        print(f"\033[92m[BEACON] BSSID: {bssid} | SSID: {essid} | Channel: {channel} | Signal: {signal}\033[0m")
        
        # Check for beacon floods
        if bssid in attack_counts:
            attack_counts[bssid] += 1
        else:
            attack_counts[bssid] = 1

        if attack_counts[bssid] > 10:  # Threshold
            msg = "Beacon Flood"
            insert_log(bssid, signal, channel, msg)
            print(f"\033[91m[ATTACK] Beacon Flood from {bssid}\033[0m")
            wids_logger.alert("wireless_attack_detected", {
                "attack_type": "beacon_flood",
                "attacker_mac": bssid,
                "ssid_targeted": essid,
                "channel": int(channel) if channel.isdigit() else 0,
                "frequency": 2400 + (int(channel) * 5) if channel.isdigit() else 0,
                "signal_strength_dbm": int(signal) if signal != "?" else 0,
                "frame_type": "management",
                "frame_subtype": "beacon",
                "packet_rate_per_second": attack_counts[bssid],
                "detection_confidence": 0.90,
                "detected_by_sensor": "widrsx-engine",
                "sensor_interface": interface
            })

    # Log authentication frames (device connections)
    elif pkt.haslayer(Dot11Auth):
        mac = pkt.addr2
        signal = getattr(pkt, 'dBm_AntSignal', '?')
        channel = get_channel(pkt)
        print(f"\033[94m[AUTH] Device: {mac} | Channel: {channel} | Signal: {signal}\033[0m")
        wids_logger.info("wireless_auth_attempt", {
            "device_mac": mac,
            "signal_strength": signal,
            "channel": channel,
            "timestamp": time.time()
        })
        insert_log(mac, signal, channel, "Authentication Attempt")
    
    # Log deauth frames (attacks)
    elif pkt.haslayer(Dot11Deauth):
        mac = getattr(pkt, 'addr2', "Unknown")
        signal = getattr(pkt, 'dBm_AntSignal', "?")
        channel = get_channel(pkt)
        msg = "DeAuthentication"
        insert_log(mac, signal, channel, msg)
        print(f"\033[91m[ATTACK-DEAUTH] Attacker: {mac} | Target: {pkt.addr1} | Channel: {channel}\033[0m")
        wids_logger.alert("wireless_attack_detected", {
            "attack_type": "deauthentication",
            "attacker_mac": mac,
            "target_mac": getattr(pkt, 'addr1', "Unknown"),
            "ssid_targeted": "SecureAP",
            "channel": int(channel) if channel.isdigit() else 0,
            "frequency": 2400 + (int(channel) * 5) if channel.isdigit() else 0,
            "signal_strength_dbm": int(signal) if signal != "?" else 0,
            "frame_type": "management",
            "frame_subtype": "deauth",
            "packet_rate_per_second": 1,
            "detection_confidence": 0.95,
            "detected_by_sensor": "widrsx-engine",
            "sensor_interface": interface
        })

    elif pkt.haslayer(Dot11ProbeReq):
        # Check for probe request floods
        src_mac = pkt.addr2
        if src_mac in attack_counts:
            attack_counts[src_mac] += 1
        else:
            attack_counts[src_mac] = 1

        if attack_counts[src_mac] > 20:  # Threshold
            signal = getattr(pkt, 'dBm_AntSignal', "?")
            channel = get_channel(pkt)
            msg = "Probe Request Flood"
            insert_log(src_mac, signal, channel, msg)
            wids_logger.alert("wireless_attack_detected", {
                "attack_type": "probe_request_flood",
                "attacker_mac": src_mac,
                "ssid_targeted": "Broadcast",
                "channel": int(channel) if channel.isdigit() else 0,
                "frequency": 2400 + (int(channel) * 5) if channel.isdigit() else 0,
                "signal_strength_dbm": int(signal) if signal != "?" else 0,
                "frame_type": "management",
                "frame_subtype": "probe_request",
                "packet_rate_per_second": attack_counts[src_mac],
                "detection_confidence": 0.85,
                "detected_by_sensor": "widrsx-engine",
                "sensor_interface": interface
            })

    elif pkt.haslayer(Dot11Auth):
        # Check for auth floods
        src_mac = pkt.addr2
        if src_mac in attack_counts:
            attack_counts[src_mac] += 1
        else:
            attack_counts[src_mac] = 1

        if attack_counts[src_mac] > 15:  # Threshold
            signal = getattr(pkt, 'dBm_AntSignal', "?")
            channel = get_channel(pkt)
            msg = "Authentication Flood"
            insert_log(src_mac, signal, channel, msg)
            wids_logger.alert("wireless_attack_detected", {
                "attack_type": "authentication_flood",
                "attacker_mac": src_mac,
                "target_mac": getattr(pkt, 'addr1', "Unknown"),
                "ssid_targeted": "SecureAP",
                "channel": int(channel) if channel.isdigit() else 0,
                "frequency": 2400 + (int(channel) * 5) if channel.isdigit() else 0,
                "signal_strength_dbm": int(signal) if signal != "?" else 0,
                "frame_type": "management",
                "frame_subtype": "auth",
                "packet_rate_per_second": attack_counts[src_mac],
                "detection_confidence": 0.88,
                "detected_by_sensor": "widrsx-engine",
                "sensor_interface": interface
            })

    # Clean up old counts periodically
    if len(attack_counts) > 1000:
        current_time = time.time()
        # Simple cleanup, in practice use timestamps
        attack_counts.clear()

wids_logger.info("wids_service_started", {"sensor_interface": interface})
logging.info(f"[*] Starting Wi-Fi sniffing on interface: {interface}")
try:
    sniff(prn=handle_packet, iface=interface, store=0)
except KeyboardInterrupt:
    logging.info("[*] Sniffing stopped by user.")
    wids_logger.info("wids_service_stopped", {"reason": "user_interrupt"})
except Exception as e:
    logging.error(f"Error during sniffing: {e}")
    wids_logger.critical("wids_service_error", {"error": str(e)})
