#!/bin/bash
# brute_inject.sh
# Inject failed login lines to trigger Wazuh brute force detection
# Usage: sudo bash brute_inject.sh <source_ip> [count]
set -e

IP="${1:?Usage: sudo bash brute_inject.sh <source_ip> [count]}"
N="${2:-10}"

for i in $(seq 1 "$N"); do
  pid=$((30000 + i))
  port=$((40000 + i))
  echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log
done

echo "Injected ${N} failed-login lines for ${IP} into /var/log/auth.log"
