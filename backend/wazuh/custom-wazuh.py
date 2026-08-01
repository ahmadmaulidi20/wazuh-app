#!/usr/bin/env python3
"""
Wazuh Custom Integration Script
Sends alerts to the backend API for processing and notification.
Place in /var/ossec/integrations/ on the Wazuh Manager.
"""
import json
import sys
import os
import requests

WEBHOOK_URL = os.environ.get("WEBHOOK_URL", "http://localhost:3000/api/webhook/wazuh")
API_KEY = os.environ.get("API_KEY", "")

if not API_KEY:
    print("ERROR: API_KEY environment variable is required", file=sys.stderr)
    sys.exit(1)

try:
    alert = json.loads(sys.stdin.read())
except json.JSONDecodeError as e:
    print(f"ERROR: Invalid JSON input: {e}", file=sys.stderr)
    sys.exit(1)

try:
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": API_KEY,
    }
    resp = requests.post(WEBHOOK_URL, json=alert, headers=headers, timeout=10)
    resp.raise_for_status()
    print(f"SUCCESS: Alert forwarded (ID: {resp.json().get('id', 'unknown')})")
except requests.RequestException as e:
    print(f"ERROR: Failed to forward alert: {e}", file=sys.stderr)
    sys.exit(1)
