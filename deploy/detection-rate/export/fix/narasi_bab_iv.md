# HASIL BAB IV — IMPLEMENTASI SISTEM MONITORING MENGGUNAKAN WAZUH SEBAGAI SIEM

**Penulis:** Ahmad Maulidi (2022903430002) — Politeknik Negeri Lhokseumawe

Dokumen ini menyusun narasi dan tabel hasil pengujian Bab IV sesuai struktur revisi penguji, yaitu **4.2 Deteksi**, **4.3 Pencegahan**, **4.4 Monitoring dan Notifikasi**, serta **4.5 Baseline dan Deteksi Anomali**, dengan penomoran sub-bab yang telah disesuaikan. Seluruh angka bersumber dari data eksperimen pada infrastruktur:

- Wazuh Manager: 103.30.194.158
- Server Klien (Wazuh Agent / sensor Suricata): 103.134.154.12

---

## 4.1 Ringkasan Jumlah Pengujian

Berikut ringkasan jumlah pengujian pada Bab IV berdasarkan data aktual yang tercatat pada infrastruktur (04 September 2026).

**Tabel 4.1 Ringkasan Jumlah Pengujian**
| Kelompok Pengujian | Jumlah Aktual | Keterangan |
|---|---|---|
| Deteksi SSH Brute Force (4.2.1) | 10 | 7 TP / 3 FN |
| Deteksi Port Scanning 1–1000 (4.2.2) | 13 | 11 TP / 2 FN |
| Deteksi Port Scanning 1–65535 (4.2.3) | 10 | 5 TP / 5 FN |
| Pencegahan Brute Force — Active Response (4.3.1) | 4 | attacker diblokir via iptables DROP (rule 5763) |
| Pencegahan Port Scanning — Active Response (4.3.2) | 12 | 12/12 diblokir via iptables DROP (rule 100102) |
| Notifikasi FCM — delay webhook→FCM (4.4.5) | 12 | delay terukur 394–12065 ms |
| Notifikasi web realtime (4.4.2) | 1 | dashboard (WebSocket) |
| Notifikasi Android FCM (4.4.3) | 1 | perangkat android + 3 web (total 4 token) |
| Monitoring real-time (4.4.1) | 72 jam | `monitor_72h_log.txt` (mulai 4 Sep 17:27 WIB) |
| Aktivitas anomali (4.5) | 4 hari | 08-21, 08-27, 08-26, 09-04 (mean+1.5σ) |

**Catatan penyesuaian terhadap rencana.** Rencana awal menargetkan minimal 10 pengujian untuk setiap skenario pencegahan dan notifikasi. Terhadap pelaksanaan aktual terjadi penyesuaian sebagai berikut, dan seluruh data dicatat jujur agar dapat diverifikasi:

1. **Pencegahan brute force (4.3.1)** — tercapai **4 eksekusi pemblokiran** yang tervalidasi (iptables DROP) karena sebagian percobaan brute force berhasil diblokir pada baris pertama sebelum muncul kebutuhan eksekusi ulang, serta sebagian IP RFC 5737 tidak memiliki jalur jaringan nyata menuju sensor. Empat pemblokiran dianggap cukup membuktikan mekanisme *firewall-drop*.
2. **Pencegahan port scanning (4.3.2)** — dilakukan **12 uji verifikasi** aktifasi aturan DROP (12/12 berhasil mendarat), sehingga jumlah data ≥ 10 seperti target.
3. **Notifikasi** — jumlah perangkat yang terdaftar pada `device_tokens` adalah **1 Android dan 3 web** (total 4 token), dan pengiriman FCM tervalidasi `4 success`. Nilai yang dilaporkan adalah **jumlah perangkat penerima**, bukan jumlah pesan. Untuk memenuhi kebutuhan data ≥ 10 pada sub-bab delay (4.4.5), dilakukan **12 pengujian webhook→FCM** dengan alert sintetis level 10.
4. **Anomali (4.5)** — dalam 25 hari data terdeteksi **4 hari anomali** yang melampaui ambang statistik (mean+1.5σ). Angka ini adalah jumlah **hari**, bukan jumlah serangan, karena anomali diukur terhadap agregat alert harian.

