#!/bin/bash
# ============================================================
# VERIFIKASI akses pgAdmin lewat nginx (+ basic auth)
# Jalankan di VPS via SSH. Mendeteksi di titik mana akses gagal:
#   401 basic auth | login pgAdmin | proxy / static blank page
#
# Penggunaan:
#   sudo HTPASSWD_USER=dbadmin HTPASSWD_PASS='*****' ./verify-pgadmin.sh
# Jika HTPASSWD_PASS tidak di-set, hanya cek respons tanpa basic auth.
# ============================================================
set -e

DOMAIN="${DOMAIN:-https://siemkampus-monitoring-app.duckdns.org}"
BASE="${DOMAIN}/pgadmin"
CURL="curl -sk"

AUTH_OPTS=()
if [ -n "$HTPASSWD_USER" ] && [ -n "$HTPASSWD_PASS" ]; then
    AUTH_OPTS=(-u "$HTPASSWD_USER:$HTPASSWD_PASS")
fi

echo "=== 1. HTTP Basic Auth (nginx) ==="
if [ ${#AUTH_OPTS[@]} -eq 0 ]; then
    code=$($CURL -o /dev/null -w '%{http_code}' "$BASE/")
    echo "  /pgadmin/ tanpa basic auth -> HTTP $code (401 = terkunci, wajar)"
    echo "  Set HTPASSWD_USER & HTPASSWD_PASS untuk lanjut."
    exit 0
fi
code=$($CURL -o /dev/null -w '%{http_code}' "${AUTH_OPTS[@]}" "$BASE/")
echo "  /pgadmin/ dengan basic auth -> HTTP $code"
if [ "$code" = "401" ]; then
    echo "  FAIL: basic auth ditolak. Jalankan:"
    echo "    sudo HTPASSWD_USER=$HTPASSWD_USER HTPASSWD_PASS='password-baru' ./setup-htpasswd.sh"
    exit 1
fi
echo "  OK: basic auth diterima."

echo ""
echo "=== 2. Login page pgAdmin ==="
LOGIN="$BASE/login?next=/browser/"
code=$($CURL -o /tmp/pg_login.html -w '%{http_code}' "${AUTH_OPTS[@]}" "$LOGIN")
echo "  login page -> HTTP $code"
if [ "$code" = "404" ]; then
    echo "  FAIL: 404 - proxy /pgadmin/ tidak ketemu pgAdmin."
elif ! grep -qiE '<title>[^<]*pgAdmin|flask|csrf|/browser/' /tmp/pg_login.html; then
    echo "  WARN: halaman tidak jelas pgAdmin-nya (cek manual /tmp/pg_login.html)."
else
    echo "  OK: login page pgAdmin termuat."
fi

echo ""
echo "=== 3. Asset static (mencegah blank page) ==="
for path in "/static/js/generated/app.bundle.js" "/static/vendor/require/require.min.js"; do
    code=$($CURL -o /dev/null -w '%{http_code}' "${AUTH_OPTS[@]}" "$BASE${path}")
    echo "  $path -> HTTP $code"
done

echo ""
echo "=== 4. Endpoint internal pgAdmin ==="
code=$($CURL -o /dev/null -w '%{http_code}' "${AUTH_OPTS[@]}" "$BASE/misc/heartbeat/")
echo "  /misc/heartbeat/ -> HTTP $code"

echo ""
echo "NOTE: Login pgAdmin BUTUH email+password terpisah:"
echo "  email    = admin@siemkampus.id (PGADMIN_DEFAULT_EMAIL)"
echo "  password = PGADMIN_DEFAULT_PASSWORD di docker-compose.prod.yml"
echo "=== DONE ==="
