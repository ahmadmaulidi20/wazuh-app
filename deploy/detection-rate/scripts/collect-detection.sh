#!/bin/bash
# collect-detection.sh - Mengumpulkan Data Deteksi SSH Brute Force & Port Scanning
# Membaca alerts.json dari Wazuh Manager dan cross-reference dengan log serangan
#
# Output: /home/wazuh/results/detection_data.csv
# Kolom: No, Aktivitas, Waktu Aktivitas, Waktu Alert, Status Deteksi
#
# Jalankan SETELAH eksperimen brute force & port scanning selesai
# Penggunaan: sudo bash collect-detection.sh
set -e

RESULTS_DIR="/home/wazuh/results"
mkdir -p "$RESULTS_DIR"
OUTPUT="$RESULTS_DIR/detection_data.csv"

# File-file input
BRUTE_LOG="$RESULTS_DIR/brute_force_log.csv"
PORTSCAN_LOG="$RESULTS_DIR/portscan_log.csv"
ALERTS_JSON="/var/ossec/logs/alerts/alerts.json"

echo "=============================================="
echo "  COLLECT DETECTION DATA"
echo "=============================================="
echo "Output: $OUTPUT"
echo ""

# Header CSV
cat > "$OUTPUT" << 'EOF'
No,Aktivitas,Waktu Aktivitas,Waktu Alert,Status Deteksi
EOF

if [ ! -f "$BRUTE_LOG" ]; then
  echo "WARNING: $BRUTE_LOG tidak ditemukan. Isi kolom 'Waktu Aktivitas' manual."
fi

if [ ! -f "$ALERTS_JSON" ]; then
  echo "ERROR: $ALERTS_JSON tidak ditemukan! Jalankan di Wazuh Manager."
  exit 1
fi

echo ""
echo "--- Mengumpulkan data deteksi... ---"

NO=1

# === SSH BRUTE FORCE DETECTION ===
# Rule IDs yang relevan: 5712, 5720, 5763, 5551
# Baca dari brute_force_log.csv (kolom: no,waktu_mulai,waktu_selesai,ip,jumlah_attempt,threshold,spacing,status)
if [ -f "$BRUTE_LOG" ]; then
  # Skip header
  tail -n +2 "$BRUTE_LOG" | while IFS=, read -r no waktu_mulai waktu_selesai ip attempts threshold spacing status; do
    echo "  Mengolah percobaan brute #$no dari IP $ip..."

    # Cari alert di alerts.json untuk IP ini dan rule brute force
    ALERT_TIME=$(jq -r --arg ip "$ip" '
      select(.rule.id == "5712" or .rule.id == "5720" or .rule.id == "5763" or .rule.id == "5551") |
      select((.srcip == $ip) or (.data.srcip == $ip) or (.data.src_ip == $ip)) |
      .timestamp
    ' "$ALERTS_JSON" | tail -n 1 || echo "")

    if [ -n "$ALERT_TIME" ] && [ "$ALERT_TIME" != "null" ]; then
      DETECT="TP"
      echo "  -> ALERT DITEMUKAN: $ALERT_TIME (TP)"
    else
      DETECT="FN"
      ALERT_TIME="-" 
      echo "  -> TIDAK ADA ALERT (FN)"
    fi

    echo "$NO,SSH Brute Force,$waktu_mulai,$ALERT_TIME,$DETECT" >> "$OUTPUT"
    NO=$((NO + 1))
  done
fi

# === PORT SCANNING DETECTION ===
# Rule IDs yang relevan: 100102 (Nmap SYN), 100103 (portscan)
if [ -f "$PORTSCAN_LOG" ]; then
  # Skip header
  tail -n +2 "$PORTSCAN_LOG" | while IFS=, read -r no skenario waktu_mulai waktu_selesai command status; do
    echo "  Mengolah percobaan portscan #$no ($skenario)..."

    # Approximation: cari alert portscan yang muncul setelah waktu_mulai
    AWAL=$(date -d "$waktu_mulai" +%s 2>/dev/null || echo "0")
    AKHIR=$(date -d "$waktu_selesai" +%s 2>/dev/null || echo "0")

    ALERT_TIME=$(jq -r '
      select(.rule.id == "100102" or .rule.id == "100103") |
      .timestamp
    ' "$ALERTS_JSON" | tail -n 1 || echo "")

    if [ -n "$ALERT_TIME" ] && [ "$ALERT_TIME" != "null" ]; then
      DETECT="TP"
      echo "  -> ALERT DITEMUKAN: $ALERT_TIME (TP)"
    else
      DETECT="FN"
      ALERT_TIME="-"
      echo "  -> TIDAK ADA ALERT (FN)"
    fi

    AKTIVITAS="Port Scan $skenario"
    echo "$NO,$AKTIVITAS,$waktu_mulai,$ALERT_TIME,$DETECT" >> "$OUTPUT"
    NO=$((NO + 1))
  done
fi

echo ""
echo "=============================================="
echo "  SELESAI - Data deteksi disimpan di $OUTPUT"
echo "=============================================="
echo ""
echo "Ringkasan isi file:"
column -s, -t "$OUTPUT" 2>/dev/null || cat "$OUTPUT"