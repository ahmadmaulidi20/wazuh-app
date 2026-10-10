#!/bin/bash
# monitor_3ip.sh - Periodic brute-force simulation from 3 different attacker IPs
# for the 3x24h real-time monitoring requirement (sub-bab 4.4.1 / 4.5).
# Run on AGENT (where /var/log/auth.log is): nohup sudo bash monitor_3ip.sh &
set -e

LOG="/var/log/monitor_3ip.log"
AUTHLOG="/var/log/auth.log"
INTERVAL=${1:-900}   # seconds between rounds (default 15 min)

# Three distinct attacker IPs (RFC 5737 documentation range, does not conflict
# with real traffic). These are NOT whitelisted -> treated as attackers.
IP_A="198.51.100.10"
IP_B="203.0.113.20"
IP_C="198.51.100.30"

inject() {
  local ip="$1" n="$2"
  for i in $(seq 1 "$n"); do
    pid=$((20000 + RANDOM % 5000))
    port=$((30000 + RANDOM % 20000))
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $ip port $port ssh2" >> "$AUTHLOG"
  done
}

echo "=== 3-IP MONITORING START $(date) ===" >> "$LOG"
while true; do
  inject "$IP_A" 8
  sleep 1
  inject "$IP_B" 9
  sleep 1
  inject "$IP_C" 7
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] injected A=$IP_A(8) B=$IP_B(9) C=$IP_C(7)" >> "$LOG"
  sleep "$INTERVAL"
done
