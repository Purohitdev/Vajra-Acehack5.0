#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime

def tail_logs(service_name=None, lines=50):
    """Tail the structured logs for a specific service or all services"""
    logs_dir = "logs"
    
    if not os.path.exists(logs_dir):
        print("Logs directory does not exist")
        return
    
    log_files = []
    if service_name:
        log_file = os.path.join(logs_dir, f"{service_name}.jsonl")
        if os.path.exists(log_file):
            log_files.append(log_file)
        else:
            print(f"No logs found for service: {service_name}")
            return
    else:
        # Get all .jsonl files
        for file in os.listdir(logs_dir):
            if file.endswith('.jsonl'):
                log_files.append(os.path.join(logs_dir, file))
    
    all_entries = []
    for log_file in log_files:
        try:
            with open(log_file, 'r') as f:
                for line in f:
                    if line.strip():
                        try:
                            entry = json.loads(line.strip())
                            all_entries.append(entry)
                        except json.JSONDecodeError:
                            continue
        except Exception as e:
            print(f"Error reading {log_file}: {e}")
    
    # Sort by timestamp
    all_entries.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
    
    # Display last N entries
    for entry in all_entries[:lines]:
        timestamp = entry.get('timestamp', 'Unknown')
        service = entry.get('service_name', 'Unknown')
        event = entry.get('event_type', 'Unknown')
        severity = entry.get('severity', 'INFO')
        
        print(f"[{timestamp}] [{service}] [{severity}] {event}")
        
        # Print key data fields
        data = {k: v for k, v in entry.items() 
                if k not in ['timestamp', 'log_id', 'system_node', 'service_name', 'severity', 'event_type', 'session_id']}
        
        for key, value in data.items():
            print(f"  {key}: {value}")
        print()

if __name__ == "__main__":
    service = sys.argv[1] if len(sys.argv) > 1 else None
    lines = int(sys.argv[2]) if len(sys.argv) > 2 else 20
    
    tail_logs(service, lines)