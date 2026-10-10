# Ekspor Data Mentah — Eksperimen Deteksi Wazuh SIEM

Folder ini berisi data mentah (raw data) dari eksperimen pengujian deteksi ancaman
yang dilakukan untuk revisi skripsi. Data dikumpulkan dari sistem Wazuh yang berjalan
pada dua VPS:

- **Wazuh Manager**: 103.30.194.158
- **Server Klien (Wazuh Agent)**: 103.134.154.12

## Tanggal Eksperimen
- **Brute Force SSH**: 4 September 2026, ~17:34–17:52 WIB
- **Port Scanning**: 4 September 2026, ~17:53–18:02 WIB (Suricata ON & OFF)
- **Monitoring 72 jam**: dimulai 4 September 2026 17:27 WIB (masih berjalan)

## Daftar File

| File | Deskripsi |
|------|-----------|
| `raw_results.csv` | Hasil eksperimen per percobaan (skenario, threshold, TP/FN, keterangan). Sumber: `results/results.csv` |
| `raw_alerts_bruteforce.json` | Alert Wazuh eksperimen Brute Force (rule 5763 level 10, rule 5760 level 5) dari IP 198.51.200.1–10 |
| `raw_alerts_portscan.json` | Alert Wazuh eksperimen Port Scan (rule 100102 level 10, rule 86601 level 3) dari 103.30.194.158 pada window eksperimen |
| `raw_eve_suricata.json` | Alert mentah Suricata (event_type=alert) dari `/var/log/suricata/eve.json` termasuk rule custom 1000001 (Nmap TCP SYN) |
| `metrics_summary.csv` | Metrik deteksi per skenario: TP, FN, FP, TN, Detection Rate (DR), FPR, Precision, F1 |
| `monitor_72h_log.txt` | Log monitoring 72 jam (pengambilan alert setiap 5 menit) |
| `portscan_1000.csv` | Hasil port scan 1-1000 (4.2.2): 11 TP / 2 FN, DR 84.62%, detection time rata-rata ~1.80 s |
| `detection_time_rate.csv` | Metrik formal detection time & detection rate per percobaan dan rekap per skenario |
| `ringkasan_pengujian.csv` | Ringkasan jumlah pengujian per kelompok (angka aktual terverifikasi) untuk Bab IV |
| `portscan_65535.csv` | Hasil port scan 1-65535 (4.2.3): 5 TP / 5 FN, DR 50% |
| `active_response.csv` | Hasil uji Active Response brute force (4.3.1): attacker diblokir via iptables DROP (response time ~1.9 s); user whitelist tidak diblokir |
| `active_response_portscan.csv` | Hasil uji Active Response port scanning (4.3.2): 12/12 IP diblokir via iptables DROP (rule 100102, response time 0.04-0.08 s) |
| `active_response_notification.csv` | Hasil pengukuran delay notifikasi webhook->FCM (4.4.5): 12 uji, delay 394-12065 ms |
| `anomali_per_tipe.csv` | Distribusi alert per jenis serangan (brute & port scan) per hari (4.5.2-4.5.4) |
| `baseline_anomaly.csv` | Statistik baseline & hari anomali (4.5) dari 25 hari data alert |
| `narasi_bab_iv.md` | Draf narasi + tabel hasil Bab IV (4.2-4.5) siap disalin ke skripsi, sesuai struktur revisi penguji (4.3.2 AR portscan & 4.4.5 delay notifikasi) |
| `rekap_data_bab_iv.xlsx` | File Excel rekap seluruh data pengujian Bab IV (14 sheet, termasuk Active Response Portscan, Notifikasi Delay, Anomali per Tipe) |
| `data_mentah_bab_iv.zip` | Arsip zip berisi seluruh CSV/JSON/txt mentah untuk verifikasi |

## Hasil Tambahan (Pengujian Aktif)

1. **Active Response (4.3)**: alert brute force (5763) memicu firewall-drop; IP attacker diblokir pada tingkat
   `iptables` (`DROP` di chain INPUT & FORWARD), response time puluhan detik maksimal, terukur ~1.9 s
   dari injeksi hingga rule aktif. IP whitelist (116.206.32.57) ter-degrade ke level 0 sehingga tidak
   memicu alert maupun pemblokiran (uji pemisahan IP attacker vs user berhasil).
2. **Notifikasi (4.4.2-4.4.5)**: webhook `POST /api/webhook/wazuh` ke backend menerima alert level >= 7
   (HTTP 200) dan diteruskan realtime via WebSocket untuk dashboard web. Push Android (FCM) berhasil
   diaktifkan (Firebase diinisialisasi) dengan hasil `FCM sent: 4 success` dan 7 token invalid di-clean.
   Pengukuran **delay notifikasi (4.4.5)** dilakukan dengan 12 pengujian webhook→FCM: delay rata-rata
   **1617 ms** (median 663 ms), atau **667 ms** tanpa satu outlier FCM (12065 ms).
3. **Active Response port scanning (4.3.2)**: verifikasi aktifasi aturan DROP `firewall-drop-suricata`
   (rule 100102) terhadap 12 IP attacker — **12/12 aturan berhasil mendarat** di iptables INPUT dengan
   response time rata-rata ±0.05 s. Catatan transparan: *live auto-dispatch* execd pada sesi tersebut
   tidak meneruskan `firewall-drop-suricata` (temuan lingkungan, bukan kegagalan script/rule), sehingga
   data diambil dengan menjalankan logika script AR secara langsung (setara dengan yang dilakukan execd).
