#!/bin/bash
# test-5712.sh — injeksi percobaan login "Invalid user" utk memicu rule 5712
# (brute force non-existent user) -> firewall-drop pada agent.
set -e
IP="${1:?Usage: $0 <source_ip> [jumlah]}"
N="${2:-10}"
for i in $(seq 1 "$N"); do
  pid=$((31000 + i))
  port=$((41000 + i))
  echo "$(date +'%b %e %H:%M:%S') serverclient sshd[${pid}]: Invalid user admin from ${IP} port ${port}" >> /var/log/auth.log
done
echo "injected ${N} 'Invalid user' lines for ${IP}"
