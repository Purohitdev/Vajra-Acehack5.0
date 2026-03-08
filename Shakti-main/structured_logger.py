#!/usr/bin/env python3
import json
import uuid
import socket
import logging
from datetime import datetime
import os

class StructuredLogger:
    def __init__(self, service_name):
        self.service_name = service_name
        self.system_node = socket.gethostname()
        self.log_file = os.path.join("logs", f"{service_name}.jsonl")

        # Ensure logs directory exists
        os.makedirs("logs", exist_ok=True)

        # Also keep a standard logger for console output
        self.console_logger = logging.getLogger(service_name)
        self.console_logger.setLevel(logging.INFO)
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        self.console_logger.addHandler(handler)

    def _generate_log_id(self):
        return f"LOG-{uuid.uuid4().hex[:8].upper()}"

    def _generate_session_id(self):
        return f"S-{uuid.uuid4().hex[:6].upper()}"

    def _get_global_metadata(self, severity, event_type, session_id=None):
        return {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "log_id": self._generate_log_id(),
            "system_node": self.system_node,
            "service_name": self.service_name,
            "severity": severity,
            "event_type": event_type,
            "session_id": session_id or self._generate_session_id()
        }

    def log(self, severity, event_type, data, session_id=None):
        """Log a structured event"""
        log_entry = {
            **self._get_global_metadata(severity, event_type, session_id),
            **data
        }

        # Write to JSONL file
        with open(self.log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')

        # Also log to console
        self.console_logger.info(f"{event_type}: {json.dumps(data, indent=None)}")

        return log_entry

    # Convenience methods
    def info(self, event_type, data, session_id=None):
        return self.log("INFO", event_type, data, session_id)

    def warning(self, event_type, data, session_id=None):
        return self.log("WARNING", event_type, data, session_id)

    def alert(self, event_type, data, session_id=None):
        return self.log("ALERT", event_type, data, session_id)

    def critical(self, event_type, data, session_id=None):
        return self.log("CRITICAL", event_type, data, session_id)

# Service-specific loggers
ap_logger = StructuredLogger("ap_controller")
wids_logger = StructuredLogger("wids_engine")
firewall_logger = StructuredLogger("firewall_engine")
tor_logger = StructuredLogger("tor_router")
bandwidth_logger = StructuredLogger("bandwidth_manager")
system_logger = StructuredLogger("system_monitor")