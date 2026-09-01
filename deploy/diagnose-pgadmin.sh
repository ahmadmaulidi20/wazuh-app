#!/bin/bash
# ============================================================
# DIAGNOSA + REPAIR pgAdmin "Not Found" di panel kerja (subpath)
# Jalankan di VPS via SSH. Read-mostly: mendeteksi semua penyebab
# umum error "The requested URL was not found on the server" yang
# muncul DI DALAM panel kerja pgAdmin (mis. saat buka tabel).
#
# Penyebab yang dideteksi:
#   1) Double-prefix: blok /pgadmin/ masih memakai sub_filter DI
#      SAMPING X-Script-Name  ->  URL menjadi /pgadmin/pgadmin/...
#      (salah satu dari keduanya saja, jangan keduanya)
#   2) Blok /pgadmin/ TANPA X-Script-Name -> URL tidak ber-prefix
#   3) Container pgAdmin belum ter-recreate (ROOT_URL/SCRIPT_NAME)
#   4) Cakupan cookie di subpath (/ pganti /pgadmin)
#
# Penggunaan:
#   sudo HTPASSWD_USER=dbadmin HTPASSWD_PASS='***' ./diagnose-pgadmin.sh [--fix]
# Tanpa --fix hanya diagnosa. Dengan --fix, terapkan repair nginx.
# ============================================================
set -u

MODE="${1:-diagnose}"
DO_FIX=0
[ "$MODE" = "--fix" ] && DO_FIX=1

DOMAIN="https://siemkampus-monitoring-app.duckdns.org"
CURL="curl -sk"

# --- cari blok /pgadmin/ di semua config nginx yang live -------------
echo "=== 1. Cari blok /pgadmin/ di config nginx live ==="
NGINX_DUMP=$(sudo nginx -T 2>/dev/null)

if ! echo "$NGINX_DUMP" | grep -q "location /pgadmin/"; then
    echo "  [WARN] Tidak ada 'location /pgadmin/' pada config nginx live."
    echo "  Nginx ternyata BUKAN yang menyajikan /pgadmin/. Cek apakah domain"
    echo "  dilayani oleh nginx container (mynginx) atau proxy lain."
else
    echo "  Blok ditemukan. Menampilkan isi blok /pgadmin/ (untuk review):"
    echo "  --------------------------------------------------------------"
    echo "$NGINX_DUMP" \
        | awk '/location \/pgadmin\/ \{/,/\}/' \
        | sed 's/^/  | /'
    echo "  --------------------------------------------------------------"
fi

echo ""
echo "=== 2. Deteksi double-prefix (sub_filter + X-Script-Name) ==="
BLOCK=$(echo "$NGINX_DUMP" \
        | awk '/location \/pgadmin\/ \{/,/\}/')
HAS_SUB=$(echo "$BLOCK" | grep -c "sub_filter")
HAS_SCRIPT=$(echo "$BLOCK" | grep -c "X-Script-Name")

if [ "$HAS_SUB" -gt 0 ] && [ "$HAS_SCRIPT" -gt 0 ]; then
    echo "  [FAIL] double-prefix DETECTED: blok /pgadmin/ memakai BOTH"
    echo "         sub_filter DAN X-Script-Name."
    echo "         Hasilnya pgAdmin menghasilkan URL /pgadmin/... TAPI"
    echo "         sub_filter juga menambah /pgadmin -> /pgadmin/pgadmin/..."
    echo "         => 404 'Not Found' di dalam panel kerja."
    echo "         FIX: hilangkan sub_filter, cukup X-Script-Name saja."
    NEED_FIX=1
elif [ "$HAS_SCRIPT" -eq 0 ]; then
    echo "  [FAIL] blok /pgadmin/ TIDAK memakai X-Script-Name."
    echo "         pgAdmin menghasilkan URL tanpa prefix /pgadmin -> 404."
    echo "         FIX: tambahkan 'proxy_set_header X-Script-Name /pgadmin;'"
    NEED_FIX=1
else
    echo "  [OK]   blok /pgadmin/ memakai X-Script-Name tanpa sub_filter."
    echo "         Pendekatan ini sesuai dokumentasi resmi pgAdmin."
    NEED_FIX=0
