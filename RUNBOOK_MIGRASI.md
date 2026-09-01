# RUNBOOK MIGRASI — Pindah ke VPS / Device Baru Tanpa Konfigurasi Ulang

Dokumen panduan untuk memigrasikan seluruh stack **Wazuh monitoring** ke server/device baru
hanya dengan mengulang langkah di bawah — semua konfigurasi aplikasi, kedua VPS, dan database
sudah terekam di repo ini (config tanpa sekret) + di folder `backups/` (config dengan sekret &
data, **tidak** di-commit ke GitHub).

---

## 1. Peta Arsitektur (2 Host)

| Host | Alamat | Peran | Komponen |
|------|--------|-------|----------|
| **VPS Manager** | `103.30.194.158` | Wazuh Manager + Indexer + Dashboard **dan** app (backend + nginx + postgres + pgAdmin) | Wazuh all-in-one, nginx, `docker-compose.prod.yml`, PostgreSQL, pgAdmin, Flutter web static |
| **VPS Agent (kampus)** | `103.134.154.12` (internal `10.228.87.3`) | Wazuh agent + Suricata + active response | wazuh-agent, Suricata, `firewall-drop-suricata`, watchdog |

Domain: `siemkampus-monitoring-app.duckdns.org` (SSL via Let's Encrypt).

---

## 2. File Konfigurasi per Host (sumber kebenaran)

### A. Sisi aplikasi (repo ini, `deploy/` + `backend/` + `wazuh_app/`)
| File | Fungsi |
|------|--------|
| `deploy/docker-compose.prod.yml` | Orkestrasi postgres + backend + pgadmin + nginx |
| `deploy/nginx.conf` | Reverse proxy (API, WS, pgAdmin, Flutter static) |
| `deploy/WAZUH_INTEGRATION.md` | Integrasi Wazuh -> backend webhook |
| `backend/**` | Source backend + Dockerfile + prisma schema |
| `wazuh_app/**` | Source Flutter |

### B. VPS Manager (config asli -> di `backups/manager/`)
- `/var/ossec/etc/ossec.conf`, `/var/ossec/etc/rules/local_rules.xml`, `/var/ossec/etc/client.keys`
- `/var/ossec/integrations/custom-wazuh.py`, `/var/ossec/etc/environment` (rahasia)
- `/etc/wazuh-indexer/**`, `/etc/wazuh-dashboard/**`
- nginx live config `/etc/nginx/sites-available/siem-web`, `/etc/nginx/.htpasswd`
- `docker-compose.prod.yml` & `.env.production` (rahasia) di lokasi stack

### C. VPS Agent (config asli -> di `backups/agent/`)
- `/var/ossec/etc/ossec.conf`, `client.keys`, `local_internal_options.conf`
- `/etc/suricata/suricata.yaml`, rules lokal
- `/var/ossec/active-response/bin/firewall-drop-suricata`, watchdog

### D. Database (data -> di `backups/db/`)
- Full dump `pg_dump` dari container `backend-postgres-1` (db `wazuh_monitor`).

---

## 3. Prosedur Backup (dari mesin lokal / server)

```bash
# 1. Backup config VPS manager (butuh SSH ke 103.30.194.158)
./deploy/backup-vps-manager.sh

# 2. Backup config VPS agent (butuh SSH ke 103.134.154.12)
./deploy/backup-vps-agent.sh

# 3. Backup database (jalankan DI server yang menjalankan docker)
POSTGRES_PASSWORD='...' ./deploy/backup-db.sh
```

Semua output masuk `backups/` yang **DI-IGNORE git** -> aman, tidak bocor.

---

## 4. Prosedur Restore ke VPS / Device BARU

> Prasyarat VPS baru: Docker + Docker Compose + (untuk domain) nginx + certbot.

### 4.1 Deploy aplikasi (backend + postgres + pgadmin + nginx)
```bash
cd aplikasi-wazuh/deploy          # repo ini di VPS baru / clone dari GitHub

# Isi sekret dari nilai asli (TIDAK ada di git). Salin template lalu edit:
cp .env.production.example .env.production
#   -> isi POSTGRES_PASSWORD, JWT_SECRET, WEBHOOK_API_KEY, PGADMIN_PASSWORD

# Taruh file private yang tidak boleh ikut git:
#   firebase-service-account.json   (dari server lama)
#   ssl/ certbot certs (atau jarakan certbot --nginx di VPS baru)

npm --prefix ../backend ci || true   # (bila perlu build backend)
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
```

### 4.2 Restore database
```bash
# Dump ada di backups/db/<ts>/wazuh_monitor.dump
docker exec backend-postgres-1 pg_restore -U wazuh -d wazuh_monitor \
    < backups/db/<ts>/wazuh_monitor.dump
# atau lewat pipeline:
docker cp backups/db/<ts>/wazuh_monitor.dump backend-postgres-1:/tmp/
docker exec backend-postgres-1 pg_restore -U wazuh -d wazuh_monitor /tmp/wazuh_monitor.dump
```

### 4.3 Restore config Wazuh Manager (pada VPS manager baru)
```bash
# Salin dari backups/manager/<ts>/ yang dibuat pada server lama:
#  - ossec.conf, local_rules.xml, client.keys  -> /var/ossec/etc/...
#  - custom-wazuh.py -> /var/ossec/integrations/ (chmod 755, chown root:ossec)
#  - environment (API_KEY) -> /var/ossec/etc/environment
#  - wazuh-indexer / wazuh-dashboard certs & config
sudo systemctl restart wazuh-manager
```

### 4.4 Restore config Wazuh Agent (pada VPS agent baru)
```bash
# Salin dari backups/agent/<ts>/:
#  - ossec.conf, client.keys, local_internal_options.conf -> /var/ossec/etc/
#  - suricata.yaml, suricata-local.rules -> /etc/suricata/...
#  - active-response/firewall-drop-suricata -> /var/ossec/active-response/bin/
#  - wazuh-agent-watchdog.sh -> /usr/local/bin/ (jika dipakai)
sudo systemctl restart wazuh-agent suricata
```

### 4.5 SSL & domain (VPS manager baru)
```bash
sudo certbot --nginx -d siemkampus-monitoring-app.duckdns.org
# path cert sesuai nginx.conf: /etc/letsencrypt/live/siemkampus-monitoring-app.duckdns.org/
```

---

## 5. Verifikasi Setelah Migrasi

| Cek | Perintah / Lokasi |
|-----|--------------------|
| Backend API naik | `curl -s http://localhost:3000/health` |
| Login admin | `./deploy/test-login.js` (isi `ADMIN_PASSWORD`) |
| WhatsApp/pgAdmin | `https://domain/pgadmin/` (login) |
| Agent connect | di manager `/var/ossec/logs/ossec.log` & dashboard |
| Alerts masuk | dashboard / `alert` API |
| Integrasi webhook | `tail -f /var/ossec/logs/ossec.log \| grep custom-wazuh` |

### 5.3 pgAdmin: login "stuck di halaman login" / password salah

Gejala: setelah submit kredensial, halaman tetap di login (tidak masuk panel).
Penyebab paling umum:

1. **Volume `pgadmin_data` punya kredensial lama.** `PGADMIN_DEFAULT_EMAIL/PASSWORD`
   hanya dipakai SAAT PERTAMA container dibuat (saat `/var/lib/pgadmin/pgadmin4.db`
   belum ada). Jika volume sudah ada, mengubah `.env.production` **tidak** mengubah
   password login. Reset password tanpa hapus volume (tidak kehilangan server tersimpan):

   ```bash
   cd /opt/wazuh-app
   sudo bash deploy/diagnose-pgadmin-login.sh                 # kumpulkan diagnosa dulu (read-only)
   sudo bash deploy/fix-pgadmin-login.sh '<password-baru>'    # atau pakai PGADMIN_PASSWORD dari .env.production
   # lalu hard-reload / incognito & login dengan admin@siemkampus.id + password baru
   ```

2. **Subpath/cookie.** Pastikan blok nginx `/pgadmin/` memakai
   `X-Script-Name /pgadmin`, `X-Forwarded-Host $host`, dan `proxy_cookie_path / /pgadmin/`
   (lihat `deploy/nginx.conf`), lalu `sudo nginx -t && sudo nginx -s reload`.

3. **Cache browser.** Hard reload (Ctrl+Shift+R) atau buka mode incognito.

Uji login penuh (POST+CSRF+redirect) untuk memastikan:
   ```bash
   cd /opt/wazuh-app
   PGADMIN_PASSWORD='<pass>' sudo bash deploy/verify-pgadmin.sh
   ```

---

## 6. Keamanan & Kepatuhan (repo PUBLIC)

- **JANGAN commit** folder `backups/`, `.env.production`, `firebase-service-account.json`, `ssl/`, dump DB ke GitHub.
- Rahasia (API key webhook, password DB/pgAdmin, JWT, service-account) **tidak pernah** disimpan di git.
- Saat mencetak nama server/IP di dokumen, pertimbangkan: nilai sudah publik via DNS, tapi hindari menambah detail yang memudahkan serangan bila tidak perlu.
- Jika rahasia pernah ter-expose (mis. history git public), **rotate** nilai tersebut di server.
