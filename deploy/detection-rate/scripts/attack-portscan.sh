#!/bin/bash
# attack-portscan.sh - Port Scanning Attack Script
# Menjalankan port scan dengan Nmap ke server target
# Skenario:
#   - 10x port scan 1-1000 (TCP SYN)
#   - 10x port scan 1-65535 (TCP SYN full range)
#
# Threshold Suricata: 8+ SYN packets dalam 60 detik (track by_src)
# Detected oleh Wazuh rule 100102 (level 10)
#
# Target: Server Klien (Wazuh Agent) 103.134.154.12
set -e

NMAP="/usr/bin/nmap"
TARGET="103.134.154.12"
RESULTS_DIR="/home/wazuh/results"
mkdir -p "$RESULTS_DIR"

LOG_FILE="$RESULTS_DIR/portscan_log.csv"
echo "no,skenario,waktu_mulai,waktu_selesai,command,status" > "$LOG_FILE"

echo "=============================================="
echo "  PORT SCANNING ATTACK - 20 PERCOBAAN"
echo "=============================================="
echo "Target: $TARGET"
echo "  - 10x: port 1-1000 (top 200 ports)"
echo "  - 10x: port 1-65535 (full range)"
echo "Threshold Suricata: 8 SYN / 60 detik"
echo "Time: $(date)"
echo ""

echo "--- Skenario 1: Port Scan 1-1000 (10 pengujian) ---"
for i in $(seq 1 10); do
  WaktuMulai=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[Scan $i/20] nmap -sS -T4 --top-ports 200 $TARGET"
  echo "  Waktu mulai: $WaktuMulai"

  sudo $NMAP -sS -T4 --top-ports 200 "$TARGET" 2>&1 | tail -3

  WaktuSelesai=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$i,1-1000,$WaktuMulai,$WaktuSelesai,nmap -sS -T4 --top-ports 200 $TARGET,executed" >> "$LOG_FILE"
  echo "  Waktu selesai: $WaktuSelesai"

  if [ "$i" -lt 10 ]; then
    echo "  Waiting 70s (reset Suricata threshold window)..."
    sleep 70
  fi
done

echo ""
echo "  Waiting 70s sebelum full range scan..."
sleep 70

echo "--- Skenario 2: Port Scan 1-65535 (10 pengujian) ---"
for i in $(seq 1 10); do
  WaktuMulai=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[Scan $((i + 10))/20] nmap -sS -p 1-65535 -T5 --min-rate 3000 $TARGET"
  echo "  Waktu mulai: $WaktuMulai"

  sudo $NMAP -sS -p 1-65535 -T5 --min-rate 3000 --max-retries 1 --host-timeout 120s "$TARGET" 2>&1 | tail -3

  WaktuSelesai=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$((i + 10)),1-65535,$WaktuMulai,$WaktuSelesai,nmap -sS -p 1-65535 -T5 --min-rate 3000 $TARGET,executed" >> "$LOG_FILE"
  echo "  Waktu selesai: $WaktuSelesai"

  if [ "$i" -lt 10 ]; then
    echo "  Waiting 30s..."
    sleep 30
  fi
done

echo ""
echo "=============================================="
echo "  SEMUA 20 PERCOBAAN SELESAI"
echo "  Log: $LOG_FILE"
echo "  Time: $(date)"
echo "=============================================="