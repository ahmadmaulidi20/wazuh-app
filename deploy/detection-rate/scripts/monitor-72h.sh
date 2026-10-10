#!/bin/bash
# monitor-72h.sh - Monitoring 3x24 jam (72 jam) aktivitas sistem
# Mencatat aktivitas jaringan, alert, active response, dan notifikasi
#
# Output: /home/wazuh/results/monitoring_72h.csv
# Kolom: No, Waktu, IP Sumber, Aktivitas, Alert, Active Response, Status Block, Notifikasi
#
# Jalankan di VPS Manager (103.30.194.158)
# Penggunaan: sudo bash monitor-72h.sh [durasi_jam]
# Default durasi: 72 jam
set -e

RESULTS_DIR="/home/wazuh/results"
mkdir -p "$RESULTS_DIR"
OUTPUT="$RESULTS_DIR/monitoring_72h.csv"
DURATION_HOURS="${1:-72}"
INTERVAL_MIN=5
TOTAL_ITERATIONS=$((DURATION_HOURS * 60 / INTERVAL_MIN))

ALERTS_JSON="/var/ossec/logs/alerts/alerts.json"
AR_LOG="/var/ossec/logs/active-responses.log"
STDOUT_LOG="$RESULTS_DIR/monitor_72h_stdout.log"

START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
END_TIME=$(date -d "$START_TIME +$DURATION_HOURS hours" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$DURATION_HOURS jam lagi")

echo "=============================================="
echo "  MONITORING 3x24 JAM (72 JAM)"
echo "=============================================="
echo "  Mulai:   $START_TIME"
echo "  Berakhir: $END_TIME (setelah $DURATION_HOURS jam)"
echo "  Interval: $INTERVAL_MIN menit"
echo "  Iterasi:  $TOTAL_ITERATIONS"
echo "  Output:   $OUTPUT"
echo ""
echo "  Jalankan monitor di background:"
echo "  nohup sudo bash monitor-72h.sh $DURATION_HOURS > $STDOUT_LOG 2>&1 &"
echo ""

# Header CSV
cat > "$OUTPUT" << 'EOF'
No,Waktu,IP Sumber,Aktivitas,Alert,Active Response,Status Block,Notifikasi
EOF

get_alert_count() {
  local rule="$1"
  local since="$2"
  if [ -f "$ALERTS_JSON" ]; then
    count=$(jq -r --arg rule "$rule" 'select(.rule.id == $rule) | .timestamp' "$ALERTS_JSON" 2>/dev/null | tail -n 50 | wc -l)
    echo "$count"
  else
    echo "0"
  fi
}

get_last_alert() {
  local rule="$1"
  if [ -f "$ALERTS_JSON" ]; then
    last=$(jq -r --arg rule "$rule" 'select(.rule.id == $rule) | .timestamp' "$ALERTS_JSON" 2>/dev/null | tail -n 1)
    echo "$last"
  else
    echo "-"
  fi
}

get_ar_count() {
  local since="$1"
  if [ -f "$AR_LOG" ]; then
    count=$(grep -c "Blocking" "$AR_LOG" 2>/dev/null || echo "0")
    echo "$count"
  else
    echo "0"
  fi
}

get_iptables_block_count() {
  count=$(sudo iptables -L INPUT -n 2>/dev/null | grep -c "DROP" || echo "0")
  echo "$count"
}

get_source_ips() {
  if [ -f "$ALERTS_JSON" ]; then
    ip=$(jq -r 'select(.srcip != null) | .srcip' "$ALERTS_JSON" 2>/dev/null | sort -u | tail -n 5 | tr '\n' ' ')
    echo "$ip"
  else
    echo "-"
  fi
}

PROGRESS=0

for ((i = 1; i <= TOTAL_ITERATIONS; i++)); do
  NOW=$(date '+%Y-%m-%d %H:%M:%S')
  PROGRESS=$((i * 100 / TOTAL_ITERATIONS))

  # Collect data snapshot
  BRUTE_LAST=$(get_last_alert "5763")
  BRUTE_CNT=$(get_alert_count "5763")
  SCAN_LAST=$(get_last_alert "100102")
  SCAN_CNT=$(get_alert_count "100102")
  AR_CNT=$(get_ar_count "")
  IPT_C=$(get_iptables_block_count)
  SRC_IPS=$(get_source_ips)

  # Simplify activity description
  ACTIVITY="-"
  ALERT_STATUS="Tidak Ada"
  AR_STATUS="Tidak Ada"
  NOTIF_STATUS="-"

  if [ "$BRUTE_CNT" != "0" ] && [ "$BRUTE_CNT" != "" ]; then
    ACTIVITY="SSH Brute Force"
    ALERT_STATUS="Level 10 ($BRUTE_CNT)"
    NOTIF_STATUS="Terkirim"
  elif [ "$SCAN_CNT" != "0" ] && [ "$SCAN_CNT" != "" ]; then
    ACTIVITY="Port Scanning"
    ALERT_STATUS="Level 10 ($SCAN_CNT)"
    NOTIF_STATUS="Terkirim"
  fi

  if [ "$AR_CNT" != "0" ]; then
    AR_STATUS="Aktif ($AR_CNT block)"
  fi

  BLOCK_STATUS="Normal"
  if [ "$IPT_C" != "0" ]; then
    BLOCK_STATUS="Aktif ($IPT_C rule DROP)"
  fi

  # Write to CSV
  echo "$i,$NOW,$SRC_IPS,$ACTIVITY,$ALERT_STATUS,$AR_STATUS,$BLOCK_STATUS,$NOTIF_STATUS" >> "$OUTPUT"

  # Progress status
  if [ $((i % 12)) -eq 0 ]; then
    echo "[$NOW] Progress: $PROGRESS% | Iterasi $i/$TOTAL_ITERATIONS | Active Responses: $AR_CNT | DROP rules: $IPT_C"
  fi

  # Sleep until next interval
  sleep $((INTERVAL_MIN * 60))
done

END_TIME=$(date '+%Y-%m-%d %H:%M:%S')
echo ""
echo "=============================================="
echo "  MONITORING SELESAI"
echo "  Mulai:    $START_TIME"
echo "  Berakhir: $END_TIME"
echo "  Total iterasi: $TOTAL_ITERATIONS"
echo "  Output:   $OUTPUT"
echo "=============================================="