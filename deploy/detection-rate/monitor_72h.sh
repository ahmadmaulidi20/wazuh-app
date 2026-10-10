#!/bin/bash
# monitor_72h.sh - Continuous monitoring for 72 hours
# Logs new alerts every 5 minutes to /var/log/monitor_72h.log
# Run on Wazuh Manager: nohup bash monitor_72h.sh &
set -e

LOGFILE="/var/log/monitor_72h.log"
ALERTS="/var/ossec/logs/alerts/alerts.json"
INTERVAL=300  # 5 minutes

echo "=== 72H MONITORING STARTED at $(date) ===" >> "$LOGFILE"
echo "Baseline alert count: $(wc -l < $ALERTS)" >> "$LOGFILE"
echo "" >> "$LOGFILE"

last_count=$(wc -l < "$ALERTS")

for i in $(seq 1 864); do
  sleep $INTERVAL
  current_count=$(wc -l < "$ALERTS")
  new_alerts=$((current_count - last_count))
  timestamp=$(date +'%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] Total: $current_count | New since last: $new_alerts" >> "$LOGFILE"

  if [ "$new_alerts" -gt 0 ]; then
    echo "  --- NEW ALERTS ---" >> "$LOGFILE"
    sudo tail -n "$new_alerts" "$ALERTS" | while IFS= read -r line; do
      rid=$(echo "$line" | grep -o '"id":"[0-9]*"' | head -1 | tr -d '"id":')
      lvl=$(echo "$line" | grep -o '"level":[0-9]*' | head -1 | tr -d '"level":')
      src=$(echo "$line" | grep -o '"src_ip":"[^"]*"' | head -1 | tr -d '"src_ip":')
      desc=$(echo "$line" | grep -o '"description":"[^"]*"' | head -1 | tr -d '"description":')
      echo "    rule=$rid level=$lvl src=$src desc=$desc" >> "$LOGFILE"
    done
    echo "  --- END ---" >> "$LOGFILE"
  fi

  last_count=$current_count
done

echo "=== 72H MONITORING COMPLETED at $(date) ===" >> "$LOGFILE"
