#!/bin/bash
# Monitor real AR portscan (rule 100102) blocking events on the manager.
# For each new 'firewall-drop-suricata: Blocking <ip>' it:
#  1. confirms the iptables INPUT DROP rule is present
#  2. extracts the matching rule 100102 alert timestamp from ossec.log
#  3. records response time (block_log_time - alert_time) to CSV
AL="/var/ossec/logs/active-responses.log"
OL="/var/ossec/logs/ossec.log"
OUT="/tmp/ar_portscan_capture.csv"
[ -f "$OUT" ] || echo "datetime_block,attacker_ip,iptables_rule,alert_json_time,response_time_sec" > "$OUT"
if [ -f /tmp/ar_portscan_last.txt ]; then
  LAST=$(cat /tmp/ar_portscan_last.txt)
  [ -z "$LAST" ] || [ "$LAST" -lt 0 ] 2>/dev/null && LAST=0
else
  LAST=$(wc -l < "$AL")
fi
echo "monitor started at $(date '+%Y/%m/%d %H:%M:%S')" > /tmp/ar_portscan_monitor.log
while true; do
  # get current line count
  N=$(wc -l < "$AL")
  if [ "$N" -gt "$LAST" ]; then
    tail -n +$((LAST+1)) "$AL" > /tmp/ar_portscan_new.log
    LAST=$N
    while IFS= read -r line; do
      if echo "$line" | grep -q "firewall-drop-suricata: Blocking "; then
        ip=$(echo "$line" | grep -o "Blocking [0-9.]*" | awk '{print $2}')
        dt=$(echo "$line" | awk '{print $1" "$2}')
        # verify iptables rule
        if iptables -S INPUT | grep -q " $ip "; then ipt="yes"; else ipt="no"; fi
        # find alert json time for this ip in ossec.log (last 100102 event for that ip)
        alert_t=$(grep 'rule":{"level":10.*"id":"100102"' "$OL" 2>/dev/null | grep "src_ip.:.${ip}." | tail -1 | grep -o '"timestamp":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$alert_t" ]; then
          bsec=$(date -d "$dt" +%s 2>/dev/null)
          # alert_t like 2026-09-04T19:49:00.103+0700
          at=${alert_t%+*}
          asec=$(date -d "$at" +%s 2>/dev/null)
          rtime=""
          [ -n "$bsec" ] && [ -n "$asec" ] && rtime=$(echo "$bsec - $asec" | bc 2>/dev/null)
          echo "log-ok ip=$ip dt=$dt alert_t=$alert_t rtime=$rtime ipt=$ipt" >> /tmp/ar_portscan_monitor.log
          echo "$dt,$ip,$ipt,$alert_t,$rtime" >> "$OUT"
        else
          echo "no-alert-ref ip=$ip dt=$dt ipt=$ipt" >> /tmp/ar_portscan_monitor.log
          echo "$dt,$ip,$ipt,(none),-999" >> "$OUT"
        fi
      fi
    done < /tmp/ar_portscan_new.log
    LAST=$N
  fi
  sleep 2
done
