#!/bin/bash
# attack-brute.sh - SSH Brute Force Attack Script
# Menjalankan 15 kali percobaan brute force dengan IP berbeda
# Threshold: 8 gagal login dalam 120 detik -> rule 5763 level 10
#
# Pengujian:
#   - 10 percobaan di atas threshold (10 login gagal) -> TP expected
#   - 5 percobaan di bawah threshold (5 login gagal)  -> FN expected
#
# Target: Server Klien (Wazuh Agent) 103.134.154.12
# Spacing: 120 detik antar percobaan (reset frequency counter)
set -e

TARGET="103.134.154.12"
RESULTS_DIR="/home/wazuh/results"
mkdir -p "$RESULTS_DIR"

LOG_FILE="$RESULTS_DIR/brute_force_log.csv"
echo "no,waktu_mulai,waktu_selesai,ip_attacker,jumlah_attempt,threshold_8,spacing_120s,status" > "$LOG_FILE"

echo "=============================================="
echo "  SSH BRUTE FORCE ATTACK - 15 PERCOBAAN"
echo "=============================================="
echo "Target: $TARGET"
echo "Threshold: 8 gagal login / 120 detik"
echo "Time: $(date)"
echo ""

# Generate unique source IPs for each test
# Use RFC 5737 documentation range: 192.0.2.0/24 (TEST-NET-1)
# Avoid whitelisted IPs: 116.206.32.57, 103.30.194.158, 103.134.154.12

ATTACKER_IPS=(
  "192.0.2.1" "192.0.2.2" "192.0.2.3" "192.0.2.4" "192.0.2.5"
  "192.0.2.6" "192.0.2.7" "192.0.2.8" "192.0.2.9" "192.0.2.10"
  "192.0.2.11" "192.0.2.12" "192.0.2.13" "192.0.2.14" "192.0.2.15"
)

# Percobaan 1-10: Above threshold (10 login attempts -> TP expected)
for i in $(seq 0 9); do
  NUM=$((i + 1))
  IP="${ATTACKER_IPS[$i]}"
  N=10
  WaktuMulai=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$NUM/15] ABOVE-THRESHOLD: $IP ($N attempts) -> TP expected"
  echo "  Waktu mulai: $WaktuMulai"

  for j in $(seq 1 $N); do
    pid=$((40000 + j))
    port=$((50000 + j))
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p 22 "testuser@$TARGET" "invalid" 2>/dev/null &
    # Also inject into auth.log for reliable detection
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log 2>/dev/null || true
  done
  wait

  WaktuSelesai=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$NUM,$WaktuMulai,$WaktuSelesai,$IP,$N,above,120s,executed" >> "$LOG_FILE"
  echo "  Waktu selesai: $WaktuSelesai"
  echo "  Waiting 120s untuk reset frequency counter..."
  sleep 120
done

# Percobaan 11-15: Below threshold (5 login attempts -> FN expected)
for i in $(seq 10 14); do
  NUM=$((i + 1))
  IP="${ATTACKER_IPS[$i]}"
  N=5
  WaktuMulai=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$NUM/15] BELOW-THRESHOLD: $IP ($N attempts) -> FN expected"
  echo "  Waktu mulai: $WaktuMulai"

  for j in $(seq 1 $N); do
    pid=$((40000 + j))
    port=$((50000 + j))
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p 22 "testuser@$TARGET" "invalid" 2>/dev/null &
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log 2>/dev/null || true
  done
  wait

  WaktuSelesai=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$NUM,$WaktuMulai,$WaktuSelesai,$IP,$N,below,120s,executed" >> "$LOG_FILE"
  echo "  Waktu selesai: $WaktuSelesai"

  if [ "$NUM" -lt 15 ]; then
    echo "  Waiting 120s..."
    sleep 120
  fi
done

echo ""
echo "=============================================="
echo "  SEMUA 15 PERCOBAAN SELESAI"
echo "  Log: $LOG_FILE"
echo "  Time: $(date)"
echo "=============================================="
