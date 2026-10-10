#!/bin/bash
# collect-manager-alerts.sh — Snapshot alert yang tiba di Wazuh Manager (deteksi).
# Berisi ringkasan alert terkait brute-force (5712/5720/5763/5551) dan Suricata
# (86600/86601/100102/100103) dalam window waktu tertentu.
#
# Penggunaan: bash collect-manager-alerts.sh <since_ts> [<until_ts>]
#   since_ts/until_ts format epoch (detik). Bila tidak ada, tampilkan 500 baris terakhir.

set -e
SINCE="${1:-}"
UNTIL="${2:-}"

ALERTS="/var/ossec/logs/alerts/alerts.json"
RULES_SSH="5712|5720|5763|5551"
RULES_SUR="86600|86601|100102|100103"

echo "=== TIMESTAMP ==="
date "+%FT%T%z"

echo "=== ALERTS FILE ==="
echo "total lines: $(sudo wc -l < "$ALERTS")"
echo "last mtime:  $(sudo stat -c '%y' "$ALERTS")"

echo "=== RULE trigger (brute-force) ==="
sudo grep -E "\"rule\"\s*:\s*\{\s*\"id\"\s*:\s*\"($RULES_SSH)\"" "$ALERTS" \
  | grep -oE '"id":"(5712|5720|5763|5551)"' | sort | uniq -c || true

echo "=== RULE trigger (suricata portscan) ==="
sudo grep -E "\"rule\"\s*:\s*\{\s*\"id\"\s*:\s*\"($RULES_SUR)\"" "$ALERTS" \
  | grep -oE '"id":"(86600|86601|100102|100103)"' | sort | uniuc -c || true

echo "=== Last 15 relevant alerts (rule + src_ip) ==="
sudo grep -E "\"rule\"\s*:\s*\{\s*\"id\"\s*:\s*\"($RULES_SUR|$RULES_SSH)\"" "$ALERTS" \
  | grep -oE '("id":"(86600|86601|100102|100103|5712|5720|5763|5551)"|\"src_ip\":\"[0-9.]+\")' \
  | tail -30 || true

echo "=== Agent 001 (srv_kampusmu) status ==="
sudo /var/ossec/bin/agent_control -i 001 2>/dev/null | grep -E 'Status|IP Address|Connected' || true

echo "DONE"