#!/bin/bash
# brute_realistic.sh - Mix above-threshold and below-threshold brute force
# 7 tests with 10 attempts (TP) + 3 tests with 5 attempts (FN)
# Below-threshold tests won't trigger composite rule 5763 (freq=8)
set -e

echo "=== Brute Force Realistic Test ==="
echo "Time: $(date)"
echo ""

# Test 1-7: 10 attempts each (above threshold=8, should trigger rule 5763)
for i in 1 2 3 4 5 6 7; do
  IP="198.51.100.$i"
  N=10
  echo "Test $i: $IP ($N attempts) - EXPECTED TP"
  for j in $(seq 1 $N); do
    pid=$((30000 + j))
    port=$((40000 + j))
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log
  done
  echo "  Injected $N lines"
  sleep 10
done

# Test 8-10: 5 attempts each (below threshold=8, should NOT trigger rule 5763)
for i in 8 9 10; do
  IP="198.51.100.$i"
  N=5
  echo "Test $i: $IP ($N attempts) - EXPECTED FN (below threshold)"
  for j in $(seq 1 $N); do
    pid=$((30000 + j))
    port=$((40000 + j))
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log
  done
  echo "  Injected $N lines"
  sleep 10
done

echo ""
echo "=== All 10 tests completed ==="
