-- Konversi semua timestamp dari UTC ke Asia/Jakarta (WIB, UTC+7)
-- HATI-HATI: Jalankan SEKALI saja. Menjalankan ulang akan menggeser timestamp dua kali.

-- 1. Users
UPDATE users SET
  created_at = created_at AT TIME ZONE 'Asia/Jakarta',
  updated_at = updated_at AT TIME ZONE 'Asia/Jakarta';

-- 2. Agents
UPDATE agents SET
  last_seen  = last_seen AT TIME ZONE 'Asia/Jakarta',
  created_at = created_at AT TIME ZONE 'Asia/Jakarta',
  updated_at = updated_at AT TIME ZONE 'Asia/Jakarta'
WHERE last_seen IS NOT NULL OR created_at IS NOT NULL;

-- 3. Alerts
UPDATE alerts SET
  timestamp  = timestamp AT TIME ZONE 'Asia/Jakarta',
  created_at = created_at AT TIME ZONE 'Asia/Jakarta'
WHERE timestamp IS NOT NULL OR created_at IS NOT NULL;

-- 4. Device Tokens
UPDATE device_tokens SET
  created_at = created_at AT TIME ZONE 'Asia/Jakarta',
  updated_at = updated_at AT TIME ZONE 'Asia/Jakarta';
