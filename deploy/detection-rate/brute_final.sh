#!/bin/bash
# brute_final.sh - Final brute force experiment with proper spacing
# 120s between tests to reset frequency counter per-IP
# 7 tests with 10 attempts (TP) + 3 tests with 5 attempts (FN)
set -e

echo "=== Final Brute Force Experiment ==="
echo "Time: $(date)"
echo "7 tests x 10 attempts (above threshold=8) -> TP expected"
echo "3 tests x 5 attempts (below threshold=8) -> FN expected"
echo "120s spacing between tests"
echo ""

# Above-threshold tests (10 attempts -> rule 5763 should fire)
for i in 1 2 3 4 5 6 7; do
  IP="198.51.200.$i"
  N=10
  echo "Test $i/10 [ABOVE-THRESHOLD]: $IP ($N attempts) -> TP expected"
  for j in $(seq 1 $N); do
    pid=$((40000 + j))
    port=$((50000 + j))
    echo "$(date +'%b %e %H:%M:%S') server sshd[$pid]: Failed password for root from $IP port $port ssh2" >> /var/log/auth.log
  done
  echo "  Injected $N lines at $(date +'%H:%M:%S')"
  echo "  Waiting 120s for frequency window to reset..."
  sleep 120
done

# Below-threshold tests (5 attempts -> rule 5763 should NOT fire)
for i in 8 9 10; do
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
    echo "  Waiting 120s..."
    sleep 120
  fi
done

echo ""
echo "=== All 10 tests completed at $(date) ==="
