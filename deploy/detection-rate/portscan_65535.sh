#!/bin/bash
# portscan_65535.sh - Full-range (1-65535) port scan experiment (4.2.3)
# 8 spaced scans (TP, >60s between starts) + 2 rapid scans (FN within 60s window)
set -e
NMAP="/usr/bin/nmap"
TARGET="103.134.154.12"
OUT="/tmp/portscan_65535_log.txt"
SCAN_ARGS="-sS -p 1-65535 -T5 --min-rate 3000 --max-retries 1 --host-timeout 120s"

echo "=== Port Scan 1-65535 Experiment $(date) ===" > "$OUT"

echo "--- 8 SPACED SCANS (TP) ---" >> "$OUT"
for i in $(seq 1 8); do
  START=$(date +'%H:%M:%S')
  echo "S#$i START=$START" >> "$OUT"
  sudo $NMAP $SCAN_ARGS $TARGET >/dev/null 2>&1
  echo "S#$i END=$(date +'%H:%M:%S') waiting 30s" >> "$OUT"
  sleep 30
done

echo "--- 2 RAPID SCANS (FN expected, within 60s window) ---" >> "$OUT"
for i in 9 10; do
  START=$(date +'%H:%M:%S')
  echo "S#$i START=$START" >> "$OUT"
  sudo $NMAP $SCAN_ARGS $TARGET >/dev/null 2>&1
  echo "S#$i END=$(date +'%H:%M:%S') sleep 3s" >> "$OUT"
  sleep 3
done

echo "=== done $(date) ===" >> "$OUT"
