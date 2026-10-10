#!/bin/bash
# collect-notification.sh - Mengumpulkan Data Notifikasi (Webhook + FCM)
# Membandingkan timestamp alert di Wazuh dengan timestamp di database backend
#
# Output: /home/wazuh/results/notification_data.csv
# Kolom: No, Aktivitas, Waktu Alert Wazuh, Waktu Diterima Web, Waktu Diterima Android
#
# Jalankan di VPS Manager (103.30.194.158)
# Penggunaan: sudo bash collect-notification.sh
set -e

RESULTS_DIR="/home/wazuh/results"
mkdir -p "$RESULTS_DIR"
OUTPUT="$RESULTS_DIR/notification_data.csv"

ALERTS_JSON="/var/ossec/logs/alerts/alerts.json"
DB_USER="wazuh"
DB_NAME="wazuh_monitor"
DB_HOST="localhost"
DB_PORT="5432"

# Environment variable override untuk password DB
DB_PASSWORD="${DB_PASSWORD:-wazuh123}"

echo "=============================================="
echo "  COLLECT NOTIFICATION DATA"
echo "=============================================="
echo "Output: $OUTPUT"
echo ""

# Header CSV
cat > "$OUTPUT" << 'EOF'
No,Aktivitas,Waktu Alert Wazuh,Waktu Diterima Web,Waktu Diterima Android
EOF

if [ ! -f "$ALERTS_JSON" ]; then
  echo "ERROR: $ALERTS_JSON tidak ditemukan!"
  exit 1
fi

# Cek apakah backend PostgreSQL tersedia
if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
  echo "WARNING: PostgreSQL tidak dapat diakses. Menggunakan data dari alerts.json saja."
  echo "  (Web/Android timestamp tidak dapat direkam. Isi manual jika diperlukan)"
  DB_AVAILABLE=0
else
  DB_AVAILABLE=1
  echo "  PostgreSQL terhubung."
fi

NO=1

# Dapatkan semua alert level >= 7 dari alerts.json (yang dikirim ke webhook)
echo "  Memproses alert dari alerts.json..."

ALERT_IDS=$(jq -r 'select(.rule.level >= 7) | [.id, .rule.id, .timestamp, .rule.description] | @tsv' "$ALERTS_JSON" | tail -n 50)

if [ -z "$ALERT_IDS" ]; then
  echo "  Tidak ada alert level>=7 ditemukan."
else
  echo "  Ditemukan alert level>=7. Memproses..."
fi

echo "$ALERT_IDS" | while IFS=$'\t' read -r alert_id rule_id wazuh_ts rule_desc; do
  if [ -z "$alert_id" ]; then continue; fi

  ACTIVITY="Alert Rule $rule_id ($rule_desc)"

  echo "  Proses alert: $alert_id (rule $rule_id)..."

  WEB_TIME="-"
  ANDROID_TIME="-"

  if [ "$DB_AVAILABLE" = "1" ]; then
    # Query database untuk mendapat timestamp (kapan diterima web)
    WEB_TIME=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A -c \
      "SELECT TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') FROM alerts WHERE wazuh_alert_id = '$alert_id' LIMIT 1" 2>/dev/null || echo "-")

    if [ -z "$WEB_TIME" ] || [ "$WEB_TIME" = "-" ]; then
      WEB_TIME="-"
    fi

    # Android FCM delivery di-record di Firebase. Tidak ada kolom terpisah,
    # namun dapat di-estimate dari log aplikasi backend.
    # Cari log FCM di backend log (jika ada)
    if [ -f "/home/wazuh/backend/logs/combined.log" ]; then
      ANDROID_TIME=$(grep "$alert_id" /home/wazuh/backend/logs/combined.log 2>/dev/null | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}' | tail -n 1 || echo "-")
    fi

    if [ -f "/var/log/wazuh-monitor-backend.log" ]; then
      ANDROID_TIME=$(grep -i "FCM sent" /var/log/wazuh-monitor-backend.log 2>/dev/null | tail -n 1 | grep -oP '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}' | tail -n 1 || echo "-")
    fi
  fi

  echo "$NO,$ACTIVITY,$wazuh_ts,$WEB_TIME,$ANDROID_TIME" >> "$OUTPUT"
  NO=$((NO + 1))
done

echo ""
echo "=============================================="
echo "  SELESAI - Data notifikasi disimpan di $OUTPUT"
echo "=============================================="
echo ""
echo "CATATAN:"
echo "  - 'Waktu Diterima Android' diambil dari log backend / FCM delivery"
echo "  - Jika kosong ('-'), Anda perlu mencatat manual waktu notifikasi muncul"
echo "    di aplikasi Android"
echo ""
echo "Ringkasan isi file:"
column -s, -t "$OUTPUT" 2>/dev/null || cat "$OUTPUT"