#!/bin/bash
# run-experiment.sh - Master Script Eksekusi Penuh
# Menjalankan seluruh rangkaian eksperimen untuk skripsi:
#   1. SSH Brute Force (15 percobaan)
#   2. Port Scanning 1-1000 (10 percobaan)
#   3. Port Scanning 1-65535 (10 percobaan)
#   4. Kumpulkan data deteksi, pencegahan, notifikasi
#   5. Monitoring 72 jam (opsional, jalankan terpisah)
#
# Penggunaan: sudo bash run-experiment.sh [--with-monitor]
#   --with-monitor: menjalankan monitoring 72 jam setelah eksperimen
#
# Sistem:
#   - Wazuh Manager: 103.30.194.158
#   - Server Klien (agent + Suricata): 103.134.154.12
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="/home/wazuh/results"
mkdir -p "$RESULTS_DIR"

LOGFILE="$RESULTS_DIR/experiment_log.txt"

WITH_MONITOR=0
if [ "$1" = "--with-monitor" ]; then
  WITH_MONITOR=1
fi

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [EXPERIMENT] $1" | tee -a "$LOGFILE"
}

echo "==============================================="
echo "  WA Z U H  -  E K S P E R I M E N  S K R I P S I"
echo "==============================================="
echo "  Implementasi Sistem Monitoring Menggunakan Wazuh"
echo "  sebagai SIEM dalam Pencegahan Ancaman Keamanan"
echo "  Server (SSH Brute Force & Port Scanning)"
echo ""
echo "  Waktu mulai: $(date)"
echo "  Log file: $LOGFILE"
echo "  Results dir: $RESULTS_DIR"
echo ""

# =============================================
# STEP 1: PERSIAPAN
# =============================================
log "========================================"
log "STEP 1: VERIFIKASI SISTEM"
log "========================================"

echo ""
echo "--- Memeriksa layanan... ---"

# Check Wazuh Manager
if pgrep -x "wazuh-manager" > /dev/null || systemctl is-active --quiet wazuh-manager 2>/dev/null || systemctl is-active --quiet wazuh 2>/dev/null; then
  log "OK: Wazuh Manager aktif"
  echo "  [OK] Wazuh Manager aktif"
else
  log "WARNING: Wazuh Manager tidak terdeteksi sebagai service. Memeriksa proses..."
  if pgrep -f "ossec" > /dev/null; then
    log "  Process ossec terdeteksi aktif"
    echo "  [OK] Proses wazuh (ossec) terdeteksi"
  else
    log "ERROR: Wazuh Manager tidak aktif! Eksperimen dibatalkan."
    echo "  [ERROR] Wazuh Manager tidak aktif!"
    exit 1
  fi
fi

# Check Suricata (harus di agent server, tetapi script ini jalan di manager)
# Untuk verifikasi silang, periksa apakah ada agent yang terhubung
log "CATATAN: Suricata dijalankan di Server Klien (103.134.154.12), diverifikasi manual."

# Check Backend
if systemctl is-active --quiet backend 2>/dev/null || pgrep -f "node.*src/index" > /dev/null || pgrep -f "node.*dist/index" > /dev/null; then
  log "OK: Backend (node.js) aktif"
  echo "  [OK] Backend aktif"
else
  log "WARNING: Backend tidak terdeteksi. Notifikasi mungkin tidak berfungsi."
  echo "  [WARNING] Backend tidak terdeteksi."
fi

# Check PostgreSQL
if systemctl is-active --quiet postgresql 2>/dev/null || pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
  log "OK: PostgreSQL aktif"
  echo "  [OK] PostgreSQL aktif"
else
  log "WARNING: PostgreSQL tidak terdeteksi."
  echo "  [WARNING] PostgreSQL tidak terdeteksi."
fi

# =============================================
# STEP 2: PRE-EXPERIMENT SNAPSHOT
# =============================================
log "========================================"
log "STEP 2: SNAPSHOT AWAL"
log "========================================"

