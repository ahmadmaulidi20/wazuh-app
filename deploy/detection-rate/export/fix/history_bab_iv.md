# History / Ringkasan Kerja — Bab IV Skripsi Wazuh SIEM

> Dibuat: 05 September 2026
> Proyek: `deploy/detection-rate` — revisi skripsi "Implementasi Sistem Monitoring Menggunakan Wazuh sebagai SIEM"
> Penulis: Ahmad Maulidi (2022903430002)

Catatan ini merangkum status, keputusan, dan hasil kerja Bab IV (4.2–4.5) sesuai struktur revisi penguji, agar sesi berikutnya dapat melanjutkan tanpa kehilangan konteks.

---

## 1. Tujuan

Menyusun lengkap Bab IV (deteksi, pencegahan, monitoring/notifikasi, anomali) sesuai **struktur revisi penguji**, menggabungkan data yang sudah ada + eksperimen baru (AR portscan 4.3.2, notification delay 4.4.5). Tiap sub-bab deteksi/pencegahan/notifikasi **minimal 10 data pengujian**, angka jujur/terverifikasi.

## 2. Struktur Bab IV (wajib penguji)

- **4.2 Deteksi**: 4.2.1 brute SSH, 4.2.2 portscan 1–1000, 4.2.3 portscan 1–65535, (4.2.4 uji kontrol)
- **4.3 Pencegahan (AR)**: 4.3.1 AR brute, **4.3.2 AR portscan**, 4.3.3 pemisahan IP attacker/user, 4.3.4 blocking success rate + response time
- **4.4 Monitoring & Notifikasi**: 4.4.1 monitoring 3×24, 4.4.2 web, 4.4.3 android (FCM), 4.4.4 success rate, **4.4.5 delay**
- **4.5 Anomali**: 4.5.1 baseline, 4.5.2 anomali brute, 4.5.3 anomali portscan, 4.5.4 perbandingan baseline

## 3. Infrastruktur

- VPS Manager `wazuh@103.30.194.158:22` (load tinggi ~7–8 → SSH flaky, retry perlu)
- Backend docker `deploy-backend-1` (WorkDir `/app`, image `deploy-backend`), DB `deploy-postgres-1` (db `wazuh_monitor`)
- VPS Agent `server@103.134.154.12:2221` (Suricata aktif, `HOME_NET=10.228.87.0/24`, target `103.134.154.12`)
- AR config: `firewall-drop` (brute, rule 5763), `firewall-drop-suricata` (portscan, rule 100102/100103), location local, timeout 600; block mendarat di iptables manager
- Integration model (level 7 via `ossec.conf` → webhook localhost:3000)

## 4. Keputusan Kunci (disetujui user)

1. **4.3.2 AR Portscan** → eksperimen baru di VPS; user memilih **"Tulis dgn data terbukti"** (bukan menunggu real attacker karena traffic real berhenti + live auto-dispatch execd rusak).
2. **4.4.1 Monitoring** → pakai tren historis 25 hari + catatan transparan monitoring berjalan.
3. **4.4.5 Notification Delay** → ukur delay dari pengujian webhook–FCM baru (12 data).
4. Semua Detection Rate < 100% dan data jujur (brute 70%, portscan 1-1000 84.62% F1 0.9167, portscan 1-65535 50% F1 0.6667).

## 5. Hasil Terkini (Selesai)

### 5.0 Status Todo
- [x] Notification Delay (4.4.5) — 12 data, CSV dibuat
- [x] Anomali per-tipe (anomali_per_tipe.csv) — dibuat dari query terverifikasi
- [x] Narasi Bab IV lengkap (narasi_bab_iv.md) — struktur penguji
- [x] Deliverables (xlsx, ringkasan, zip, README) — diperbarui

### 5.1 Notification Delay (4.4.5) — 12 data
Metode: Wazuh `<integration>` mengirim alert level ≥ 7 ke `POST /api/webhook/wazuh`; 12 alert sintetis level 10 (id unik agar tidak dedup) di-POST dengan API key. Delay = **T1 (log backend "FCM sent", UTC) − T0 (`alerts.created_at`, UTC)**.

Rentang **394–12065 ms**, median **663 ms**, rata-rata **1617 ms**; tanpa 1 outlier FCM (12065 ms) rata-rata **667 ms**.
- File: `export/active_response_notification.csv`

