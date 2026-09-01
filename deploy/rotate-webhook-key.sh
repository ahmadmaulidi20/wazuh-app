#!/bin/bash
# ============================================================
# ROTASI API Key webhook Wazuh -> backend.
# Jalankan DI VPS Manager (host yang menjalankan Wazuh Manager + stack docker app).
#
# Mengganti WEBHOOK_API_KEY di semua lokasi secara sinkron:
#   1. deploy/.env.production  (stack docker backend)
#   2. /var/ossec/etc/environment  (API_KEY untuk integrasi)
#   3. /var/ossec/etc/ossec.conf   (<integration><api_key>)
# lalu me-restart backend container & Wazuh Manager.
#
# Penggunaan:
#   sudo NEW_KEY="<key-baru>" bash deploy/rotate-webhook-key.sh
#   atau  sudo bash deploy/rotate-webhook-key.sh   (script membuat key otomatis & menampilkan)
#
# CATATAN: sesuaikan COMPOSE_DIR bila stack app tidak berada di ./deploy
# ============================================================
set -e

COMPOSE_DIR="${COMPOSE_DIR:-$(pwd)/deploy}"
ENV_FILE="$COMPOSE_DIR/.env.production"
OSSEC_CONF="/var/ossec/etc/ossec.conf"
INTEG_ENV_FILE="/var/ossec/etc/environment"
WEBHOOK_URL="${WEBHOOK_URL:-http://localhost:3000/api/webhook/wazuh}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Jalankan dengan sudo/root."
    exit 1
fi

# --- 1. Tentukan key baru ---
if [ -n "${NEW_KEY:-}" ]; then
    KEY="$NEW_KEY"
    echo "Menggunakan NEW_KEY dari env."
else
    KEY=$(openssl rand -hex 32)
    echo "Key baru dihasilkan otomatis."
fi
if [ -n "$KEY" ]; then
    echo ""
    echo "KEY BARU (simpan baik-baik / catat):"
    echo "  $KEY"
    echo "------------------------------------------------------------"
fi
if [ -z "$KEY" ]; then echo "ERROR: key kosong"; exit 1; fi

# --- 2. Update .env.production backend ---
if [ -f "$ENV_FILE" ]; then
    if grep -q '^WEBHOOK_API_KEY=' "$ENV_FILE"; then
        sed -i "s|^WEBHOOK_API_KEY=.*|WEBHOOK_API_KEY=$KEY|" "$ENV_FILE"
    else
        echo "WEBHOOK_API_KEY=$KEY" >> "$ENV_FILE"
    fi
    echo "  OK  update $ENV_FILE"
else
    echo "  SKIP  $ENV_FILE tidak ditemukan (cari .env.production di lokasi stack app)"
fi

# --- 3. Update /var/ossec/etc/environment ---
cat > "$INTEG_ENV_FILE" << EOF
API_KEY=$KEY
EOF
chmod 640 "$INTEG_ENV_FILE"
chown root:wazuh "$INTEG_ENV_FILE"
echo "  OK  update $INTEG_ENV_FILE"

# --- 4. Update ossec.conf ---
if [ -f "$OSSEC_CONF" ]; then
    sed -i "s|<api_key>.*</api_key>|<api_key>$KEY</api_key>|" "$OSSEC_CONF"
    echo "  OK  update <api_key> di $OSSEC_CONF"
else
    echo "  SKIP  $OSSEC_CONF tidak ditemukan"
fi

# --- 5. Restart backend container (bila ada) ---
if [ -d "$COMPOSE_DIR" ] && [ -f "$COMPOSE_DIR/docker-compose.prod.yml" ]; then
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_DIR/docker-compose.prod.yml" up -d --force-recreate backend || \
        echo "  WARN  gagal recreate backend (cek path COMPOSE_DIR / nama service)"
fi

# --- 6. Restart Wazuh Manager ---
if [ -x /var/ossec/bin/ossec-control ]; then
    /var/ossec/bin/ossec-control restart || true
else
    systemctl restart wazuh-manager || true
fi

echo ""
echo "=== Rotasi selesai. Uji end-to-end: ==="
echo "  API_KEY=\"$KEY\" WEBHOOK_URL=\"$WEBHOOK_URL\" \\"
echo "    python3 /var/ossec/integrations/custom-wazuh.py /path/alert.json"
echo "  Harus muncul 'SUCCESS: Alert forwarded'."
echo "  Lalu jalankan dari laptop:  ./deploy/sync-private.sh  (simpan key baru ke repo private)"
echo "=== DONE ==="
