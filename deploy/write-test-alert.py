#!/usr/bin/env python3
import json

alert = {
    "id": "test-wazuh-001",
    "rule": {"id": "100", "level": 10, "description": "Test Alert from Wazuh"},
    "agent": {"id": "001", "name": "test-agent"},
    "timestamp": "2026-07-31T07:00:00Z"
}

with open("/tmp/test-alert.json", "w") as f:
    json.dump(alert, f)

print("Test alert written")