SNAPSHOT_FILE="$RESULTS_DIR/pre_experiment_snapshot.txt"
{
  echo "PRE-EXPERIMENT SNAPSHOT - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "================================"
  echo ""
  echo "--- IPTABLES DROP RULES ---"
  sudo iptables -L INPUT -n --line-numbers 2>/dev/null || echo "(tidak dapat membaca)"
  echo ""
  echo "--- ACTIVE RESPONSES LOG (last 20) ---"
  tail -n 20 /var/ossec/logs/active-responses.log 2>/dev/null || echo "(not available)"
  echo ""
  echo "--- AGENTS ---"
  /var/ossec/bin/agent_control -l 2>/dev/null || echo "(not available)"
  echo ""
  echo "--- BACKEND DATABASE ALERT COUNT ---"
  PGPASSWORD="wazuh123" psql -h localhost -U wazuh -d wazuh_monitor -t -A -c "SELECT COUNT(*) FROM alerts;" 2>/dev/null || echo "(db not accessible)"
  echo ""
} > "$SNAPSHOT_FILE"
log "Snapshot awal disimpan: $SNAPSHOT_FILE"
echo "  [OK] Snapshot awal: $SNAPSHOT_FILE"

# =============================================
# STEP 3: EKSPERIMEN SSH BRUTE FORCE
# =============================================
log "========================================"
log "STEP 3: SSH BRUTE FORCE (15 PERCOBAAN)"
log "========================================"
echo ""
echo ">>> Menjalankan eksperimen SSH Brute Force..."
echo "    Target: Server Klien (103.134.154.12)"
echo "    Threshold: 8 gagal login / 120 detik"
echo "    IP Attacker: 192.0.2.1 - 192.0.2.15 (RFC 5737)"
echo ""

if [ -f "$SCRIPT_DIR/attack-brute.sh" ]; then
  sudo bash "$SCRIPT_DIR/attack-brute.sh" 2>&1 | tee "$RESULTS_DIR/brute_force_stdout.log"
  log "SSH Brute Force selesai. Log: $RESULTS_DIR/brute_force_log.csv"
else
  log "ERROR: Script attack-brute.sh tidak ditemukan!"
fi

# =============================================
# STEP 4: EKSPERIMEN PORT SCANNING
# =============================================
log "========================================"
log "STEP 4: PORT SCANNING (20 PERCOBAAN)"
log "========================================"
echo ""
echo ">>> Menjalankan eksperimen Port Scanning..."
echo "    Skenario 1: 10x port 1-1000"
echo "    Skenario 2: 10x port 1-65535"
echo "    Threshold Suricata: 8 SYN / 60 detik"
echo ""

if [ -f "$SCRIPT_DIR/attack-portscan.sh" ]; then
  sudo bash "$SCRIPT_DIR/attack-portscan.sh" 2>&1 | tee "$RESULTS_DIR/portscan_stdout.log"
  log "Port Scanning selesai. Log: $RESULTS_DIR/portscan_log.csv"
else
  log "ERROR: Script attack-portscan.sh tidak ditemukan!"
fi

# =============================================
# STEP 5: KUMPULKAN DATA
# =============================================
log "========================================"
log "STEP 5: PENGUMPULAN DATA MENTAH"
log "========================================"
echo ""

echo ">>> Mengumpulkan data deteksi..."
if [ -f "$SCRIPT_DIR/collect-detection.sh" ]; then
  sudo bash "$SCRIPT_DIR/collect-detection.sh" 2>&1 | tee "$RESULTS_DIR/collect_detection_stdout.log"
fi
echo ""

echo ">>> Mengumpulkan data pencegahan..."
if [ -f "$SCRIPT_DIR/collect-prevention.sh" ]; then
  sudo bash "$SCRIPT_DIR/collect-prevention.sh" 2>&1 | tee "$RESULTS_DIR/collect_prevention_stdout.log"
fi
echo ""

