#!/bin/bash
# collect-prevention.sh - Mengumpulkan Data Pencegahan (Active Response + Firewall)
# Memeriksa status block melalui iptables dan active-responses.log
#
# Output: /home/wazuh/results/prevention_data.csv
# Kolom: No, Aktivitas, IP Attacker, IP Pengguna, Status Block, Status Akses Pengguna
#
# Penggunaan: sudo bash collect-prevention.sh
set -e

RESULTS_DIR="/home/wazuh/results"
mkdir -p "$RESULTS_DIR"
OUTPUT="$RESULTS_DIR/prevention_data.csv"

BRUTE_LOG="$RESULTS_DIR/brute_force_log.csv"
PORTSCAN_LOG="$RESULTS_DIR/portscan_log.csv"
AR_LOG="/var/ossec/logs/active-responses.log"

# IP Pengguna yang sah (mestinya whitelist/tidak diblokir)
USER_IPS=(
  "116.206.32.57"   # IP Administrator (whitelist)
  "103.30.194.158"  # Wazuh Manager
  "103.134.154.12"  # Server Klien (agent)
)

echo "=============================================="
echo "  COLLECT PREVENTION DATA"
echo "=============================================="
echo "Output: $OUTPUT"
echo ""

# Header CSV
cat > "$OUTPUT" << 'EOF'
No,Aktivitas,IP Attacker,IP Pengguna,Status Block,Status Akses Pengguna
EOF

NO=1

check_iptables_block() {
  local ip="$1"
  if sudo iptables -L INPUT -n 2>/dev/null | grep -q "DROP.*$ip" || \
     sudo iptables -L INPUT -n 2>/dev/null | grep -q "$ip"; then
    echo "Berhasil"
  else
    echo "Gagal/Tidak Ada"
  fi
}

check_ar_log() {
  local ip="$1"
  if [ -f "$AR_LOG" ]; then
    count=$(grep -c "Blocking $ip" "$AR_LOG" 2>/dev/null || echo "0")
    if [ "$count" -gt 0 ]; then
      echo "Berhasil"
    else
      echo "Tidak Tercatat"
    fi
  else
    echo "Log tidak ada"
  fi
}

echo "--- SSH Brute Force Prevention ---"
if [ -f "$BRUTE_LOG" ]; then
  tail -n +2 "$BRUTE_LOG" | while IFS=, read -r no waktu_mulai waktu_selesai ip attempts threshold spacing status; do
    echo "  Memeriksa pencegahan brute #$no dari IP $ip..."

    # Cek apakah IP attacker di-block
    AR_STATUS=$(check_ar_log "$ip")
    IPTABLES_STATUS=$(check_iptables_block "$ip")

    if [ "$AR_STATUS" = "Berhasil" ] && [ "$IPTABLES_STATUS" = "Berhasil" ]; then
      BLOCK="Berhasil"
    else
      BLOCK="Tidak Ada"
    fi

    # Cek akses IP pengguna (harus tetap bisa akses)
    USER_ACCESS="Normal"
    for user_ip in "${USER_IPS[@]}"; do
      if sudo iptables -L INPUT -n 2>/dev/null | grep -q "$user_ip"; then
        USER_ACCESS="TERBLOKIR (anaomali!)"
        echo "  WARNING: IP Pengguna $user_ip terblokir!"
      fi
    done

    echo "$NO,SSH Brute Force,$ip,116.206.32.57,$BLOCK,$USER_ACCESS" >> "$OUTPUT"
    NO=$((NO + 1))
  done
fi

echo ""
echo "--- Port Scanning Prevention ---"
if [ -f "$PORTSCAN_LOG" ]; then
  tail -n +2 "$PORTSCAN_LOG" | while IFS=, read -r no skenario waktu_mulai waktu_selesai command status; do
    echo "  Memeriksa pencegahan portscan #$no ($skenario)..."

    # Untuk port scan, attacker IP tidak diketahui secara pasti dari log.
    # Berasumsi attacker IP diambil dari alert terakhir di active-responses.log
    LAST_BLOCKED=$(grep "Blocking" "$AR_LOG" 2>/dev/null | tail -n 1 | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "N/A")

    if [ "$LAST_BLOCKED" != "N/A" ]; then
      BLOCK="Berhasil"
      ATTACKER_IP="$LAST_BLOCKED"
    else
      BLOCK="Tidak Ada"
      ATTACKER_IP="N/A"
    fi

    USER_ACCESS="Normal"
    for user_ip in "${USER_IPS[@]}"; do
      if sudo iptables -L INPUT -n 2>/dev/null | grep -q "$user_ip"; then
        USER_ACCESS="TERBLOKIR (anasomal!)"
      fi
    done

    echo "$NO,Port Scan $skenario,$ATTACKER_IP,116.206.32.57,$BLOCK,$USER_ACCESS" >> "$OUTPUT"
    NO=$((NO + 1))
  done
fi

echo ""
echo "=============================================="
echo "  SELESAI - Data pencegahan disimpan di $OUTPUT"
echo "=============================================="
echo ""
echo "Ringkasan isi file:"
column -s, -t "$OUTPUT" 2>/dev/null || cat "$OUTPUT"