# Troubleshooting: Nmap Scan Tidak Muncul di Dashboard Wazuh

Dokumentasi investigasi & perbaikan masalah deteksi scan `nmap` yang tidak muncul di
dashboard Wazuh Manager (agent `srv_kampusmu`). Tanggal perbaikan: 2026-08-08.

## 1. Ringkasan Masalah

Scan `nmap -sS -p 1-2500 <IP-kampus>` yang dijalankan dari laptop lokal tidak muncul di
dashboard Wazuh Manager. Rantai yang harus bekerja: **Suricata → eve.json → logcollector
→ agent → manager (rule) → indexer → dashboard**.

## 2. Arsitektur & Topologi

| Komponen | Host | IP | Versi |
|----------|------|-----|-------|
| Wazuh Manager + Indexer + Dashboard | VPS | `103.30.194.158` | Wazuh 4.7.5 |
| Agent Wazuh + Suricata | VM kampus | `103.134.154.12` (internal `10.228.87.3`) | Wazuh 4.7.5, Suricata 6.0.4 |

- RAM VM kampus: 2GB (terbatas — lihat bagian Batasan).
- Port penting: SSH manager `22`, SSH kampus `2221`, Wazuh remoted `1514`.
- Rule custom di manager: `100102` (Nmap scan) dan `100103` (portscan) di
  `/var/ossec/etc/rules/local_rules.xml`, `level 10`, didasarkan pada `if_sid 86601`
  (event `event_type=alert` dari Suricata).

## 3. Akar Masalah (4 Penyebab yang Saling Tumpang Tindih)

### 3.1 Agent restart-loop karena watchdog kustom
Script `/usr/local/bin/wazuh-agent-watchdog.sh` + timer systemd
(`wazuh-agent-watchdog.timer`, `OnBootSec=2min`, `OnUnitActiveSec=1min`) me-restart agent
setiap menit selama status bukan `connected` / keepalive > 90 detik. Setiap restart
membuang posisi baca logcollector → **gap pengiriman eve.json**.

### 3.2 Active response memblokir IP manager sendiri
Script `/var/ossec/active-response/bin/firewall-drop-suricata` memblokir IP sumber scan
via iptables. Karena scan uji dijalankan dari manager, **manager (`103.30.194.158`)
diblokir** → SYN-ACK ke remoted port `1514` di-drop → agent tidak bisa connect kembali.

### 3.3 Posisi baca logcollector macet di tengah file
eve.json adalah file tunggal besar (12MB+). Posisi baca logcollector macet di offset
±357KB dari ±12MB → terus "grind" membaca backlog lama secara lambat, event baru di ujung
file tidak pernah terjangkau. Setelah agent restart berkali-kali, posisi baca tidak pernah
berada di tail file.

### 3.4 Traffic scan dari laptop lokal di-drop edge provider
Saat uji scan dari laptop: hasil `0 hosts up`, Suricata menerima **0 paket** dari IP
laptop. Traffic di-drop oleh provider sebelum masuk NIC VM kampus — bukan masalah
konfigurasi Wazuh/Suricata.

## 4. Perubahan yang Dilakukan

### 4.1 Kurangi footprint eve-log Suricata (VM kampus)
File: `/etc/suricata/suricata.yaml` (backup: `suricata.yaml.bak`, `suricata.yaml.bak2`).

- `http`, `tls`, `files`, `smtp`, `mqtt`, `dhcp` → `enabled: no`
- `dns` → `enabled: no`
- `- flow` dikomentari
- `ftp`, `rdp`, `nfs`, `smb`, `tftp`, `ikev2`, `dcerpc`, `krb5`, `snmp`, `rfb`, `sip`
  dikomentari
- Yang tersisa: `alert` + `ssh` (+ `anomaly`)

Hasil: RSS Suricata turun dari ±725MB → ±600MB, rule dimuat 52012.

### 4.2 Matikan watchdog (VM kampus)
```bash
sudo systemctl stop wazuh-agent-watchdog.timer
sudo systemctl disable wazuh-agent-watchdog.timer
```

### 4.3 Whitelist IP manager di active response (VM kampus)
File: `/var/ossec/active-response/bin/firewall-drop-suricata`.

Tambahkan whitelist di bagian atas script:
```bash
WHITELIST="103.30.194.158"
# skip blokir jika IP sumber di whitelist
```

Sekarang log `/var/ossec/logs/active-responses.log` mencatat:
```
firewall-drop-suricata: Skipping trusted IP 103.30.194.158
```
bukan memblokir manager.

