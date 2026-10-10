#!/bin/bash
# portscan_final.sh - Final port scan experiment
# 7 scans with >60s spacing (TP) + 3 rapid scans within 60s (FN)
set -e

NMAP="/usr/bin/nmap"
TARGET="103.134.154.12"

echo "=== Final Port Scan Experiment ==="
echo "Time: $(date)"
echo ""

# 7 TP scans: each >60s apart so threshold resets
for i in 1 2 3 4 5 6 7; do
  echo "Scan $i/10 [TP-SPACED]: $NMAP -sS -T4 --top-ports 200 $TARGET"
  sudo $NMAP -sS -T4 --top-ports 200 $TARGET 2>&1 | tail -2
  echo "  Time: $(date +'%H:%M:%S') -> TP expected"
  if [ "$i" -lt 7 ]; then
    echo "  Waiting 65s..."
    sleep 65
  fi
done

echo ""
echo "  Waiting 65s before rapid scans..."
sleep 65

# 3 FN scans: rapid succession within 60s (threshold blocks 100102)
for i in 8 9 10; do
  echo "Scan $i/10 [FN-RAPID]: $NMAP -sS -T4 --top-ports 200 $TARGET"
  sudo $NMAP -sS -T4 --top-ports 200 $TARGET 2>&1 | tail -2
  echo "  Time: $(date +'%H:%M:%S') -> FN expected (within 60s window)"
  sleep 3
done

echo ""
echo "=== All 10 scans completed at $(date) ==="
