#!/bin/bash
# ============================================================
# BACKUP Config VPS Wazuh AGENT (VM kampus: agent + Suricata + active response)
# Jalankan dari MESIN LOKAL (bukan di server) -- menarik konfigurasi via SSH.
# Output: backups/agent/<timestamp>/  (folder ini DI-IGNORE dari git public)
#
# Host agent: 103.134.154.12 (internal 10.228.87.3)
# ============================================================
set -e

SSH_HOST="${SSH_HOST:-root@103.134.154.12}"
SSH_OPTS="${SSH_OPTS:--o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new}"

TS=$(date +%Y%m%d-%H%M%S)
OUT_DIR="backups/agent/$TS"
mkdir -p "$OUT_DIR"

echo "=== Backup config VPS Wazuh AGENT ($SSH_HOST) -> $OUT_DIR ==="

# --- Agent core ---
for f in /var/ossec/etc/ossec.conf /var/ossec/etc/client.keys /var/ossec/etc/local_internal_options.conf; do
    if scp $SSH_OPTS -q "$SSH_HOST:$f" "$OUT_DIR/" 2>/dev/null; then
        echo "  OK  $f"
    else
        echo "  --  $f (tidak ada / gagal)"
    fi
done

# --- Suricata ---
scp $SSH_OPTS -q "$SSH_HOST:/etc/suricata/suricata.yaml" "$OUT_DIR/suricata.yaml" 2>/dev/null && echo "  OK  suricata.yaml" || echo "  --  suricata.yaml"
scp $SSH_OPTS -q "$SSH_HOST:/etc/suricata/rules/local.rules" "$OUT_DIR/suricata-local.rules" 2>/dev/null && echo "  OK  suricata-local.rules" || echo "  --  suricata-local.rules"
scp $SSH_OPTS -q "$SSH_HOST:/var/lib/suricata/rules/local.rules" "$OUT_DIR/suricata-rules-local.rules" 2>/dev/null && echo "  OK  suricata-rules-local.rules" || echo "  --  suricata-rules-local.rules"

# --- Active response custom + watchdog ---
mkdir -p "$OUT_DIR/active-response"
scp $SSH_OPTS -q "$SSH_HOST:/var/ossec/active-response/bin/firewall-drop-suricata" "$OUT_DIR/active-response/" 2>/dev/null && echo "  OK  active-response/firewall-drop-suricata" || echo "  --  active-response/firewall-drop-suricata"
scp $SSH_OPTS -q "$SSH_HOST:/usr/local/bin/wazuh-agent-watchdog.sh" "$OUT_DIR/wazuh-agent-watchdog.sh" 2>/dev/null && echo "  OK  wazuh-agent-watchdog.sh" || echo "  --  wazuh-agent-watchdog.sh"
scp $SSH_OPTS -q "$SSH_HOST:/usr/local/bin/wazuh-agent-watchdog.timer" "$OUT_DIR/wazuh-agent-watchdog.timer" 2>/dev/null && echo "  OK  wazuh-agent-watchdog.timer" || echo "  --  watchdog timer"

echo ""
echo "=== Ringkasan ==="
du -sh "$OUT_DIR"
echo "Config disimpan di: $OUT_DIR"
echo "CATATAN: backups/ DI-IGNORE dari git public. Jangan commit ke GitHub."
echo "=== DONE ==="