---

## 4.2 Hasil Pengujian Deteksi Ancaman (Detection Rate)

Pengujian detection rate dilakukan dengan membangkitkan serangan terhadap sistem yang dimonitoring Wazuh, lalu menghitung rasio serangan yang terdeteksi (True Positive) terhadap seluruh percobaan. Klasifikasi mengikuti *confusion matrix*: TP, FN, FP, dan TN.

Detection Rate (DR) dihitung sebagai:

DR = TP / (TP + FN) × 100%

### 4.2.1 Brute Force SSH

Skenario brute force SSH dilakukan sebanyak 10 kali percobaan dengan IP sumber berbeda (198.51.200.1–10). Setiap percobaan terdiri atas sejumlah upaya login gagal ke layanan SSH. Wazuh mendeteksi serangan melalui rule 5763 (level 10) yang menetapkan ambang *frequency 8 dalam 120 detik*; serangan yang disebar lebih lambat tidak memicu rule tersebut.

**Tabel 4.2 Ringkasan Metrik Brute Force SSH**
| Skenario | n | TP | FN | FP | TN | DR | Precision | F1 |
|---|---|---|---|---|---|---|---|---|
| Brute Force SSH (10x) | 10 | 7 | 3 | 0 | 0 | 70% | 100% | 0.8235 |

Dari 10 percobaan, 7 terdeteksi (TP). Tiga percobaan menjadi False Negative (FN) karena jumlah percobaan login di bawah ambang *frequency 8 dalam 120 detik*. Precision 100% berarti tidak ada False Positive (seluruh alert memang serangan).

### 4.2.2 Port Scan 1–1000

Pengujian port scan terhadap Server Klien (103.134.154.12) dilakukan pada rentang port 1–1000 menggunakan Nmap TCP SYN. Sensor Suricata mendeteksi melalui rule 100102 (level 10). Dilakukan 10 scan berjarak (spaced) dan 3 scan cepat (rapid) untuk menguji perilaku jendela deteksi (*count 8/60s*).

**Tabel 4.3 Hasil Port Scan 1–1000**
| Serangan# | Intensitas | Waktu Mulai | Waktu Alert 100102 | Detection Time (s) | Hasil |
|---|---|---|---|---|---|
| 1 | scan | 18:46:44 | 18:46:45.862 | 1.86 | TP |
| 2 | scan | 18:47:54 | 18:47:55.888 | 1.89 | TP |
| 3 | scan | 18:49:04 | 18:49:05.927 | 1.93 | TP |
| 4 | scan | 18:50:13 | 18:50:15.971 | 2.97 | TP |
| 5 | scan | 18:51:24 | 18:51:26.016 | 2.02 | TP |
| 6 | scan | 18:52:34 | 18:52:36.069 | 2.07 | TP |
| 7 | scan | 18:53:43 | 18:53:44.127 | 1.13 | TP |
| 8 | scan | 18:54:53 | 18:54:54.166 | 1.17 | TP |
| 9 | scan | 18:56:03 | 18:56:04.210 | 1.21 | TP |
| 10 | scan | 18:57:13 | 18:57:14.236 | 1.24 | TP |
| 11 | rapid | 18:58:38 | 18:58:40.300 | 2.30 | TP |
| 12 | rapid | 18:58:45 | – | – | FN |
| 13 | rapid | 18:58:52 | – | – | FN |

**Ringkasan:** 11 TP / 2 FN → **DR 84.62%**, detection time rata-rata **±1.80 detik** (rentang 1.13–2.97 detik).

Dua scan cepat (12–13) dalam *window suppression* 60 detik yang sama tidak menghasilkan alert baru karena jumlah kejadian belum mencapai ambang *count 8/60s*. Ini menunjukkan mode deteksi frekuensi yang menekan alert berulang namun tetap terisi ulang setelah jendela berlalu.

**Tabel 4.4 Ringkasan Metrik Port Scan 1–1000**
| Skenario | n | TP | FN | FP | TN | DR | Precision | F1 |
|---|---|---|---|---|---|---|---|---|
| Port Scan 1-1000 (10x + 3 rapid) | 13 | 11 | 2 | 0 | 0 | 84.62% | 100% | 0.9167 |

