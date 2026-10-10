#!/bin/bash
# portscan_all.sh - Run 10 nmap scans from Manager
# Scan 1-2 already done, this does 3-10
set -e

TARGET="103.134.154.12"
NMAP="/usr/bin/nmap"

test_num=2
for i in $(seq 1 8); do
  test_num=$((test_num + 1))
  echo "=== Port Scan Test $test_num/10 ==="
  echo "  Time: $(date +'%Y-%m-%d %H:%M:%S')"
  sudo $NMAP -sS -T4 --top-ports 200 $TARGET 2>&1 | tail -3
  echo "  Sleeping 5s before next scan..."
  sleep 5
done

echo "=== All 8 scans completed ==="
