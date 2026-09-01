#!/usr/bin/env python3

import json
import sys
import os
import requests

alert_path = sys.argv[1]
api_key = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("API_KEY", "CHANGE_ME")
webhook_url = sys.argv[3] if len(sys.argv) > 3 else os.environ.get("WEBHOOK_URL", "http://localhost:3000/api/webhook/wazuh")

try:
    with open(alert_path, "r") as f:
        alert = json.load(f)
except (json.JSONDecodeError, IOError) as e:
    print(f"ERROR: Failed to read alert: {e}", file=sys.stderr)
    sys.exit(1)

try:
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": api_key,
    }
    resp = requests.post(webhook_url, json=alert, headers=headers, timeout=10)
    resp.raise_for_status()
    print(f"SUCCESS: Alert forwarded (ID: {resp.json().get('id', 'unknown')})")
except requests.RequestException as e:
    print(f"ERROR: Failed to forward alert: {e}", file=sys.stderr)
    sys.exit(1)
