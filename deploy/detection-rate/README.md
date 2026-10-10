# Wazuh Detection Rate Experiment

Eksperimen untuk mengukur **detection rate** Wazuh (True Positive / False Negative / False Positive / True Negative)
melalui dua mekanisme deteksi: SSH brute-force & port scan (Suricata).

## Konteks

- **VPS Manager**: `wazuh@103.30.194.158` (Wazuh manager + backend, sudo passwordless)
- **VPS Agent**: `server@103.134.154.12:2221` (wazuh-agent + Suricata, sudo passwordless, internal `10.228.87.3` via `ens3`)
- **Target serangan**: VPS Agent (`103.134.154.12`)
- **Sumber serangan**: VM VirtualBox (jaringan terpisah), alat dijalankan manual
- **Deteksi diukur di**: VPS Manager (`/var/ossec/logs/alerts/alerts.json` + backend DB)
- **Ground truth**: `tcpdump` SYN di `ens3` (agent) + `eve.json`/`fast.log` (Suricata)

## Skenario

### A. SSH brute-force — tuning `frequency` rule 5712/5763/5551 di manager
nilai freq `4 · 8 · 16`, intensitas serangan lemah/sedang/kuat, repetisi 3x.

### B. Port scan — Suricata ON/OFF
- `ON`: `nmap -sS <target>` -> rule 100102/100103 -> TP
- `OFF`: `systemctl stop suricata` -> scan -> manajer tanpa alert -> FN
- `ON + traffic normal`: multi-port -> over-trigger? -> FP

### C. Efek whitelist (`116.206.33.54` & `116.206.32.57`)
Serangan dari IP yang di-whitelist -> rule level 0 -> FN (sengaja).

## Metrik

| Metrik | Rumus |
|--------|-------|
| Detection Rate / Recall | `TP/(TP+FN)` |
| Precision | `TP/(TP+FP)` |
| False Positive Rate | `FP/(FP+TN)` |
| F1 | `2PR/(P+R)` |

Tuning dirancang agar FN & FP > 0 sehingga detection rate bukan 100%.

## Cara menjalankan (koordinator: Anda manual di VM)

1. Sensor aktif, catat timestamp start → Anda jalankan serangan → snapshot hasil (end).
2. Baca alert manager (window) + ground-truth agent (tcpdump/eve/fast).
3. Label TP/FN/FP/TN, kumpulkan ke CSV, hitung metrik.

## Catatan

- Config live VPS **lebih baru** dari repo (local_rules 246 baris, whitelist ganda). Backup & sinkronkan dulu.
- Saat Suricata OFF, ground truth tetap andal lewat `tcpdump` SYN (bukan eve.json).
- Firewall UFW (policy DROP) di agent; serangan SYN tak kebatalkan juga bisa jadi ground truth via log.