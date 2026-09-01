#!/bin/bash
# ============================================================
# SETUP .htpasswd untuk basic auth nginx (/pgadmin/)
# Jalankan di VPS via SSH. Membuat/meng-update user basic auth
# yang di-baca oleh deploy/nginx.conf (auth_basic_user_file).
#
# Penggunaan:
#   sudo HTPASSWD_USER=dbadmin HTPASSWD_PASS='*****' ./setup-htpasswd.sh
#
# Ganti password -> file .htpasswd di-overwrite dengan user baru.
# ============================================================
set -e

HTPASSWD_FILE=${HTPASSWD_FILE:-/etc/nginx/.htpasswd}
HTPASSWD_USER=${HTPASSWD_USER:-dbadmin}

if [ -z "$HTPASSWD_PASS" ]; then
    echo "HTPASSWD_PASS belum di-set. Input password secara interaktif:"
    read -s -p "Password untuk user '$HTPASSWD_USER': " HTPASSWD_PASS
    echo ""
    if [ -z "$HTPASSWD_PASS" ]; then
        echo "ERROR: Password kosong. Batalkan."
        exit 1
    fi
fi

# Pastikan tools tersedia
if command -v htpasswd >/dev/null 2>&1; then
    HASH_TOOL="htpasswd"
elif command -v openssl >/dev/null 2>&1; then
    HASH_TOOL="openssl"
else
    echo "ERROR: Tidak ada 'htpasswd' (apache2-utils) maupun 'openssl'."
    echo "Install: sudo apt-get update && sudo apt-get install -y apache2-utils"
    exit 1
fi

echo "Menulis basic-auth user '$HTPASSWD_USER' ke $HTPASSWD_FILE"

if [ "$HASH_TOOL" = "htpasswd" ]; then
    if [ -f "$HTPASSWD_FILE" ] && grep -q "^${HTPASSWD_USER}:" "$HTPASSWD_FILE"; then
        htpasswd -b -B "$HTPASSWD_FILE" "$HTPASSWD_USER" "$HTPASSWD_PASS"
    else
        htpasswd -b -B -c "$HTPASSWD_FILE" "$HTPASSWD_USER" "$HTPASSWD_PASS"
    fi
else
    SALT=$(openssl rand -base64 6 | tr -d '/+=' | head -c 8)
    HASH=$(openssl passwd -apr1 -salt "$SALT" "$HTPASSWD_PASS")
    if [ -f "$HTPASSWD_FILE" ] && grep -q "^${HTPASSWD_USER}:" "$HTPASSWD_FILE"; then
        sed -i "s|^${HTPASSWD_USER}:.*|${HTPASSWD_USER}:${HASH}|" "$HTPASSWD_FILE"
    else
        echo "${HTPASSWD_USER}:${HASH}" >> "$HTPASSWD_FILE"
    fi
fi

chmod 640 "$HTPASSWD_FILE"
chown root:www-data "$HTPASSWD_FILE" 2>/dev/null || chown root:root "$HTPASSWD_FILE"

echo ""
echo "=== Uji & reload nginx ==="
sudo nginx -t
sudo systemctl reload nginx
echo "  nginx reloaded OK"

echo ""
echo "=== Verifikasi ==="
DOMAIN="https://siemkampus-monitoring-app.duckdns.org"
code=$(curl -sk -o /dev/null -w '%{http_code}' -u "$HTPASSWD_USER:$HTPASSWD_PASS" "$DOMAIN/pgadmin/")
echo "  /pgadmin/ dengan basic auth ($HTPASSWD_USER) -> HTTP $code"
echo "  200/302 = OK (password diterima). 401 = password masih salah."
echo ""
echo "NOTE: Login pgAdmin tetap butuh email+password terpisah:"
echo "  email    = admin@siemkampus.id (PGADMIN_DEFAULT_EMAIL)"
echo "  password = PGADMIN_DEFAULT_PASSWORD di docker-compose.prod.yml"
echo "=== DONE ==="
