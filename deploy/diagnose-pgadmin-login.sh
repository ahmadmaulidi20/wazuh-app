#!/bin/bash
# ============================================================
# DIAGNOSIS login pgAdmin "stuck di halaman login"
# AMAN / READ-ONLY: tidak mengubah apa pun di server (tidak ada
# down, rm, nginx reload, ataupun setup.py set-password).
#
# Jalankan di VPS Manager (yang menjalankan container pgAdmin):
#   cd /opt/wazuh-app
#   sudo bash deploy/diagnose-pgadmin-login.sh
# Lalu tempel SELURUH output ke assistant.
# ============================================================
EMAIL="${PGADMIN_EMAIL:-admin@siemkampus.id}"
echo "Target email pgAdmin: $EMAIL"
echo ""

echo "=== [1] Container pgAdmin (running + semua) ==="
docker ps -a | grep -i pgadmin || echo "(tidak ada container bernama pgadmin)"

CONTAINER=$(docker ps --format '{{.Names}}' | grep -i pgadmin | head -1)
if [ -z "$CONTAINER" ]; then
    echo ""
    echo "ERROR: tidak ada container pgadmin yang berjalan. Berhenti di sini."
    exit 1
fi
echo "Container aktif: $CONTAINER"
echo "Image: $(docker inspect -f '{{.Config.Image}}' "$CONTAINER")"
echo "Dibuat: $(docker inspect -f '{{.Created}}' "$CONTAINER")"

echo ""
echo "=== [2] Env pgAdmin aktif (password DISEMBUNYIKAN) ==="
docker inspect "$CONTAINER" | grep -iE \
    'PGADMIN_DEFAULT_EMAIL|PGADMIN_DEFAULT_PASSWORD|PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED|PGADMIN_CONFIG_ROOT_URL|PGADMIN_CONFIG_SERVER_MODE' \
    | sed -E 's#(PGADMIN_DEFAULT_PASSWORD"?:?"e?"?\[?[^,]*,).*#\1 <hidden>#'

echo ""
echo "=== [3] Status file DB pgAdmin (kapan dibuat/diubah -> tahu password lama) ==="
docker exec -u pgadmin "$CONTAINER" sh -c \
    'ls -la /var/lib/pgadmin/pgadmin4.db 2>/dev/null && echo "--- stat ---" && stat -c "ukuran=%s  dimodifikasi=%y" /var/lib/pgadmin/pgadmin4.db 2>/dev/null' \
    || echo "(pgadmin4.db tidak ditemukan di /var/lib/pgadmin — cek mount volume)"
echo "  Mount volume:"
docker inspect -f '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' "$CONTAINER"

echo ""
echo "=== [4] Konfigurasi lokal pgAdmin (kalau ada override) ==="
docker exec -u pgadmin "$CONTAINER" sh -c \
    'for f in /pgadmin4/config_local.py /pgadmin4/config_distro.py; do echo "--- $f ---"; grep -iE "MASTER_PASSWORD_REQUIRED|SERVER_MODE|AUTHENTICATION|ROOT_URL|CSRF|REMEMBER" "$f" 2>/dev/null || echo "(tidak ada / kosong)"; done'

echo ""
echo "=== [5] Pendengar TCP pgAdmin di dalam container ==="
docker exec -u pgadmin "$CONTAINER" sh -c 'netstat -ltnp 2>/dev/null | grep -E ":(80|5050|8080)\b" || ss -ltnp 2>/dev/null | grep -E ":(80|5050|8080)\b" || echo "(tidak bisa cek netstat/ss)"'

echo ""
echo "=== [6] Konfigurasi nginx saat ini untuk /pgadmin/ ==="
NGINX_DUMP="$(nginx -T 2>/dev/null)"
if [ -z "$NGINX_DUMP" ]; then
    echo "  (nginx -T butuh root — jalankan: sudo nginx -T | grep -iA8 -e 'location /pgadmin/')"
else
    echo "$NGINX_DUMP" | grep -iA8 'location /pgadmin/' || echo "  [FAIL] tidak ada 'location /pgadmin/' di nginx"
    echo ""
    echo "  --- Scan indikator LOGIN LOOP (cookie/scheme/prefix) ---"
    if echo "$NGINX_DUMP" | grep -qi 'proxy_cookie_path'; then
        echo "  [BENDERA MERAH] proxy_cookie_path DITEMUKAN -> TIDAK ada di panduan resmi pgAdmin."
        echo "                 Rewrite Path cookie bisa memicu login loop. HAPUS dari blok /pgadmin/."
    else
        echo "  [OK] tidak ada proxy_cookie_path."
    fi
    if echo "$NGINX_DUMP" | grep -qi 'X-Scheme \$scheme' || echo "$NGINX_DUMP" | grep -qi 'X-Scheme'; then
        echo "  [OK] X-Scheme \$scheme ada -> pgAdmin tahu koneksi HTTPS (untuk cookie Secure/redirect)."
    else
        echo "  [BENDERA MERAH] X-Scheme TIDAK ada di blok /pgadmin/ -> pgAdmin tidak tahu HTTPS,"
        echo "                  redirect/cookie bisa salah. Tambahkan: proxy_set_header X-Scheme \$scheme;"
    fi
    echo "$NGINX_DUMP" | grep -qi 'location /pgadmin/pgadmin' && \
        echo "  [BENDERA MERAH] double-prefix /pgadmin/pgadmin DITEMUKAN -> hilangkan sub_filter." || \
        echo "  [OK] tidak ada double-prefix /pgadmin/pgadmin."
fi
echo ""
echo "  --- Env ROOT_URL di container (indikator konflik subpath) ---"
if docker inspect "$CONTAINER" | grep -q 'PGADMIN_CONFIG_ROOT_URL'; then
    echo "  [BENDERA MERAH] PGADMIN_CONFIG_ROOT_URL MASIH TERPASANG -> konflik dgn X-Script-Name bisa bikin"
    echo "                  login loop. HAPUS dari compose (biarkan X-Script-Name yg menangani prefix)."
else
    echo "  [OK] PGADMIN_CONFIG_ROOT_URL tidak terpasang."
fi

echo ""
echo "=== [7] Rekam jejak: apakah ada skrip perbaikan di /opt/wazuh-app ==="
for f in /opt/wazuh-app/deploy/fix-pgadmin-vps.sh \
         /opt/wazuh-app/deploy/diagnose-pgadmin.sh \
         /opt/wazuh-app/deploy/nginx.conf \
         /opt/wazuh-app/deploy/.env.production; do
    if [ -e "$f" ]; then
        echo "ADA: $f  (modif: $(stat -c '%y' "$f"))"
    else
        echo "TIDAK ADA: $f"
    fi
done
echo ""
echo "  Password pgAdmin di .env.production (tampilkan hanya status, jangan bocorkan):"
if [ -f /opt/wazuh-app/deploy/.env.production ]; then
    grep -q '^PGADMIN_PASSWORD=change-this-pgadmin-password' /opt/wazuh-app/deploy/.env.production \
        && echo "  PGADMIN_PASSWORD = placeholder 'change-this-pgadmin-password'" \
        || echo "  PGADMIN_PASSWORD = nilai non-placeholder (sudah di-set)"
fi

echo ""
echo "=== SELESAI: tempel seluruh output ini ke assistant ==="