echo ">>> Mengumpulkan data notifikasi..."
if [ -f "$SCRIPT_DIR/collect-notification.sh" ]; then
  sudo bash "$SCRIPT_DIR/collect-notification.sh" 2>&1 | tee "$RESULTS_DIR/collect_notification_stdout.log"
fi
echo ""

# =============================================
# STEP 6: POST-EXPERIMENT SNAPSHOT
# =============================================
log "========================================"
log "STEP 6: SNAPSHOT AKHIR"
log "========================================"

SNAPSHOT_END="$RESULTS_DIR/post_experiment_snapshot.txt"
{
  echo "POST-EXPERIMENT SNAPSHOT - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "================================"
  echo ""
  echo "--- IPTABLES DROP RULES ---"
  sudo iptables -L INPUT -n --line-numbers 2>/dev/null || echo "(tidak dapat membaca)"
  echo ""
  echo "--- ACTIVE RESPONSES LOG (last 50) ---"
  tail -n 50 /var/ossec/logs/active-responses.log 2>/dev/null || echo "(not available)"
  echo ""
  echo "--- BACKEND DATABASE ALERT COUNT ---"
  PGPASSWORD="wazuh123" psql -h localhost -U wazuh -d wazuh_monitor -t -A -c "SELECT COUNT(*) FROM alerts;" 2>/dev/null || echo "(db not accessible)"
  echo ""
} > "$SNAPSHOT_END"
log "Snapshot akhir disimpan: $SNAPSHOT_END"

# =============================================
# STEP 7: RINGKASAN
# =============================================
log "========================================"
log "STEP 7: RINGKASAN EKSPERIMEN"
log "========================================"

echo ""
echo "==============================================="
echo "  RINGKASAN EKSPERIMEN SELESAI"
echo "==============================================="
echo "  Waktu selesai: $(date)"
echo ""
echo "  FILE HASIL:"
echo "  ----------------------------------------"
ls -la "$RESULTS_DIR" | grep -E "\.(csv|log|txt)$"
echo ""
echo "  FILE DATA MENTAH:"
echo "  - $RESULTS_DIR/brute_force_log.csv     (15 percobaan SSH brute force)"
echo "  - $RESULTS_DIR/portscan_log.csv        (20 percobaan port scanning)"
echo "  - $RESULTS_DIR/detection_data.csv      (status deteksi TP/FN)"
echo "  - $RESULTS_DIR/prevention_data.csv     (status block + akses user)"
echo "  - $RESULTS_DIR/notification_data.csv   (timing notifikasi)"
echo "  - $RESULTS_DIR/monitoring_72h.csv      (harus dijalankan 72 jam)"
echo ""
log "Eksperimen selesai!"

# =============================================
# OPSIONAL: MONITORING 72 JAM
# =============================================
if [ "$WITH_MONITOR" = "1" ]; then
  log "========================================"
  log "OPTIONAL: MENJALANKAN MONITORING 72 JAM"
  log "========================================"
  echo ""
  echo ">>> Memulai monitoring 72 jam di background..."
  if [ -f "$SCRIPT_DIR/monitor-72h.sh" ]; then
    nohup sudo bash "$SCRIPT_DIR/monitor-72h.sh" 72 > "$RESULTS_DIR/monitor_72h_stdout.log" 2>&1 &
    echo "  Monitoring berjalan di background (PID: $!)"
    echo "  Log: $RESULTS_DIR/monitor_72h_stdout.log"
    echo "  Data: $RESULTS_DIR/monitoring_72h.csv"
  else
    log "ERROR: Script monitor-72h.sh tidak ditemukan!"
  fi
else
  echo ""
  echo ">>> Monitoring 72 jam TIDAK dijalankan."
  echo "    Jalankan manual:"
  echo "    nohup sudo bash $SCRIPT_DIR/monitor-72h.sh 72 > $RESULTS_DIR/monitor_72h_stdout.log 2>&1 &"
  echo ""
fi

echo "==============================================="
echo "  SELESAI - Semua file ada di $RESULTS_DIR"
echo "==============================================="