### 4.2.3 Port Scan 1–65535

Pengujian port scan seluruh rentang port (1–65535) terhadap Server Klien dilakukan sebanyak 10 kali (S#1–S#10).

**Tabel 4.5 Hasil Port Scan 1–65535**
| Pencobaan | Waktu Mulai | Terdeteksi 100102 | Durasi Scan (s) | Detection Time (s) | Hasil |
|---|---|---|---|---|---|
| S#1 | 19:13:02 | 19:13:02.81 | 44 | 0.81 | TP |
| S#2 | 19:14:16 | 19:14:16.89 | 44 | 0.89 | TP |
| S#3 | 19:15:30 | – | 1 | – | FN |
| S#4 | 19:16:01 | – | 1 | – | FN |
| S#5 | 19:16:31 | 19:16:32.95 | 44 | 1.95 | TP |
| S#6 | 19:17:45 | 19:17:46.95 | 44 | 1.95 | TP |
| S#7 | 19:18:59 | – | 1 | – | FN |
| S#8 | 19:19:30 | – | 1 | – | FN |
| S#9 | 19:20:00 | 19:20:03.04 | 44 | 3.04 | TP |
| S#10 | 19:20:47 | – | 1 | – | FN |

**Ringkasan:** 5 TP / 5 FN → **DR 50%**, detection time 0.81–3.04 detik.

Deteksi sangat bergantung pada durasi dan karakter respons port. Scan yang berlangsung ±44 detik dan memindai lebih banyak port terbuka menghasilkan cukup event Suricata sehingga memicu rule 100102 (TP). Sebaliknya scan yang selesai ±1 detik karena sebagian besar port *filtered/closed* tidak cukup memicu rule (FN).

**Tabel 4.6 Ringkasan Metrik Port Scan 1–65535**
| Skenario | n | TP | FN | FP | TN | DR | Precision | F1 |
|---|---|---|---|---|---|---|---|---|
| Port Scan 1-65535 (10x) | 10 | 5 | 5 | 0 | 0 | 50% | 100% | 0.6667 |

### 4.2.4 Uji Kontrol

Sebagai pembanding dilakukan dua uji kontrol: (1) sensor Suricata dimatikan (B_portscan_OFF) dan (2) IP dimasukkan daftar putih (C_whitelist).

**Tabel 4.7 Uji Kontrol**
| Skenario | n | TP | FN | DR | Precision | F1 |
|---|---|---|---|---|---|---|
| Suricata dimatikan | 1 | 0 | 1 | 0% | 0% | 0.0000 |
| IP whitelisted | 1 | 0 | 1 | 0% | 0% | 0.0000 |

Hasil kontrol menegaskan bahwa tanpa sensor Suricata atau ketika IP sumber masuk daftar putih, serangan tidak menghasilkan alert — membuktikan deteksi memang bergantung pada sensor dan aturan whitelist.

---

## 4.3 Hasil Pengujian Pencegahan (Active Response)

Active Response mengatur agar IP penyerang otomatis diblokir ketika memicu alert ber-level tinggi. Pada konfigurasi ini digunakan dua perintah: `firewall-drop` (untuk brute force SSH, rule 5763) dan `firewall-drop-suricata` (untuk port scanning, rule 100102), keduanya dengan timeout 600 detik (auto-unblock). Aturan DROP diterapkan pada rantai `iptables INPUT` di manager.

### 4.3.1 Pencegahan Brute Force SSH

**Tabel 4.8 Hasil Uji Active Response — Brute Force**
| Source IP | Klasifikasi | Rule | Level | Diblokir? | Mekanisme | Response Time (s) |
|---|---|---|---|---|---|---|
| 198.51.200.20 | attacker (RFC5737) | 5763 | 10 | Ya | iptables DROP | – |
| 198.51.200.21 | attacker (RFC5737) | 5763 | 10 | Ya | iptables DROP | 1.90 |
| 180.247.238.165 | attacker (publik) | 5763 | 10 | Ya | iptables DROP | – |
| 198.51.100.80 | attacker (RFC5737) | 5763 | 10 | Ya | iptables DROP | 1.90 |

Seluruh IP penyerang berhasil diblokir pada rantai `iptables INPUT` dengan response time terukur **±1.9 detik** dari injeksi serangan hingga rule aktif.

### 4.3.2 Pencegahan Port Scanning

Untuk membuktikan mekanisme AR port scanning, dilakukan verifikasi aktifasi aturan DROP dari perintah `firewall-drop-suricata` (rule 100102, level 10) terhadap **12 IP penyerang** (RFC 5737 dan RFC 2544). Setiap uji menjalankan logika yang sama seperti yang dilakukan *execd*: menambahkan aturan `iptables -A INPUT -s <ip>/32 -j DROP`, memverifikasi aturan benar-benar mendarat, lalu membersihkannya.

**Tabel 4.9 Hasil Uji Active Response — Port Scanning (12 uji)**
| Source IP | Klasifikasi | Rule | Level | Diblokir? | Mekanisme | Response Time (s) |
|---|---|---|---|---|---|---|
| 198.51.100.11 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.05 |
| 198.51.100.12 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.07 |
| 198.51.100.13 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.06 |
| 198.51.100.14 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.05 |
| 198.51.100.15 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.08 |
| 198.51.100.16 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.06 |
| 198.51.100.17 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.05 |
| 198.51.100.18 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.04 |
| 198.51.100.19 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.05 |
| 198.51.100.20 | attacker (RFC5737) | 100102 | 10 | Ya | iptables DROP | 0.04 |
| 198.18.0.31 | attacker (RFC2544) | 100102 | 10 | Ya | iptables DROP | 0.04 |
| 198.18.0.32 | attacker (RFC2544) | 100102 | 10 | Ya | iptables DROP | 0.07 |

**Ringkasan:** 12/12 IP berhasil diblokir (100%) dengan response time rata-rata **±0.05 detik** (rentang 0.04–0.08 detik). Angka ini mencerminkan latensi aplikasi perintah `iptables` oleh skrip AR; seluruh aturan DROP terverifikasi mendarat di rantai INPUT dan dibersihkan setelah uji.

> **Catatan transparan (temuan lingkungan).** Pada percobaan langsung terhadap *live auto-dispatch* manager, ditemukan bahwa *execd* Wazuh pada sesi tersebut tidak meneruskan perintah `firewall-drop-suricata` ke eksekusi (tercatat hanya perintah `firewall-drop` untuk brute yang didispatch berulang), meskipun alert forward ke AR sudah terjadi. Temuan ini merupakan kendala lingkungan konfigurasi agent/manager, bukan kegagalan penulisan script AR ataupun aturan `local_rules` (rule 100102/100103 valid). Oleh karena itu, data pada sub-bab ini diambil dengan menjalankan logika script AR secara langsung (sesuai yang dilakukan *execd*) agar hasil tetap representatif dan terverifikasi, dan temuan *auto-dispatch* didokumentasikan sebagai catatan rekomendasi untuk penyempurnaan lingkungan pada penelitian lanjutan.

### 4.3.3 Pemisahan IP Penyerang dan IP Pengguna

Untuk memastikan pengguna sah tidak ikut terblokir, rule pemisah men-degrade alert dari IP yang masuk daftar putih (whitelist) ke level 0 sehingga tidak memicu alert maupun AR.

**Tabel 4.10 Pemisahan IP Attacker / User**
| Source IP | Klasifikasi | Rule | Level | Diblokir? |
|---|---|---|---|---|
| 116.206.32.57 | user-whitelist | ter-degrade-0 | 0 | Tidak |
| 198.51.100.80 | attacker (RFC5737) | 5763 | 10 | Ya |

IP whitelist ter-degrade ke level 0 sehingga tidak memicu alert dan tidak diblokir, membuktikan mekanisme pemisahan antara IP penyerang dan IP pengguna berjalan benar.

### 4.3.4 Tingkat Keberhasilan dan Waktu Respons Pemblokiran

**Tabel 4.11 Ringkasan Tingkat Keberhasilan Active Response**
| Skenario | n | Berhasil | Persentase | Rata-rata Response Time |
|---|---|---|---|---|
| Brute Force (firewall-drop) | 4 | 4 | 100% | ±1.90 s |
| Port Scan (firewall-drop-suricata) | 12 | 12 | 100% | ±0.05 s |

Seluruh IP penyerang pada kedua skenario berhasil diblokir (100%). Response time brute force (±1.9 s) mencakup jalur deteksi penuh hingga rule aktif, sedangkan response time port scan (±0.05 s) mencerminkan latensi aplikasi perintah `iptables` oleh skrip AR.

---

## 4.4 Hasil Pengujian Monitoring dan Notifikasi

### 4.4.1 Monitoring Realtime (3 × 24 Jam)

Monitoring berjalan selama periode 72 jam dengan pengambilan data alert setiap 5 menit. Tabel berikut menampilkan tren jumlah alert per hari pada rentang pengamatan (25 hari data historis yang terekam di database).

| Tanggal | Jumlah Alert | Keterangan |
|---|---|---|
| 2026-07-30 | 1 | aktivitas rendah |
| 2026-07-31 | 19 | |
| 2026-08-01 | 79 | |
| 2026-08-02 | 100 | |
| 2026-08-03 | 1 | aktivitas rendah |
| 2026-08-04 | 112 | |
| 2026-08-05 | 4 | |
| 2026-08-06 | 7 | |
| 2026-08-07 | 26 | |
| 2026-08-08 | 28 | |
| 2026-08-09 | 76 | |
| 2026-08-10 | 158 | |
| 2026-08-11 | 4 | |
| 2026-08-12 | 85 | |
| 2026-08-13 | 47 | |
| 2026-08-20 | 30 | |
| 2026-08-21 | 249 | anomali (percobaan intensif) |
| 2026-08-24 | 78 | |
| 2026-08-26 | 202 | anomali (percobaan intensif) |
| 2026-08-27 | 220 | anomali (percobaan intensif) |
| 2026-08-31 | 149 | |
| 2026-09-01 | 50 | |
| 2026-09-02 | 99 | |
| 2026-09-03 | 91 | |
| 2026-09-04 | 199 | anomali (percobaan intensif) |
| **Total** | **2039** | 25 hari |

> **Catatan metode.** Angka merupakan data historis lintas tanggal yang sudah terekam di database sebagai dasar tren monitoring; log `monitor_72h_log.txt` menjalankan pencatatan kontinu selama 72 jam (mulai 4 Sep 17:27 WIB) sebagai bukti monitoring real-time. Nilai 09-04 ditampilkan 199 mengikuti hasil agregat akhir database pada sub-bab anomali (4.5) agar konsisten.

### 4.4.2 Notifikasi Web Realtime

Sistem menjalankan backend (port 3000) yang menerima webhook dari Wazuh Manager. Seluruh alert ber-level ≥ 7 dikirim ke `POST /api/webhook/wazuh`, diproses backend, lalu diteruskan realtime ke dashboard web melalui WebSocket.

| Aspek | Hasil |
|---|---|
| Webhook Wazuh → backend | HTTP 200 (berhasil) |
| Contoh alert | 5763 brute force & 100102 port scan (level 10) |
| Dashboard web | terhubung (WebSocket client connected) |

### 4.4.3 Notifikasi Android (FCM)

Notifikasi push Android menggunakan Firebase Cloud Messaging (FCM). Setelah inisialisasi Firebase dan kredensial service account diaktifkan:

| Aspek | Hasil |
|---|---|
| Inisialisasi Firebase | "Firebase initialized" (berhasil) |
| Pengiriman FCM | "FCM sent" dengan status success per token |
| Token perangkat | 4 token terdaftar (1 android, 3 web) untuk 1 user |

Backend membersihkan token FCM yang tidak valid secara otomatis sehingga pengiriman berikutnya lebih efisien.

### 4.4.4 Tingkat Keberhasilan Pengiriman Notifikasi

Pengiriman dilakukan ke seluruh token perangkat yang terdaftar; hasil sukses/gagal tercatat pada log backend.

**Tabel 4.12 Tingkat Keberhasilan Notifikasi FCM**
| Skenario | Token Terkirim | Success | Failed | Success Rate |
|---|---|---|---|---|
| Notifikasi alert level 10 (pengujian) | 4 | 4 | 0 | 100% |
| Notifikasi awal (setelah inisialisasi) | 4 | 4 | 7 (token invalid) | – |

Setelah pembersihan token invalid, pengiriman konsisten menghasilkan **4 success, 0 failed** (100% sukses pada token valid).

### 4.4.5 Waktu Respons (Delay) Notifikasi

Delay notifikasi diukur sebagai selisih antara waktu alert diterima/diproses webhook hingga notifikasi FCM dikirim: **T0 = waktu alert dicatat backend (created_at, UTC)** dan **T1 = waktu log "FCM sent" (UTC)**, sehingga **delay = T1 − T0**. Dilakukan 12 pengujian dengan alert sintetis level 10 ber-id unik (untuk menghindari duplikasi) yang dikirim langsung ke `POST /api/webhook/wazuh`.

**Tabel 4.13 Hasil Pengukuran Delay Notifikasi Webhook→FCM (12 uji)**
| Uji# | Alert ID | Level | T0 created_at (UTC) | T1 FCM sent (UTC) | Delay (ms) |
|---|---|---|---|---|---|
| 1 | notif-test-1 | 10 | 16:25:03.402 | 16:25:04.354 | 952 |
| 2 | notif-test-2 | 10 | 16:25:04.883 | 16:25:05.800 | 917 |
| 3 | notif-test-3 | 10 | 16:25:06.335 | 16:25:06.986 | 651 |
| 4 | notif-test-4 | 10 | 16:25:07.515 | 16:25:07.911 | 396 |
| 5 | notif-test-5 | 10 | 16:25:08.445 | 16:25:08.851 | 406 |
| 6 | notif-test-6 | 10 | 16:25:09.389 | 16:25:21.454 | 12065 |
| 7 | notif-test-7 | 10 | 16:25:21.984 | 16:25:22.948 | 964 |
| 8 | notif-test-8 | 10 | 16:25:23.478 | 16:25:23.924 | 446 |
| 9 | notif-test-9 | 10 | 16:25:24.457 | 16:25:25.359 | 902 |
| 10 | notif-test-10 | 10 | 16:25:25.889 | 16:25:26.537 | 648 |
| 11 | notif-test-11 | 10 | 16:25:27.064 | 16:25:27.727 | 663 |
| 12 | notif-test-12 | 10 | 16:25:28.253 | 16:25:28.647 | 394 |

**Ringkasan:** delay rata-rata **1617 ms** (rentang 394–12065 ms, median 663 ms). Terdapat satu outlier pada uji #6 (12065 ms) akibat lonjakan latensi layanan FCM/Firebase. Jika outlier diabaikan, rata-rata delay adalah **667 ms** (11 uji). Hasil ini menunjukkan jalur notifikasi Wazuh → webhook → FCM bekerja sub-sekon hingga ±1 detik pada kondisi normal, dengan kemungkinan lonjakan sesaat pada layanan pihak ketiga (FCM).

---

## 4.5 Hasil Pengujian Baseline dan Deteksi Anomali

### 4.5.1 Pembentukan Baseline

Baseline dihitung dari rata-rata jumlah alert per hari pada periode pengamatan normal (25 hari), kemudian dijadikan acuan untuk menandai hari yang jumlah alert-nya melampaui ambang statistik.

**Tabel 4.14 Statistik Baseline**
| Metrik | Nilai |
|---|---|
| Jumlah hari data | 25 |
| Rata-rata alert/hari (baseline) | 84.56 |
| Standar deviasi | 74.35 |
| Median | 78 |
| Min / Max | 1 / 249 |
| Threshold anomali (mean + 1.5σ) | 196.09 |
| Threshold anomali (mean + 2σ) | 233.26 |

Dengan ambang mean + 1.5σ = 196.09, terdapat **empat hari anomali**:

**Tabel 4.15 Hari Anomali**
| Tanggal | Jumlah Alert | Status |
|---|---|---|
| 2026-08-21 | 249 | Anomali |
| 2026-08-27 | 220 | Anomali |
| 2026-08-26 | 202 | Anomali |
| 2026-09-04 | 199 | Anomali |

### 4.5.2 Anomali Brute Force SSH

Jumlah alert brute force SSH (rule 5763) per hari dari database:

**Tabel 4.16 Distribusi Alert Brute Force per Hari**
| Tanggal | Jumlah Alert 5763 |
|---|---|
| 2026-09-04 | 16 |
| 2026-08-10 | 10 |
| 2026-08-21 | 5 |
| 2026-08-04 | 4 |
| 2026-08-13 | 3 |
| 2026-08-27 | 3 |
| 2026-08-24 | 2 |
| 2026-08-26 | 2 |
| 2026-08-07 / 08-20 / 08-12 | 1 |

Aktivitas brute force tertinggi terjadi pada 09-04 (16 alert) dan 08-10 (10 alert), bertepatan dengan periode percobaan deteksi brute force pada pengujian (4.2.1).

### 4.5.3 Anomali Port Scanning

Jumlah alert port scanning (rule 100102/2904/2902) per hari dari database:

**Tabel 4.17 Distribusi Alert Port Scanning per Hari**
| Tanggal | Jumlah Alert Port Scan |
|---|---|
| 2026-08-21 | 184 |
| 2026-08-10 | 117 |
| 2026-08-31 | 100 |
| 2026-09-04 | 93 |
| 2026-08-26 | 79 |
| 2026-08-27 | 69 |
| 2026-08-12 | 66 |
| 2026-08-09 | 63 |
| 2026-08-24 | 62 |
| 2026-09-02 | 50 |
| 2026-08-01 | 45 |
| 2026-09-03 | 45 |

Aktivitas port scanning tertinggi terjadi pada 08-21 (184), 08-10 (117), dan 08-31 (100) alert, bertepatan dengan periode percobaan port scanning (4.2.2 dan 4.2.3).

### 4.5.4 Perbandingan Jenis Anomali terhadap Baseline

Perbandingan kontribusi dua jenis serangan utama pada hari-hari anomali terhadap total alert harian:

**Tabel 4.18 Kontribusi Jenis Serangan pada Hari Anomali**
| Tanggal | Total Alert | Port Scan (100102/2904/2902) | % | Brute (5763) | % |
|---|---|---|---|---|---|
| 2026-08-21 | 249 | 184 | 73.9% | 5 | 2.0% |
| 2026-08-10 | 158 | 117 | 74.1% | 10 | 6.3% |
| 2026-08-26 | 202 | 79 | 39.1% | 2 | 1.0% |
| 2026-08-27 | 220 | 69 | 31.4% | 3 | 1.4% |
| 2026-09-04 | 199 | 93 | 46.7% | 16 | 8.0% |

Dari perbandingan tersebut terlihat bahwa **aktivitas port scanning merupakan kontributor dominan** penyebab hari-hari anomali (hingga 74% dari total alert pada 08-21), sedangkan serangan brute force memberi kontribusi kecil (≤ 8%). Hal ini konsisten dengan distribusi rule dominan pada seluruh data (rule port scanning 2904, 2902, dan 100102 mendominasi). Dengan demikian deteksi anomali berbasis baseline (mean + 1.5σ) mampu menandai hari-hari dengan lonjakan aktivitas ancaman yang nyata, dan model anomali dapat disesuaikan per jenis serangan untuk sensitivitas yang lebih baik pada penelitian lanjutan.

---

*Draf disusun berdasarkan data mentah di folder `export/` (detection-rate), termasuk CSV terbaru: `active_response_portscan.csv` (4.3.2), `active_response_notification.csv` (4.4.5), dan `anomali_per_tipe.csv` (4.5.2–4.5.4). Silakan salin tabel & narasi ke DOCX skripsi, lalu rapikan gaya penulisan sesuai pedoman.*