fi

echo ""
echo "=== 3. Periksa config container pgAdmin ==="
CID=$(docker ps --format '{{.ID}} {{.Image}}' | grep -i pgadmin | awk '{print $1}' | head -1)
if [ -z "$CID" ]; then
    echo "  [WARN] Container pgAdmin tidak ditemukan. (Mungkin beda host/service?)"
else
    echo "  Container: $CID"
    echo -n "  PGADMIN_CONFIG_ROOT_URL di config_distro.py : "
    docker exec "$CID" grep -iE "ROOT_URL|SCRIPT_NAME|SERVER_MODE" /pgadmin4/config_distro.py 2>/dev/null \
        || echo "(tidak terlihat / file belum dibuat)"
fi

echo ""
echo "=== 4. Verifikasi akses bertingkat ==="
if [ -n "${HTPASSWD_USER:-}" ] && [ -n "${HTPASSWD_PASS:-}" ]; then
    AUTH=(-u "$HTPASSWD_USER:$HTPASSWD_PASS")
    code=$($CURL -o /dev/null -w '%{http_code}' "${AUTH[@]}" "$DOMAIN/pgadmin/")
    echo "  /pgadmin/ (basic auth)    -> HTTP $code"
    code2=$($CURL -o /dev/null -w '%{http_code}' "${AUTH[@]}" "$DOMAIN/pgadmin/misc/heartbeat/")
    echo "  /pgadmin/misc/heartbeat/  -> HTTP $code2  (200 = endpoint pgAdmin reachable)"
    code3=$($CURL "${AUTH[@]}" "$DOMAIN/pgadmin/" | grep -oE 'src="/{1,2}pgadmin/[^"]*"' | head -3)
    echo "  Contoh referensi asset di HTML:"
    echo "$code3" | sed 's/^/    /'
    if echo "$code3" | grep -qE 'src="/pgadmin/'; then
        echo "  [OK]   asset sudah ber-prefix /pgadmin (bukan double /pgadmin/pgadmin)."
    else
        echo "  [INFO] asset tidak ber-/pgadmin lihat output di atas."
    fi
else
    code=$($CURL -o /dev/null -w '%{http_code}' "$DOMAIN/pgadmin/")
    echo "  /pgadmin/ tanpa basic auth -> HTTP $code (401 = wajar terkunci)"
    echo "  Set HTPASSWD_USER & HTPASSWD_PASS untuk cek detail."
fi

echo ""
echo "=== 5. Log 404 di container pgAdmin (path yang benar-benar gagal) ==="
if [ -n "${CID:-}" ]; then
    docker logs --tail 300 "$CID" 2>&1 \
        | grep -iE "404|NotFound" \
        | tail -15 \
        | sed 's/^/  /' \
        || echo "  (tidak ada 404 di 300 baris log terakhir)"
fi

echo ""
if [ "$DO_FIX" = "1" ] && [ "${NEED_FIX:-0}" = "1" ]; then
    echo "=== FIX: menerapkan blok /pgadmin/ yang benar ==="
    echo "  Memanggil fix-pgadmin-vps.sh untuk menimpa blok /pgadmin/ ..."
    sudo HTPASSWD_USER="${HTPASSWD_USER:-}" HTPASSWD_PASS="${HTPASSWD_PASS:-}" \
        bash "$(dirname "$0")/fix-pgadmin-vps.sh"
    echo "  Setelah ini: (a) hard-reload browser atau buka mode incognito,"
    echo "  (b) login ulang ke $DOMAIN/pgadmin/."
else
    if [ "${NEED_FIX:-0}" = "1" ]; then
        echo "  Perlu fix. Jalankan:  sudo ./diagnose-pgadmin.sh --fix"
        echo "  (set HTPASSWD_PASS agar fix + cek berjalan lengkap)"
    else
        echo "  Config nginx sudah benar. Jika error masih muncul, penyebab:"
        echo "    - Cache browser lama (hard reload / incognito) -> login ulang"
        echo "    - Container pgAdmin belum recreate -> docker compose up -d --force-recreate pgadmin"
    fi
fi

echo "=== DONE ==="
