#!/bin/bash
# ============================================================
# SYNC sekret & backup dari repo utama (wazuh-app) ke repo PRIVATE
# (wazuh-app-private). Menyalin semua file yang git-ignored / rahasia
# dari proyek ke folder private, lalu commit & push otomatis.
#
# Penggunaan (dari root proyek utama):
#   ./deploy/sync-private.sh
#
# Prasyarat: repo private sudah di-clone, path default:
#   $HOME/wazuh-app-private   (atau set PRIVATE_DIR)
# ============================================================
set -e

# Path repo private (sesuaikan bila lokasi berbeda)
PRIVATE_DIR="${PRIVATE_DIR:-$HOME/wazuh-app-private}"
MAIN_DIR="${MAIN_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

if [ ! -d "$PRIVATE_DIR/.git" ]; then
    echo "ERROR: Repo private tidak ditemukan di $PRIVATE_DIR"
    echo "Clone dulu:  gh repo clone wazuh-app-private  (Lalu jalankan ulang)"
    exit 1
fi

echo "=== Sync repo utama -> repo PRIVATE ==="
echo "  MAIN   : $MAIN_DIR"
echo "  PRIVATE: $PRIVATE_DIR"

# --- 1. Secrets ---
mkdir -p "$PRIVATE_DIR/secrets"
cp -f "$MAIN_DIR/deploy/.env.production"          "$PRIVATE_DIR/secrets/env.production" 2>/dev/null || echo "  (skip) deploy/.env.production"
cp -f "$MAIN_DIR/backend/.env"                    "$PRIVATE_DIR/secrets/backend.env"    2>/dev/null || echo "  (skip) backend/.env"
cp -f "$MAIN_DIR/backend/firebase-service-account.json" "$PRIVATE_DIR/secrets/firebase-service-account.json" 2>/dev/null || echo "  (skip) backend/firebase-service-account.json"

# --- 2. Backups (config VPS + DB dump) ---
if [ -d "$MAIN_DIR/backups" ]; then
    mkdir -p "$PRIVATE_DIR/backups"
    # salin hanya container kosong .gitkeep agar folder rapi
    cp -fa "$MAIN_DIR/backups/." "$PRIVATE_DIR/backups/"
    echo "  (ok)  backups/ disinkronkan"
else
    echo "  (skip) Belum ada folder backups/ (jalankan backup-vps-*.sh dulu)"
    mkdir -p "$PRIVATE_DIR/backups"
    touch "$PRIVATE_DIR/backups/.gitkeep"
fi

# --- 3. SSL certs (jika ada) ---
if [ -d "$MAIN_DIR/deploy/ssl" ]; then
    mkdir -p "$PRIVATE_DIR/certs"
    cp -fa "$MAIN_DIR/deploy/ssl/." "$PRIVATE_DIR/certs/"
    echo "  (ok)  ssl/ -> certs/"
fi

# --- 4. Commit & push ---
cd "$PRIVATE_DIR"
git add -A
if git diff --cached --quiet; then
    echo "  Tidak ada perubahan untuk di-commit."
else
    git commit -m "sync secrets & backups $(date +%Y%m%d-%H%M%S)" >/dev/null
    git push origin HEAD 2>&1 | tail -2
    echo "  Commit & push PRIVATE selesai."
fi

echo "=== DONE ==="
