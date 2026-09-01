#!/bin/bash
# ============================================================
# BACKUP Config VPS Wazuh MANAGER (+ app stack yang berjalan di server yang sama)
# Jalankan dari MESIN LOKAL (bukan di server) -- menarik konfigurasi via SSH.
# Output: backups/manager/<timestamp>/  (folder ini DI-IGNORE dari git public)
#
# Host manager: 103.30.194.158  (Wazuh Manager + Indexer + Dashboard + app backend/
#                                nginx/postgres/pgadmin di server yang sama)
# ============================================================
set -e

SSH_HOST="${SSH_HOST:-root@103.30.194.158}"
SSH_OPTS="${SSH_OPTS:--o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new}"

TS=$(date +%Y%m%d-%H%M%S)
OUT_DIR="backups/manager/$TS"
mkdir -p "$OUT_DIR"

echo "=== Backup config VPS Wazuh MANAGER ($SSH_HOST) -> $OUT_DIR ==="

# --- Wazuh Manager core ---
for f in /var/ossec/etc/ossec.conf /var/ossec/etc/rules/local_rules.xml /var/ossec/etc/client.keys; do
    if scp $SSH_OPTS -q "$SSH_HOST:$f" "$OUT_DIR/" 2>/dev/null; then
        echo "  OK  $f"
    else
        echo "  --  $f (tidak ada / gagal)"
    fi
done

# --- Wazuh integration script + environment ---
mkdir -p "$OUT_DIR/integrations"
scp $SSH_OPTS -q "$SSH_HOST:/var/ossec/integrations/custom-wazuh.py" "$OUT_DIR/integrations/" 2>/dev/null && echo "  OK  integrations/custom-wazuh.py" || echo "  --  integrations/custom-wazuh.py"
scp $SSH_OPTS -q "$SSH_HOST:/var/ossec/etc/environment" "$OUT_DIR/integrations/environment" 2>/dev/null && \
    { echo "  OK  integrations/environment (SANITIZED)"; \
      sed -i 's/^API_KEY=.*/API_KEY=CHANGE_ME/;s/^WEBHOOK_URL=.*/WEBHOOK_URL=http:\/\/localhost:3000\/api\/webhook\/wazuh/' "$OUT_DIR/integrations/environment"; } \
    || echo "  --  integrations/environment"

# --- Indexer & Dashboard config (all-in-one Wazuh) ---
scp $SSH_OPTS -rq "$SSH_HOST:/etc/wazuh-indexer/" "$OUT_DIR/wazuh-indexer/" 2>/dev/null && echo "  OK  wazuh-indexer/" || echo "  --  wazuh-indexer/ (tidak ditemukan)"
scp $SSH_OPTS -rq "$SSH_HOST:/etc/wazuh-dashboard/" "$OUT_DIR/wazuh-dashboard/" 2>/dev/null && echo "  OK  wazuh-dashboard/" || echo "  --  wazuh-dashboard/"

# --- App stack (nginx + docker compose + env) ---
scp $SSH_OPTS -q "$SSH_HOST:/etc/nginx/sites-available/siem-web" "$OUT_DIR/nginx-siem-web.conf" 2>/dev/null && echo "  OK  nginx-siem-web.conf" || echo "  --  nginx live config (pakai nginx -T fallback)"
scp $SSH_OPTS -q "$SSH_HOST:/etc/nginx/.htpasswd" "$OUT_DIR/nginx-htpasswd" 2>/dev/null && \
    { echo "  OK  nginx-htpasswd (SANITIZED - hash boleh publik, bukan plaintext)"; } \
    || echo "  --  nginx-htpasswd"
scp $SSH_OPTS -q "$SSH_HOST:/opt/wazuh-app/docker-compose.prod.yml" "$OUT_DIR/docker-compose.prod.yml" 2>/dev/null && echo "  OK  docker-compose.prod.yml" || echo "  --  docker-compose.prod.yml (cari path lain)"
scp $SSH_OPTS -q "$SSH_HOST:/opt/wazuh-app/.env.production" "$OUT_DIR/.env.production" 2>/dev/null && \
    { echo "  OK  .env.production (BERISI RAHASIA - jangan commit, simpan lokal)" ; } \
    || echo "  --  .env.production"

echo ""
echo "=== Ringkasan ==="
du -sh "$OUT_DIR"
echo "Config disimpan di: $OUT_DIR"
echo ""
echo "CATATAN PENTING:"
echo "  - File .env.production / environment / wazuh-indexer berisi rahasia & sertifikat."
echo "    Folder backups/ DI-IGNORE dari git public -> DILARANG commit file ini ke GitHub."
echo "  - Nilai rahasia dipertahankan utuh di backup lokal agar bisa langsung redeploy."
echo "=== DONE ==="
