#!/bin/bash
# brute_all.sh - Run 10 brute force tests with different IPs
# Usage: sudo bash brute_all.sh
set -e

IPS="198.51.100.1 198.51.100.2 198.51.100.3 198.51.100.4 198.51.100.5 198.51.100.6 198.51.100.7 198.51.100.8 198.51.100.9 198.51.100.10"
N=10

test_num=0
for IP in $IPS; do
  test_num=$((test_num + 1))
  echo "=== Test $test_num/10: $IP ==="
  for i in $(seq 1 $N); do
    pid=$((30000 + i))
    port=$((40000 + i))
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log
  done
  echo "  Injected $N lines for $IP"
  sleep 5
done

echo "=== All 10 tests completed ==="
