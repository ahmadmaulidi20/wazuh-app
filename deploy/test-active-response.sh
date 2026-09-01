#!/bin/bash
# test-active-response.sh
# Menyuntikkan N percobaan login SSH gagal ke /var/log/auth.log untuk memicu
# active response Wazuh (rule 5763 "sshd: brute force" -> firewall-drop).
#
# Penggunaan (harus root/sudo):
#   sudo bash test-active-response.sh <source_ip> [jumlah=10]
#
# Setelah ~2-10 detik, rule firewall-drop "add" akan aktif untuk <source_ip>
# (default timeout 600 detik, lalu auto-delete). IP uji idealnya pakai IP
# test dokumentasi (mis. 203.0.113.x) ATAU IP client yang memang ingin diuji.
set -e

IP="${1:?Usage: sudo bash test-active-response.sh <source_ip> [jumlah]}"
N="${2:-10}"

for i in $(seq 1 "$N"); do
  pid=$((30000 + i))
  port=$((40000 + i))
  echo "$(date +'%b %e %H:%M:%S') wazuh sshd[${pid}]: Failed password for root from ${IP} port ${port} ssh2" >> /var/log/auth.log
done

echo "injected ${N} failed-login lines for ${IP} into /var/log/auth.log"
