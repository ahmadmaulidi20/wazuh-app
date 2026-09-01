#!/bin/bash
# ar-proof-job.sh — bukti sisi server bahwa active response berjalan.
# Dipanggil background (nohup) tepat setelah injeksi login gagal:
#   sudo bash -c 'nohup bash ar-proof-job.sh <source_ip> >/dev/null 2>&1 &'
# Menulis hasil ke /home/wazuh/ar-proof.txt setelah 15 detik (saat rule aktif).
set -e

IP="${1:?Usage: bash ar-proof-job.sh <source_ip>}"
sleep 15

{
  echo "=== waktu ==="
  date '+%F %H:%M:%S %Z'
  echo
  echo "=== perintah active-response untuk ${IP} di active-responses.log ==="
  grep "${IP}" /var/ossec/logs/active-responses.log | grep -oE '"command":"[a-z]+"' | sort | uniq -c
  echo
  echo "=== iptables ==="
  iptables -S | grep "${IP}" || echo "(tidak ada rule iptables)"
  echo
  echo "=== nft ruleset ==="
  nft list ruleset 2>/dev/null | grep "${IP}" || echo "(tidak ada rule nft)"
} > /home/wazuh/ar-proof.txt 2>&1