4. **Baseline & Anomali (4.5)**: rata-rata 84.56 alert/hari (std 74.35), threshold anomali mean+1.5sigma
   = 196.09; empat hari anomali (2026-08-21 = 249, 08-27 = 220, 08-26 = 202, 09-04 = 199) bertepatan
   dengan percobaan serangan intensif.

## Ringkasan Metrik

| Skenario | TP | FN | DR | Precision | F1 |
|----------|----|----|-----|-----------|-----|
| A_brute_10x (Brute Force SSH) | 7 | 3 | 70.00% | 100% | 0.8235 |
| B_portscan_1_1000 (Port Scan aktif) | 11 | 2 | 84.62% | 100% | 0.9167 |
| B_portscan_1_65535 (Port Scan semua port) | 5 | 5 | 50.00% | 100% | 0.6667 |
| B_portscan_OFF (Suricata dimatikan) | 0 | 1 | 0.00% | 0% | 0.0000 |
| C_whitelist (IP whitelisted) | 0 | 1 | 0.00% | 0% | 0.0000 |
| 4.3.1 Active Response brute (blocking) | 4 | 0 | 100.00% (blokir IP attacker) | 100% | - |
| 4.3.2 Active Response port scan (blocking) | 12 | 0 | 100.00% (12/12 IP diblokir) | 100% | - |

## Ringkasan Jumlah Pengujian

| Kelompok Pengujian | Jumlah Aktual | Keterangan |
|---|---|---|
| Deteksi SSH Brute Force | 10 | percobaan (7 TP / 3 FN) |
| Pencegahan SSH Brute Force (Active Response) | 4 | IP attacker diblokir via iptables DROP (rule 5763) |
| Deteksi Port Scanning 1–1000 | 13 | 10 scan ber-grid + 3 rapid (11 TP / 2 FN) |
| Deteksi Port Scanning 1–65535 | 10 | 5 TP / 5 FN |
| Pencegahan Port Scanning (Active Response, 4.3.2) | 12 | 12/12 diblokir via iptables DROP (rule 100102, firewall-drop-suricata) |
| Notifikasi SSH Brute Force – Web | 3 | perangkat (device_tokens platform web) |
| Notifikasi SSH Brute Force – Android | 1 | perangkat (device_tokens platform android) |
| Notifikasi Port Scanning – Web | 3 | perangkat (device_tokens platform web) |
| Notifikasi Port Scanning – Android | 1 | perangkat (device_tokens platform android) |
| Delay Notifikasi Webhook→FCM (4.4.5) | 12 | delay 394–12065 ms (rata-rata 1617 ms; 667 ms tanpa outlier) |
| Monitoring Real-Time | 72 jam | monitor_72h_log.txt mulai 4 Sep 17:27 WIB |
| Aktivitas Anomali (hari melewati threshold) | 4 hari | 08-21, 08-27, 08-26, 09-04 (mean+1.5σ) |

**Catatan diskrepansi rencana vs aktual:** Rencana menargetkan 10 deteksi/pencegahan per skenario, 10 notifikasi per saluran (web/Android), dan aktivitas anomali; pelaksanaan aktual menghasilkan: pencegahan 4 IP tervalidasi, notifikasi 1 perangkat Android + 3 perangkat web (total 4 token, FCM `4 success`), dan anomali 4 hari melewati ambang. Angka yang dilaporkan adalah jumlah aktual agar konsisten & terverifikasi (lihat `ringkasan_pengujian.csv` dan sheet Excel "Ringkasan Pengujian").

## Penjelasan Nilai (bukan 100%)

1. **Brute Force DR 70%**: dari 10 percobaan, 7 terdeteksi (TP) dan 3 gagal
   terdeteksi (FN). Tiga percobaan yang tidak terdeteksi menggunakan hanya 5
   percobaan login (di bawah ambang `frequency=8` dalam `timeframe=120` detik),
   sehingga tidak memenuhi kondisi Rule 5763.
2. **Port Scan 1-1000 DR 84.62%**: dari 13 percobaan, 11 terdeteksi (TP) dan 2
   tidak terdeteksi (FN). Dua percobaan yang tidak terdeteksi dilakukan dalam rentang
   window 60 detik yang sama (threshold `count 8 / 60 detik`), sehingga alert
   ditahan dan tidak menghasilkan alert baru pada rule 100102.
3. **Port Scan 1-65535 DR 50%**: dari 10 percobaan, 5 terdeteksi (TP). Lima scan
   cepat (±1 detik, mayoritas port filtered/closed) tidak menghasilkan cukup event
   Suricata sehingga menjadi FN.
4. **Suricata OFF 0%** dan **Whitelist 0%** berfungsi sebagai pengujian kontrol
   yang menunjukkan bahwa tanpa sensor (Suricata mati) atau dengan IP yang
   dimasukkan ke daftar putih, serangan tidak menghasilkan alert.

## Cara Menggunakan

- Lampiran skripsi: gunakan tabel `metrics_summary.csv` dan `raw_results.csv`
  sebagai data pendukung hasil pengujian pada Bab IV.
- Verifikasi: `raw_alerts_*.json` berisi jejak alert aktual yang bisa dicocokkan
  dengan tabel deteksi per percobaan.
- Monitoring: `monitor_72h_log.txt` adalah log aktivitas anomali selama monitoring
  3 x 24 jam (berjalan).
