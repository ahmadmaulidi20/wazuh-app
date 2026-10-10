#!/bin/bash
# Bounded foreground capture of real AR portscan (rule 100102) blocking events.
# Polls active-responses.log for new 'firewall-drop-suricata: Blocking <ip>',
# verifies iptables DROP rule, correlates alert timestamp, writes CSV.
# Run: bash /tmp/ar_portscan_capture.sh <minutes>
AL="/var/ossec/logs/active-responses.log"
OL="/var/ossec/logs/ossec.log"
LAST="$1"
DUR="${2:-12}"   # default 12 minutes
OUT="/tmp/ar_portscan_capture.csv"
echo "datetime_block,attacker_ip,iptables_rule,alert_time,response_time_sec" > "$OUT"
END=$(( $(date +%s) + DUR*60 ))
echo "capture started $(date '+%Y/%m/%d %H:%M:%S') until $(date -d @$END '+%H:%M:%S')" 
COUNT=0
while [ $(date +%s) -lt $END ]; do
  N=$(wc -l < "$AL")
  if [ "$N" -gt "$LAST" ]; then
    while IFS= read -r line; do
      if echo "$line" | grep -q "firewall-drop-suricata: Blocking "; then
        ip=$(echo "$line" | sed -n 's/.*Blocking \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')
        dt=$(echo "$line" | awk '{print $1" "$2}')
        if iptables -S INPUT | grep -q " $ip "; then ipt="yes"; else ipt="no"; fi
        alert_t=$(grep '"src_ip":"'$ip'"' "$OL" | tail -1 | grep -o '"timestamp":"[^"]*"' | head -1 | cut -d'"' -f4)
        rtime=""
        if [ -n "$alert_t" ]; then
          bsec=$(date -d "$dt" +%s 2>/dev/null)
          at=${alert_t%+*}
          asec=$(date -d "$at" +%s 2>/dev/null)
          [ -n "$bsec" ] && [ -n "$asec" ] && rtime=$(echo "$bsec - $asec" | bc -l 2>/dev/null)
        fi
        echo "$dt,$ip,$ipt,$alert_t,$rtime" >> "$OUT"
        COUNT=$((COUNT+1))
        echo "[$COUNT] blocked $ip dt=$dt rtime=${rtime}s ipt=$ipt"
      fi
    done < <(tail -n +$((LAST+1)) "$AL")
    LAST=$N
  fi
  sleep 2
done
echo "=== TOTAL captured: $COUNT ==="
echo "=== CSV ==="
cat "$OUT"
