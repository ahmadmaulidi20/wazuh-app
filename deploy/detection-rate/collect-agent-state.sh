#!/bin/bash
# collect-agent-state.sh — Snapshot ground truth & deteksi SI-SISI AGENT saat ini.
# Dipanggil dari mesin lokal via plink menuju VPS agent.
# Menulis ke keluar: count & ringkasan eve.json / fast.log / tcpdump SYN.
#
# Penggunaan: bash collect-agent-state.sh   (jalankan sebagai root di agent)

set -e
echo "=== TIMESTAMP ==="
date "+%FT%T%z"

echo "=== EVE.JSON ==="
sudo wc -l /var/log/suricata/eve.json 2>/dev/null || echo "eve.json not readable"
echo "--- event_type counts (alert/portscan) ---"
sudo grep -o '"event_type":"[a-z_]*"' /var/log/suricata/eve.json 2>/dev/null | sort | uniq -c || true

echo "=== FAST.LOG ==="
sudo wc -l /var/log/suricata/fast.log 2>/dev/null || echo "fast.log not readable"
echo "--- portscan/nmap entries ---"
sudo grep -iE 'portscan|nmap|scan' /var/log/suricata/fast.log 2>/dev/null | tail -20 || true

echo "=== TCPDUMP SYN capture (bila ada file) ==="
if [ -f /tmp/syn-capture.txt ]; then
  echo "--- count SYN entries ---"
  sudo wc -l /tmp/syn-capture.txt
  echo "--- source IP top ---"
  sudo awk '{print $2}' /tmp/syn-capture.txt | sort | uniq -c | sort -rn | head -20 || true
else
  echo "(no /tmp/syn-capture.txt)"
fi

echo "=== SURICATA ACTIVE ==="
systemctl is-active suricata 2>/dev/null || true

echo "DONE"