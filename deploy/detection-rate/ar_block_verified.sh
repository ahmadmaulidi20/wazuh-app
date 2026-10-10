#!/bin/bash
# Batch AR block-verification tests (4.3.2) - 12 distinct attacker IPs.
# Proves the firewall-drop-suricata active-response script blocks each source:
#   - runs the script (as wazuh execd does) for a distinct attacker IP
#   - confirms the iptables INPUT DROP rule actually lands
#   - measures response time (poll iptables every 0.2s)
#   - cleans up the rule after each test
SC="/var/ossec/active-response/bin/firewall-drop-suricata"
AL="/var/ossec/logs/active-responses.log"
OUT="/var/ossec/ar_block_verified.csv"
echo "test_no,attacker_ip,iptables_rule_landed,response_time_sec,evidence_log" > "$OUT"

IPs=(
  "198.51.100.11" "198.51.100.12" "198.51.100.13" "198.51.100.14"
  "198.51.100.15" "198.51.100.16" "198.51.100.17" "198.51.100.18"
  "198.51.100.19" "198.51.100.20" "198.18.0.31"   "198.18.0.32"
)

i=0
for ip in "${IPs[@]}"; do
  i=$((i+1))
  MSG='{"version":1,"origin":{"name":"node01","module":"wazuh-execd"},"command":"add","parameters":{"extra_args":[],"alert":{"rule":{"id":"100102","level":10},"agent":{"name":"srv_kampusmu"},"data":{"src_ip":"'$ip'","dest_ip":"10.228.87.3"}}}}'
  START=$(date +%s.%N)
  sudo "$SC" "$MSG" >/dev/null 2>&1
  FOUND=""; RT=""
  for p in $(seq 1 25); do
    if /sbin/iptables -S INPUT 2>/dev/null | grep -q "$ip/32"; then
      END=$(date +%s.%N); RT=$(echo "$END - $START" | bc -l); FOUND=1; break
    fi
    sleep 0.2
  done
  RULE_LANDED=$([ -n "$FOUND" ] && echo yes || echo no)
  LOGLINE=$(tail -5 "$AL" | grep "Blocking $ip" | tail -1)
  echo "$i,$ip,$RULE_LANDED,$RT,$LOGLINE" >> "$OUT"
  # cleanup for next iteration
  /sbin/iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
  sleep 0.3
done

echo "=== RESULTS ==="
cat "$OUT"
echo "=== verify all cleaned ==="
/sbin/iptables -S INPUT | grep "198.51.100\|198.18.0" || echo "all rules removed (clean)"
