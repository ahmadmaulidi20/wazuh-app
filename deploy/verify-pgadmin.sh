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
echo "=== 5. UJI LOGIN PENUH (email+password) [paling penting] ==="
# Butuh credential pgAdmin terpisah dari basic auth:
#   PGADMIN_EMAIL (default admin@siemkampus.id) & PGADMIN_PASSWORD
PGADMIN_EMAIL="${PGADMIN_EMAIL:-admin@siemkampus.id}"
if [ -z "${PGADMIN_PASSWORD:-}" ]; then
    echo "  [SKIP] Set PGADMIN_PASSWORD (password pgAdmin) untuk uji login."
else
    # 5a. Ambil halaman login + CSRF token
    LOGIN_PAGE="$BASE/login?next=%2Fpgadmin%2Fbrowser%2F"
    $CURL "${AUTH_OPTS[@]}" -c /tmp/pg_cookies.txt -o /tmp/pg_login2.html "$LOGIN_PAGE"
    echo "  GET login page -> HTTP $($CURL -o /dev/null -w '%{http_code}' "${AUTH_OPTS[@]}" "$LOGIN_PAGE")"

    # Ekstrak CSRF token (input name csrf_token)
    CSRF=$(grep -oE 'name="csrf_token"[^>]*value="[^"]*"' /tmp/pg_login2.html \
        | sed -E 's/.*value="([^"]*)".*/\1/' | head -1)
    if [ -z "$CSRF" ]; then
        CSRF=$($CURL "${AUTH_OPTS[@]}" -b /tmp/pg_cookies.txt -c /tmp/pg_cookies.txt "$LOGIN_PAGE" \
            | grep -oE '"csrf"[^,]*"[a-f0-9]+' | grep -oE '[a-f0-9]{32,}' | head -1)
    fi
    echo "  CSRF token: ${CSRF:0:12}... (${#CSRF} chars)"

    # 5b. Kirim login POST dengan cookie + csrf
    POST_DATA="email=$PGADMIN_EMAIL&password=$PGADMIN_PASSWORD&_csrf_token=$CSRF&next=%2Fpgadmin%2Fbrowser%2F"
    RESP_HEADERS=$(mktemp)
    code=$($CURL -s "${AUTH_OPTS[@]}" -b /tmp/pg_cookies.txt -c /tmp/pg_cookies.txt \
        -o /tmp/pg_login_post.html -D "$RESP_HEADERS" -w '%{http_code}' \
        -X POST "$BASE/login" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data "$POST_DATA")
    echo "  POST login -> HTTP $code"
    echo "  --- Set-Cookie (dari server) ---"
    grep -i '^Set-Cookie' "$RESP_HEADERS" | sed 's/\(session=[^;]*\).*/\1 .../'
    echo "  --- Lokasi/redirect header ---"
    grep -i '^Location:' "$RESP_HEADERS" || echo "  (tidak ada redirect header)"
    echo "  --- Isi respons (potongan) ---"
    grep -qiE 'Invalid|wrong|fail|error' /tmp/pg_login_post.html && \
        echo "  [WARN] ada keyword error/invalid di respons login" || echo "  (tidak ada keyword error)"
    # cek apakah respons menunjuk ke browser (sukses) atau login lagi (gagal)
    if grep -qiE '/pgadmin/browser/|next.*browser' /tmp/pg_login_post.html; then
        echo "  [OK]   respons mengarah ke /pgadmin/browser/ (login berhasil)."
    else
        echo "  [FAIL] respons TIDAK mengarah ke browser -> kemungkinan login ditolak/stuck."
        echo "         Cek: (1) password pgAdmin salah, (2) CSRF/session cookie, (3) volume pgadmin"
        echo "         punya kredensial lama (lihat catatan di bawah)."
    fi
    rm -f "$RESP_HEADERS"
fi

echo ""
echo "NOTE: Login pgAdmin pakai credential TERPISAH dari basic auth:"
echo "  email    = admin@siemkampus.id (PGADMIN_DEFAULT_EMAIL)"
echo "  password = PGADMIN_DEFAULT_PASSWORD di .env.production / docker-compose.prod.yml"
echo ""
echo "CLU: PGADMIN_DEFAULT_PASSWORD hanya dipakai SAAT PERTAMA kali container/jalankan."
echo "     Jika volume pgadmin_data sudah ada, ganti password via:"
echo "       docker exec <pgadmin> python3 /pgadmin4/setup.py set-password admin@siemkampus.id '<pass>'"
echo "=== DONE ==="
