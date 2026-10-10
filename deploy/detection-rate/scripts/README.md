# Data Collection Scripts - Eksperimen Skripsi

Script untuk mengumpulkan data mentah eksperimen Wazuh SIEM:
SSH Brute Force & Port Scanning.

## Arsitektur

```
VPS Manager (103.30.194.158)          VPS Agent (103.134.154.12)
┌─────────────────────────────┐      ┌─────────────────────────────┐
│  Wazuh Manager              │      │  Wazuh Agent               │
│  Backend + PostgreSQL       │      │  Suricata                  │
│  Scripts berikut (bash)     │      │  auth.log (target)         │
└─────────────────────────────┘      └─────────────────────────────┘
```

## Script List

| Script | Fungsi | Output |
|--------|--------|--------|
| `attack-brute.sh` | Melakukan 15 percobaan SSH brute force | `brute_force_log.csv` |
| `attack-portscan.sh` | Melakukan 20 percobaan port scanning | `portscan_log.csv` |
| `collect-detection.sh` | Kumpulkan status deteksi (TP/FN) | `detection_data.csv` |
| `collect-prevention.sh` | Kumpulkan status pencegahan (block) | `prevention_data.csv` |
| `collect-notification.sh` | Kumpulkan timing notifikasi | `notification_data.csv` |
| `monitor-72h.sh` | Monitoring 3x24 jam | `monitoring_72h.csv` |
| `run-experiment.sh` | Master script (jalankan semua sekaligus) | Semua output |

## Alur Penggunaan

### Cara Cepat (Rekomendasi)

1. Copy semua script ke VPS Manager:
   ```bash
   scp -r scripts/* wazuh@103.30.194.158:/home/wazuh/scripts/
   ```

2. Jalankan eksperimen lengkap:
   ```bash
   ssh wazuh@103.30.194.158
   cd /home/wazuh/scripts
   sudo bash run-experiment.sh
   ```

3. Setelah selesai, jalankan monitoring 72 jam:
   ```bash
   nohup sudo bash monitor-72h.sh 72 > /home/wazuh/results/monitor_72h_stdout.log 2>&1 &
   ```

4. Ambil hasil:
   ```bash
   scp -r wazuh@103.30.194.158:/home/wazuh/results/ ./results/
   ```

### Cara Manual

Jalankan script satu per satu:

```bash
# 1. SSH Brute Force (15 percobaan, ~30 menit karena spacing 120s)
sudo bash attack-brute.sh

# 2. Port Scanning (20 percobaan, ~15 menit)
sudo bash attack-portscan.sh

# 3. Kumpulkan data (setelah serangan selesai)
sudo bash collect-detection.sh
sudo bash collect-prevention.sh
sudo bash collect-notification.sh

# 4. Monitoring 72 jam
nohup sudo bash monitor-72h.sh 72 > monitor_72h_stdout.log 2>&1 &
```

## Output CSV Format

### detection_data.csv
```
No,Aktivitas,Waktu Aktivitas,Waktu Alert,Status Deteksi
1,SSH Brute Force,2026-09-07 17:34:00,2026-09-07 17:34:02,TP
2,Port Scan 1-1000,2026-09-07 18:00:00,2026-09-07 18:00:02,TP
```

### prevention_data.csv
```
No,Aktivitas,IP Attacker,IP Pengguna,Status Block,Status Akses Pengguna
1,SSH Brute Force,192.0.2.1,116.206.32.57,Berhasil,Normal
```

### notification_data.csv
```
No,Aktivitas,Waktu Alert Wazuh,Waktu Diterima Web,Waktu Diterima Android
1,SSH Brute Force,2026-09-07 17:34:02,2026-09-07 17:34:03,2026-09-07 17:34:09
```

### monitoring_72h.csv
```
No,Waktu,IP Sumber,Aktivitas,Alert,Active Response,Status Block,Notifikasi
1,2026-09-07 17:27:00,-,-,Tidak Ada,Tidak Ada,Normal,-
```

## Threshold yang Dituju

| Komponen | Threshold |
|----------|-----------|
| SSH Brute Force | 8 gagal login / 120 detik |
| Port Scanning | 8+ SYN packet / 60 detik / source IP |
| Active Response | firewall-drop (iptables DROP) / 600 detik |
| IP Pengguna | Whitelist 116.206.32.57 |
| IP Attacker | Block via iptables |
| Anomaly | Alert count > 196.09 / hari |

## Catatan Penting

1. **Jalankan di VPS Manager**, bukan di agent
2. **Perlu sudo** untuk inject dan baca log
3. **Pastikan Suricata aktif** di VPS Agent sebelum portscan test
4. **Pastikan backend + PostgreSQL aktif** untuk data notifikasi
5. **IP attacker menggunakan RFC 5737** (192.0.2.0/24) yang tidak ter-whitelist
6. **IP pengguna**: 116.206.32.57 (whitelist) harus tetap bisa akses server
7. Hasil FP/TN adalah **data valid** untuk analisis detection rate
8. Monitoring 72 jam harus jalan **terpisah** dari eksperimen serangan