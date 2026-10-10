#!/bin/bash
# brute_last2.sh - Tests 9 and 10 only
set -e

for i in 9 10; do
  IP="198.51.200.$i"
  N=5
  echo "Test $i/10 [BELOW-THRESHOLD]: $IP ($N attempts) -> FN expected"
  for j in $(seq 1 $N); do
    pid=$((40000 + j))
    port=$((50000 + j))
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log
  done
  echo "  Injected $N lines at $(date +'%H:%M:%S')"
  if [ "$i" -lt 10 ]; then
    sleep 120
  fi
done

echo "=== Tests 9-10 completed ==="
