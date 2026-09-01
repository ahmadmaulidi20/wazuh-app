#!/bin/bash
# ============================================================
# BACKUP DATABASE PostgreSQL (container backend_postgres_data)
# Jalankan DI SERVER yang menjalankan stack docker (mis. VPS manager).
# Output: backups/db/<timestamp>/ (folder ini DI-IGNORE dari git public).
#
# Membuat full dump (pg_dump) + rsync opsional volume.
# Untuk pindah ke VPS baru: lihat RUNBOOK_MIGRASI.md (restore).
# ============================================================
set -e

TS=$(date +%Y%m%d-%H%M%S)
OUT_DIR="backups/db/$TS"
mkdir -p "$OUT_DIR"

POSTGRES_USER="${POSTGRES_USER:-wazuh}"
POSTGRES_DB="${POSTGRES_DB:-wazuh_monitor}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-wazuh123}"
CONTAINER="${CONTAINER:-backend-postgres-1}"

echo "=== Backup DB postgres -> $OUT_DIR ==="

echo "  Container: $CONTAINER"
echo "  DB: $POSTGRES_DB (user: $POSTGRES_USER)"

# Full logical dump
echo "  Menjalankan pg_dump ..."
if docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" "$CONTAINER" \
    pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -F c --no-owner \
    > "$OUT_DIR/wazuh_monitor.dump" 2>"$OUT_DIR/pg_dump.err"; then
    echo "  OK pg_dump -> wazuh_monitor.dump ($(du -h "$OUT_DIR/wazuh_monitor.dump" | cut -f1))"
else
    echo "  [FAIL] pg_dump error, lihat $OUT_DIR/pg_dump.err"
    exit 1
fi

# Opsi: rsync langsung dari docker volume (snapshot mentah)
if command -v sudo >/dev/null && [ -n "${RSYNC_VOLUME:-}" ]; then
    VOLUME="${RSYNC_VOLUME:-backend_postgres_data}"
    echo "  Rsync docker volume $VOLUME (mentah) ..."
    sudo rsync -a --delete "/var/lib/docker/volumes/$VOLUME/_data/" "$OUT_DIR/volume_data/"
fi

gzip -k "$OUT_DIR/wazuh_monitor.dump"

echo ""
echo "=== Ringkasan ==="
du -sh "$OUT_DIR"
echo ""
echo "CATATAN PENTING:"
echo "  - Dump DB berisi DATA PRODUKSI (sensitif). backups/ DI-IGNORE dari git public."
echo "  - DILARANG commit folder backups/ ke GitHub. Simpan di penyimpanan aman "
echo "    (mis. backup off-site / password manager / object storage private)."
echo "=== DONE ==="
