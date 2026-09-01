#!/bin/bash
# ============================================================
# FIX login pgAdmin "stuck di halaman login" / password salah.
# Jalankan DI server yang menjalankan container pgAdmin (VPS Manager).
#
# Kenapa ini terjadi:
#   PGADMIN_DEFAULT_EMAIL/PASSWORD hanya dipakai SAAT PERTAMA container
#   dibuat (saat /var/lib/pgadmin/pgadmin4.db belum ada). Jika volume
#   pgadmin_data sudah ada dengan kredensial lama, mengubah env di compose
#   TIDAK mengubah password -> login ditolak / stuck di halaman login.
#
# Solusi (tanpa menghapus volume / kehilangan server tersimpan):
#   gunakan setup.py untuk set ulang password admin yang sudah ada.
#
# Penggunaan:
#   sudo ./fix-pgadmin-login.sh
#     -> reset password admin@siemkampus.id sesuai nilai PGADMIN_PASSWORD
#        di deploy/.env.production, atau argumen kedua bila diberikan.
#   sudo ./fix-pgadmin-login.sh 'password-baru'
# ============================================================
set -e

EMAIL="${PGADMIN_EMAIL:-admin@siemkampus.id}"
ENV_FILE="${ENV_FILE:-./deploy/.env.production}"
NEW_PASS="${1:-}"

# --- cari container pgadmin ---
CONTAINER=$(docker ps --format '{{.ID}} {{.Image}} {{.Names}}' | grep -i pgadmin | awk '{print $NF}' | head -1)
if [ -z "$CONTAINER" ]; then
    echo "ERROR: container pgadmin tidak ditemukan. Cek: docker ps | grep -i pgadmin"
    exit 1
fi
echo "Container pgAdmin: $CONTAINER"

# --- tentukan password baru ---
if [ -z "$NEW_PASS" ]; then
    if [ -f "$ENV_FILE" ] && grep -q '^PGADMIN_PASSWORD=' "$ENV_FILE"; then
        NEW_PASS=$(grep '^PGADMIN_PASSWORD=' "$ENV_FILE" | head -1 | cut -d= -f2-)
        echo "Mengambil password dari $ENV_FILE (PGADMIN_PASSWORD)"
    fi
fi
if [ -z "$NEW_PASS" ]; then
    echo "ERROR: tidak ada password. Berikan argumen:  sudo ./fix-pgadmin-login.sh '<password>'"
    exit 1
fi

echo "Reset password untuk: $EMAIL"
echo "== Reset via setup.py =="
docker exec -u pgadmin "$CONTAINER" \
    /venv/bin/python3 /pgadmin4/setup.py set-password "$EMAIL" "$NEW_PASS" -q 2>&1 \
    || docker exec "$CONTAINER" \
        /venv/bin/python3 /pgadmin4/setup.py set-password "$EMAIL" "$NEW_PASS" 2>&1

echo ""
echo "== Verifikasi: user terdaftar di DB pgadmin =="
docker exec -u pgadmin "$CONTAINER" sh -c \
    "sqlite3 /var/lib/pgadmin/pgadmin4.db 'SELECT email, role, active FROM user WHERE email=\"$EMAIL\";'" 2>/dev/null \
    || echo "(sqlite3 tidak tersedia di container, lewati)"

echo ""
echo "=== PENTING ==="
echo "Login sekarang dengan:"
echo "  email    = $EMAIL"
echo "  password = (nilai yg baru di-set)"
echo ""
echo "Jika MASIH stuck di halaman login, kemungkinan lain:"
echo "  1) Cache browser -> hard reload / incognito lalu login ulang."
echo "  2) Subpath/cookie -> pastikan nginx /pgadmin/ memakai X-Script-Name /pgadmin"
echo "     & SUDAH tidak ada sub_filter (lihat diagnose-pgadmin.sh --fix)."
echo "  3) Setelah reset, simpan password baru ke .env.production & repo private:"
echo "       ./deploy/sync-private.sh"
echo "=== DONE ==="
