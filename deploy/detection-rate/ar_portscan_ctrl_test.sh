#!/bin/bash
# Controlled AR portscan block test (4.3.2) - single iteration.
# Swaps AR whitelist to placeholder, launches aggressive SYN flood from manager
# to agent (fires rule 100102 reliably), polls iptables up to POLL_MAX sec for the
# block rule, measures response time, then cleans up and restores whitelist.
SC="/var/ossec/active-response/bin/firewall-drop-suricata"
AL="/var/ossec/logs/active-responses.log"
TARGET_A="${1:-103.134.154.12}"
ATTACKER="103.30.194.158"
OLD="103.30.194.158"
PH="10.99.99.99"
POLL_MAX="${2:-90}"

sudo sed -i "s/${OLD}/${PH}/" "$SC"

# launch aggressive scan in background
START=$(date +%s.%N)
sudo bash -c "nmap -sS -p 1-100 --min-rate 300 --host-timeout 15s '$TARGET_A' >/dev/null 2>&1" &
PSCAN=$!

FOUND=""; RT=""
for i in $(seq 1 $((POLL_MAX*5))); do
  if sudo /sbin/iptables -S INPUT 2>/dev/null | grep -q " $ATTACKER "; then
    END=$(date +%s.%N); RT=$(echo "$END - $START" | bc -l); FOUND=1; break
  fi
  sleep 0.2
done
wait $PSCAN 2>/dev/null

if [ -n "$FOUND" ]; then
  RULE=$(sudo /sbin/iptables -S INPUT | grep " $ATTACKER ")
  echo "RESULT=BLOCKED rt=${RT}s"
  echo "RULE=$RULE"
else
  echo "RESULT=NOT-BLOCKED"
fi

# cleanup + restore
sudo /sbin/iptables -D INPUT -s "$ATTACKER" -j DROP 2>/dev/null
sudo sed -i "s/${PH}/${OLD}/" "$SC"
sudo /sbin/iptables -S INPUT | grep " $ATTACKER " || echo "clean"
grep "WHITELIST=" "$SC"