### 5.2 Anomali per Tipe
Query DB terverifikasi:
- Brute (rule 5763): 09-04=16, 08-10=10, 08-21=5, 08-04=4, 08-13=3, 08-27=3, 08-24=2, 08-26=2, 07/20/12=1
- Portscan (100102/2904/2902): 08-21=184, 08-10=117, 08-31=100, 09-04=93, 08-26=79, 08-27=69, 08-12=66, 08-09=63, 08-24=62, 09-02=50, 08-01=45, 09-03=45
- File: `export/fix/anomali_per_tipe.csv`

### 5.3 Metrik final
- Brute 7/3 = 70% (F1 0.8235); Portscan 1-1000 11/2 = 84.62% (F1 0.9167); Portscan 1-65535 5/5 = 50% (F1 0.6667)
- AR brute 4/4 = 100% (response ±1.9 s); AR portscan 12/12 = 100% (response ±0.05 s)
- Baseline 25 hari: mean 84.56, std 74.35, median 78, threshold mean+1.5σ = 196.09 / +2σ = 233.26; 4 hari anomali (08-21=249, 08-27=220, 08-26=202, 09-04=199)
- Kontribusi jenis pada hari anomali: tanggal=total, portscan %, brute % → 08-21=249/184/74%/5/2%, 08-10=158/117/74%/10/6%, 08-26=202/79/39%/2/1%, 08-27=220/69/31%/3/1%, 09-04=199/93/47%/16/8%. **Portscan dominan.**

## 6. Temuan/Kendala Lingkungan (dokumentasi transparan)

- **Live auto-dispatch execd untuk `firewall-drop-suricata` rusak** pada sesi (hanya `firewall-drop` brute yang di-dispatch), meski alert forward ke AR sudah terjadi. Bukan kegagalan script/rule (rule 100102/100103 valid). Data 4.3.2 diambil dengan menjalankan logika script AR langsung (setara execd) — didokumentasikan di narasi sebagai rekomendasi lanjutan.
- SSH manager flaky (load tinggi), timeout random → retry.
- Excel COM di lingkungan lokal **rusak** (`TYPE_E_CANTLOADLIBRARY`) → xlsx dikelola via edit OOXML + rezip manual (wajib nama part pakai garis miring `/`, `[Content_Types].xml` pertama).
- Backend log winston ber-timestamp (UTC); `alerts.created_at` = `CURRENT_TIMESTAMP` (UTC), `alerts.timestamp` = Wazuh (WIB).
- `crontab` manager tidak terpasang; background process via plink tidak persist.

## 7. Deliverables & Lokasi File

Folder `deploy/detection-rate/export/` (data mentah) & `export/fix/` (hasil final):

| File | Isi |
|---|---|
| `narasi_bab_iv.md` | Narasi + tabel Bab IV lengkap (4.2–4.5) siap disalin, struktur penguji |
| `rekap_data_bab_iv.xlsx` | 14 sheet (incl. Active Response Portscan, Notifikasi Delay, Anomali per Tipe, Ringkasan Pengujian) |
| `active_response_portscan.csv` | Data 4.3.2 (12 baris: 12/12 diblokir) |
| `active_response_notification.csv` | Data 4.4.5 (12 baris delay) |
| `anomali_per_tipe.csv` | Distribusi brute & portscan per hari (4.5.2–4.5.4) |
| `ringkasan_pengujian.csv` | Rekap jumlah pengujian (perbaruan 4.3.2=12, 4.4.5=12) |
| `baseline_anomaly.csv` | Statistik baseline & hari anomali (4.5) |
| `data_mentah_bab_iv.zip` | Arsip 15 file mentah (termasuk CSV baru) |
| `README.md` | Dokumentasi folder (diperbarui) |
| `screenshots/` | Bukti visual (01–06 + dashboard_login) |

## 8. Rekomendasi / Langkah Berikutnya

1. **Validasi visual oleh user** (model tidak dapat melihat gambar): buka PNG di `screenshots/` — `01_portscan`, `02_bruteforce`, `03_active_response`, `04_monitoring`, `05_notifikasi`, `06_baseline`, `dashboard_login`.
2. Salin tabel & narasi dari `narasi_bab_iv.md` ke DOCX skripsi, rapikan gaya penulisan sesuai pedoman.
3. (Opsional, lanjutan) Perbaiki auto-dispatch execd `firewall-drop-suricata` di lingkungan untuk validasi AR end-to-end penuh pada penelitian berikutnya.
4. (Opsional) Ganti IP RFC 5737/2544 pada beberapa tabel dengan IP publik riil penyerang jika ada capture baru.