### 4.4 Reset eve.json (VM kampus)
```bash
sudo cp /var/log/suricata/eve.json /var/log/suricata/eve.json.backup
sudo systemctl stop suricata
sudo rm -f /var/log/suricata/eve.json
sudo touch /var/log/suricata/eve.json
sudo chown root:root /var/log/suricata/eve.json
sudo chmod 600 /var/log/suricata/eve.json
sudo systemctl start suricata
sudo systemctl restart wazuh-agent
```

Suricata memerlukan waktu init ±3,5 menit di VM ini (tunggu pesan
`All AFP capture threads are running` / `engine started` di
`/var/log/suricata/suricata.log` sebelum menguji scan).

## 5. Verifikasi End-to-End (2026-08-08)

Scan uji final dari manager: `nmap -sS -T4 --top-ports 200 103.134.154.12`.

| Langkah | Bukti |
|---------|-------|
| Suricata deteksi | eve.json berisi 1 alert `Nmap TCP SYN Port Scan Detected` |
| Logcollector baca | offset posisi bertambah (e.g. 2089 → 7800), tidak macet |
| Agent kirim | `status='connected'`, `msg_sent` meningkat (270 → 536) |
| Rule manager | alert `100102` baru di `/var/ossec/logs/alerts/alerts.json` @ `07:35:53.725+0700` (±3 detik setelah scan) |
| Active response | `Skipping trusted IP 103.30.194.158` — tidak ada blokir |
| Indexer | `wazuh-alerts-4.x-2026.08.08` berisi dokumen `rule.id=100102` @ `2026-08-08T00:35:53.725Z`, level 10 |
| Dashboard | membaca index tersebut → alert tampil |

## 6. Batasan & Rekomendasi

1. **Scan dari laptop lokal**: traffic dari IP laptop di-drop oleh edge provider
   (`0 hosts up`, 0 paket diterima Suricata). Gunakan manager/VM sebagai sumber uji scan,
   atau jalankan scan dari jaringan yang paketnya benar-benar mencapai VM kampus.
2. **RAM kampus 2GB**: Suricata init lambat (±3,5 menit) dan memori hampir penuh saat
   restart. Rekomendasi upgrade ke ≥4GB.
3. **eve.json backlog lama** (2–8 Agustus) disimpan di `eve.json.backup` tetapi tidak akan
   di-replay ke manager. Hanya event baru yang terkirim.
4. **Posisi baca logcollector**: hindari me-restart agent berulang kali; setiap restart
   bisa memindahkan posisi baca eve.json.

## 7. Perintah Berguna (Diagnosa Cepat)

```bash
# Cek status koneksi agent (VM kampus)
sudo cat /var/ossec/var/run/wazuh-agentd.state | grep -E 'status|msg_sent'

# Cek posisi baca logcollector untuk eve.json (VM kampus)
LPID=$(pgrep -f wazuh-logcollector | head -1)
sudo cat /proc/$LPID/fdinfo/7 | grep pos
sudo wc -c /var/log/suricata/eve.json

# Cek alert custom di manager
sudo python3 -c "import json;c=0
for l in open('/var/ossec/logs/alerts/alerts.json'):
    try:
        a=json.loads(l)
        if str(a.get('rule',{}).get('id',''))=='100102': c+=1
    except: pass
print(c)"

# Cek alert di indexer (auth via sertifikat admin)
curl -sk --key /etc/wazuh-indexer/certs/admin-key.pem --cert /etc/wazuh-indexer/certs/admin.pem \
  'https://localhost:9200/wazuh-alerts-4.x-2026.08.08/_search' \
  -H 'Content-Type: application/json' \
  -d '{"query":{"bool":{"must":[{"term":{"rule.id":"100102"}}]}},"sort":[{"@timestamp":{"order":"desc"}}],"size":3}'
```

## 8. File Konfigurasi Terkait

| File | Host | Fungsi |
|------|------|--------|
| `/etc/suricata/suricata.yaml` | kampus | Konfigurasi eve-log (diperkecil) |
| `/etc/suricata/rules/local.rules` & `/var/lib/suricata/rules/local.rules` | kampus | Rule `sid:1000001`, threshold `type both, count 8, seconds 60` |
| `/var/ossec/active-response/bin/firewall-drop-suricata` | kampus | AR blokir + whitelist `103.30.194.158` |
| `/usr/local/bin/wazuh-agent-watchdog.sh` | kampus | Watchdog (tidak aktif — timer disabled) |
| `/var/ossec/etc/rules/local_rules.xml` | manager | Rule `100102`/`100103` |
| `/var/ossec/etc/ossec.conf` (baris ±292) | manager | `<rules_id>100102,100103</rules_id>`, `timeout_allowed`, timeout 600 |
| `/var/ossec/logs/alerts/alerts.json` | manager | Log alert terpusat |
| `/var/log/suricata/eve.json(.backup)` | kampus | Event mentah Suricata |
