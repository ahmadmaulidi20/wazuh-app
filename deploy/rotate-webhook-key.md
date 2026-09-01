# Rotasi API Key Webhook Wazuh → Backend

Karena API key `custom-wazuh` pernah **bocor di history repo GitHub publik**, langkah paling
efektif adalah **mengganti (rotate)** nilai key tersebut agar nilai lama tidak lagi berguna.
Dokumen ini memandu rotasi penuh secara sinkron di semua komponen.

> Rotasi diperlukan karena: nilai lama sudah terekspos publik. Menghapus dari git saja TIDAK
> cukup — nilai lama masih valid di server sampai diganti.

---

## Ringkasan: di mana key dipakai?

| Komponen | Host | Lokasi | Nilai |
|----------|------|--------|-------|
| Backend (verifikasi header) | VPS Manager (docker) | env `WEBHOOK_API_KEY` (di `deploy/.env.production` / container) | nilai key |
| Wazuh integration config | VPS Manager | `/var/ossec/etc/ossec.conf` → `<integration><api_key>` | nilai key |
| Wazuh integration env | VPS Manager | `/var/ossec/etc/environment` → `API_KEY=...` | nilai key |
| Script integrasi | VPS Manager | `/var/ossec/integrations/custom-wazuh.py` (baca `API_KEY` env) | (tanpa hardcode setelah sanitasi) |

Semua nilai harus **sama** karena backend membandingkan header `X-API-Key` yang dikirimkan
integrasi dengan `WEBHOOK_API_KEY` miliknya.

---

## Langkah Rotasi (dijalankan DI VPS Manager)

### 1. Buat key baru (random, aman)
```bash
NEW_KEY=$(openssl rand -hex 32)     # 64 karakter hex
echo "KEY BARU: $NEW_KEY"           # simpan di password manager / catat
```

### 2. Update `.env.production` backend (stack docker)
```bash
# Di folder stack app (mis. /opt/wazuh-app/deploy atau di mana compose berada)
sed -i "s|^WEBHOOK_API_KEY=.*|WEBHOOK_API_KEY=$NEW_KEY|" deploy/.env.production

# Terapkan ke container + reload env
docker compose --env-file deploy/.env.production up -d --force-recreate backend
```

### 3. Update Wazuh Manager integration env
```bash
sudo bash -c "cat > /var/ossec/etc/environment << EOF
API_KEY=$NEW_KEY
EOF"
sudo chmod 640 /var/ossec/etc/environment
sudo chown root:wazuh /var/ossec/etc/environment
```

### 4. Update `ossec.conf` (integration block)
```bash
sudo sed -i "s|<api_key>.*</api_key>|<api_key>$NEW_KEY</api_key>|" /var/ossec/etc/ossec.conf
```

### 5. Restart Wazuh Manager
```bash
sudo /var/ossec/bin/ossec-control restart
# atau: sudo systemctl restart wazuh-manager
```

### 6. Verifikasi end-to-end
```bash
# Kirim alert uji lewat integrasi (key baru). Jalankan di manager:
echo '{"id":"rotasi-test","rule":{"id":100,"level":7,"description":"Rotasi Key Test"},"agent":{"id":"001","name":"rotasi-test"}}' \
  | API_KEY="$NEW_KEY" WEBHOOK_URL="http://localhost:3000/api/webhook/wazuh" \
    python3 /var/ossec/integrations/custom-wazuh.py

# Harus muncul "SUCCESS: Alert forwarded". Lalu cek di backend:
tail -n 50 /var/ossec/logs/ossec.log | grep custom-wazuh
```

---

## Setelah Rotasi

1. **Simpan key baru** di repo PRIVATE (`wazuh-app-private`):
   ```bash
   # dari laptop Anda:
   ./deploy/sync-private.sh      # menyalin .env.production terbaru (dengan key baru) ke repo private
   ```
2. **Perbarui nilai di `backups/`** bila perlu dengan menjalankan ulang `backup-vps-manager.sh`.
3. **Uji** bahwa alert nyata tetap terkirim ke dashboard (1–2 menit setelah restart).
4. Key lama `0d6630a9...` **tidak lagi valid** → tidak berguna meski ada di history publik.

---

## Bantuan: `rotate-webhook-key.sh`

Script ini mengotomatiskan langkah 2–5 di atas. Jalankan DI VPS Manager:
```bash
sudo NEW_KEY="$(openssl rand -hex 32)" bash deploy/rotate-webhook-key.sh
# atau biarkan script membuat key sendiri lalu tampilkan
sudo bash deploy/rotate-webhook-key.sh
```
Lihat header script untuk persis lokasi/compose yang diasumsikan.
