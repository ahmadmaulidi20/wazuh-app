#!/bin/bash
# start-sensor-tcpdump.sh — Aktifkan tcpdump SYN di agent sebagai ground-truth.
# Menangkap semua SYN yang masuk ke ens3 selama <duration> detik (background).
# Output: /tmp/syn-capture.txt (baris SYN), /tmp/syn-capture.err.
# Jalankan sebagai root.
DURATION="${1:-90}"
IFACE="ens3"
sudo rm -f /tmp/syn-capture.txt /tmp/syn-capture.err
sudo nohup timeout "$DURATION" tcpdump -i "$IFACE" -nn -l 'tcp[tcpflags] & (tcp-syn) != 0 and (tcp[tcpflags] & (tcp-ack)) == 0' > /tmp/syn-capture.txt 2>/tmp/syn-capture.err &
echo "sensor started ($DURATION s) pid $!"
date "+%FT%T%z"