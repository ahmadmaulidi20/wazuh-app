-- ============================================================
-- SQL SCRIPT: Fix Database via pgAdmin
-- Jalankan di pgAdmin SQL Editor: https://siemkampus-monitoring-app.duckdns.org/pgadmin/
-- Database: wazuh_monitor
-- ============================================================

-- ============================================================
-- BAGIAN 1: ANALISIS KONDISI DATA SAAT INI
-- ============================================================

-- Cek timestamp distribution di alerts
SELECT 
  COUNT(*) AS total_alerts,
  COUNT(CASE WHEN timestamp < '2026-01-01' THEN 1 END) AS likely_very_old,
  COUNT(CASE WHEN timestamp >= '2026-01-01' AND timestamp < '2026-08-01' THEN 1 END) AS pre_migration,
  COUNT(CASE WHEN timestamp >= '2026-08-01' THEN 1 END) AS post_migration,
  MIN(timestamp) AS earliest_alert,
  MAX(timestamp) AS latest_alert
FROM alerts;

-- Cek timestamp distribution di agents
SELECT 
  COUNT(*) AS total_agents,
  COUNT(CASE WHEN last_seen < '2026-08-01' THEN 1 END) AS old_last_seen,
  COUNT(CASE WHEN created_at < '2026-08-01' THEN 1 END) AS old_created
FROM agents;

-- ============================================================
-- BAGIAN 2: HAPUS ALERT DUPLIKAT
-- ============================================================

-- Cari alert duplikat berdasarkan wazuh_alert_id
SELECT wazuh_alert_id, COUNT(*) AS duplicate_count
FROM alerts
WHERE wazuh_alert_id IS NOT NULL
GROUP BY wazuh_alert_id
HAVING COUNT(*) > 1;

-- Hapus alert duplikat (keep yang ID-nya paling besar / paling baru)
DELETE FROM alerts
WHERE id NOT IN (
  SELECT MAX(id)
  FROM alerts
  WHERE wazuh_alert_id IS NOT NULL
  GROUP BY wazuh_alert_id
);

-- Cek alert tanpa wazuh_alert_id (tidak bisa di-dedup secara natural)
SELECT COUNT(*) AS alerts_without_wazuh_id
FROM alerts
WHERE wazuh_alert_id IS NULL;

-- ============================================================
-- BAGIAN 3: FIX TIMEZONE (jika diperlukan)
-- ============================================================

-- HATI-HATI: Jalankan BAGIAN 3 ini HANYA SETELAH memverifikasi
-- bahwa data lama masih dalam format UTC (belum di-shift).
--
-- Ciri-ciri data masih UTC:
--   - Alert timestamp menunjukkan waktu UTC (misalnya jam 3 pagi untuk 
--     serangan yang terjadi jam 10 pagi WIB)
--   - created_at alerts sebelum Agustus 2026 masih di UTC
--
-- Jika data SUDAH benar (WIB), SKIP bagian ini!

-- Contoh cek manual:
-- SELECT id, timestamp, created_at FROM alerts ORDER BY created_at DESC LIMIT 10;
-- Bandingkan dengan log Wazuh asli. Jika timestamp di DB = UTC log, maka perlu di-fix.

-- === Uncomment di bawah ini jika perlu fix timezone ===

/*
-- Fix alerts timestamps (data lama UTC → WIB-as-UTC)
UPDATE alerts 
SET timestamp = timestamp + INTERVAL '7 hours'
WHERE timestamp IS NOT NULL
  AND timestamp < '2026-08-27';

-- Fix alerts created_at
UPDATE alerts
SET created_at = created_at + INTERVAL '7 hours'
WHERE created_at < '2026-08-27';

-- Fix agents
UPDATE agents
SET last_seen = last_seen + INTERVAL '7 hours'
WHERE last_seen IS NOT NULL AND last_seen < '2026-08-27';

UPDATE agents
SET created_at = created_at + INTERVAL '7 hours'
WHERE created_at < '2026-08-27';

UPDATE agents
SET updated_at = updated_at + INTERVAL '7 hours'
WHERE updated_at < '2026-08-27';

-- Fix users
UPDATE users
SET created_at = created_at + INTERVAL '7 hours'
WHERE created_at < '2026-08-27';

UPDATE users
SET updated_at = updated_at + INTERVAL '7 hours'
WHERE updated_at < '2026-08-27';

-- Fix device_tokens
UPDATE device_tokens
SET created_at = created_at + INTERVAL '7 hours'
WHERE created_at < '2026-08-27';

UPDATE device_tokens
SET updated_at = updated_at + INTERVAL '7 hours'
WHERE updated_at < '2026-08-27';
*/

-- ============================================================
-- BAGIAN 4: VERIFIKASI AKHIR
-- ============================================================

-- Cek data alerts terbaru (pastikan timestamps masuk akal)
SELECT 
  id,
  wazuh_alert_id,
  rule_description,
  rule_level,
  source_ip,
  timestamp,
  created_at,
  status
FROM alerts
ORDER BY created_at DESC
LIMIT 20;

-- Cek agents
SELECT 
  wazuh_agent_id,
  name,
  status,
  last_seen,
  created_at
FROM agents
ORDER BY created_at DESC;

-- Cek users
SELECT id, username, role, created_at FROM users;

-- Cek device_tokens
SELECT id, user_id, platform, created_at FROM device_tokens;

-- Cek foreign key integrity
SELECT COUNT(*) AS orphaned_alerts
FROM alerts a
LEFT JOIN agents ag ON a.agent_id = ag.wazuh_agent_id
WHERE a.agent_id IS NOT NULL AND ag.wazuh_agent_id IS NULL;
