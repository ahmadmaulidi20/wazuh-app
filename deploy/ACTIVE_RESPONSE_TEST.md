# Prosedur Uji Active Response (Blok Otomatis) Wazuh

Dokumen ini menjelaskan cara menguji **active response `firewall-drop`** Wazuh secara end-to-end:
dari kemunculan percobaan brute-force SSH hingga IP benar-benar diblokir di firewall lalu
otomatis dilepas (auto-unblock) setelah timeout.

> Catatan: uji ini terbukti bekerja pada 5 Agu 2026 terhadap serangan brute-force SSH nyata
> (`58.23.69.251`) dan dua uji terkontrol (IP uji `203.0.113.10` dan IP client `182.9.161.37`).

---

## 1. Cara Kerja yang Diuji

```
auth.log (Failed password) 
  -> wazuh-analysisd: rule 5763 "sshd: brute force" (level 10, frequency 8)
  -> wazuh-execd: active response firewall-drop "add"
  -> iptables/nft: -A INPUT -s <ip> -j DROP  (dan FORWARD)
  -> setelah <timeout> detik: perintah "delete" -> rule dihapus
```

## 2. Komponen

| Komponen | Lokasi |
|---|---|
| Konfigurasi AR | `/var/ossec/etc/ossec.conf` baris ~256–294 (`disabled no`, rules `5551,5763,5720,5712`, timeout `600`) |
| Executable | `/var/ossec/active-response/bin/firewall-drop` |
| Log eksekusi AR | `/var/ossec/logs/active-responses.log` |
| Log manager | `/var/ossec/logs/ossec.log` |
| Alert | `/var/ossec/logs/alerts/alerts.json`, DB backend `alerts` |

## 3. File Script (di repo ini, folder `deploy/`)

| File | Fungsi |
|---|---|
| `test-active-response.sh` | Injeksi N login gagal untuk IP tertentu ke `/var/log/auth.log` |
| `ar-proof-job.sh` | Bukti sisi server: menulis `add/delete`, rule iptables & nft ke `/home/wazuh/ar-proof.txt` (dijalankan background) |
| `test-active-response.ps1` | Orkestrator Windows: baseline → trigger → verifikasi blokir → verifikasi auto-unblock |

## 4. Cara Menjalankan

### Opsi A: Orkestrator Windows (disarankan)

```powershell
# dari root repo, sesuaikan parameter bila perlu
.\deploy\test-active-response.ps1 -LockoutSec 600
```

Otomatis mendeteksi IP publik client dari sesi SSH aktif, mengecek baseline,
memicu blokir, membuktikan ping/curl/SSH terputus, lalu menunggu auto-unblock
dan memverifikasi pemulihan.

### Opsi B: Manual (server-side)

```bash
# 1. (opsional) cek IP client aktif
who
# 2. upload & injeksi login gagal utk IP target (IP client ATAU IP test 203.0.113.x)
scp deploy/test-active-response.sh wazuh@SERVER:/home/wazuh/
ssh wazuh@SERVER
echo 'wazuh' | sudo -S bash /home/wazuh/test-active-response.sh <IP> 10
# 3. jadwalkan bukti
echo 'wazuh' | sudo -S bash -c 'nohup bash /home/wazuh/ar-proof-job.sh <IP> >/dev/null 2>&1 &'
# 4. setelah ~15-30 dtk, buktikan dari sisi client (bukan SSH): ping / curl / SSH baru
# 5. setelah 600 dtk: cek auto-unblock
echo 'wazuh' | sudo -S tail -5 /var/ossec/logs/active-responses.log
echo 'wazuh' | sudo -S iptables -S | grep <IP>   # harus tidak ada output
cat /home/wazuh/ar-proof.txt
```

## 5. Bukti Hasil Uji (5 Agu 2026)

### 5.1 Serangan nyata — `58.23.69.251` (brute-force SSH otomatis dari internet)

| Waktu (WIB) | Perintah AR | Hasil |
|---|---|---|
| 03:08:45 | `add` (rule 5551, level 10) | `check_keys` -> IP diblokir -> `Ended` |
| 03:08:47 | `add` (rule 5763, level 10) | `abort` (IP sudah diblokir — dedup) |
| 03:18:48 | `delete` | rule dilepas **tepat 600 detik** kemudian |

### 5.2 Uji terkontrol sintetis — `203.0.113.10`

Injeksi 10 baris `Failed password` -> rule 5763 -> `add` -> `continue` -> `Ended`.
Firewall aktif: `iptables -A INPUT -s 203.0.113.10/32 -j DROP` + FORWARD; nft juga memuat rule drop.
Alert level 10 masuk DB backend (`wazuh_alert_id 1785877418.1636373`, status `new`).

### 5.3 Uji nyata IP client — `182.9.161.37` (blokir dipicu lewat jalur Wazuh)

| Metrik | Sebelum blokir | Setelah blokir |
|---|---|---|
| `ping` | 3/3 reply (~22 ms) | 100% loss |
| `curl https://siemkampus-monitoring-app.duckdns.org` | `HTTP/1.1 200 OK` | timeout (exit 28) |
| koneksi SSH baru (`plink`) | terhubung | timeout |

`active-responses.log` mencatat `add` untuk `182.9.161.37`; rule `-A INPUT -s 182.9.161.37/32 -j DROP`
muncul di iptables; `delete` otomatis setelah 600 detik dan koneksi pulih.

## 6. Verifikasi Tambahan / Cek Rutin

```bash
systemctl is-active wazuh-manager          # harus: active
/var/ossec/bin/agent_control -l           # agent harus Active
tail -50 /var/ossec/logs/active-responses.log
grep -iE 'execd|firewall-drop' /var/ossec/logs/ossec.log
sudo iptables -S | grep -i wazuh           # rule drop saat ada blokir aktif
sudo nft list ruleset | grep -i drop
```

## 7. Peringatan Keamanan

- **Jangan** menguji dengan IP client saat Anda sedang butuh akses server — blokir berlangsung
  `600` detik (default `<timeout>` di ossec.conf) dan memutus **semua** protokol dari IP itu.
- Uji di luar jam kerja, atau gunakan IP uji dokumentasi (`203.0.113.0/24`, `198.51.100.0/24`,
  `192.0.2.0/24`) yang tidak dipakai jaringan nyata.
- IP lain yang sedang terhubung (mis. sesi SSH paralel) **tidak** terpengaruh.
- Jika tidak sengaja terkunci: tunggu 600 detik (auto-unblock), atau hapus manual dari jalur
  lain: `sudo iptables -D INPUT -s <IP> -j DROP && sudo iptables -D FORWARD -s <IP> -j DROP`
  (atau via `nft` bila pakai nftables), dan bersihkan key-nya dari status firewall-drop.
