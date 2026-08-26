-- Konversi semua timestamp dari UTC ke WIB (+7 jam)
-- Semua field datetime diubah ke WIB

-- Alerts
UPDATE alerts SET timestamp = timestamp + INTERVAL '7 hours' WHERE timestamp IS NOT NULL;
UPDATE alerts SET created_at = created_at + INTERVAL '7 hours' WHERE created_at IS NOT NULL;

-- Agents
UPDATE agents SET last_seen = last_seen + INTERVAL '7 hours' WHERE last_seen IS NOT NULL;
UPDATE agents SET created_at = created_at + INTERVAL '7 hours';
UPDATE agents SET updated_at = updated_at + INTERVAL '7 hours';

-- Users
UPDATE users SET created_at = created_at + INTERVAL '7 hours';
UPDATE users SET updated_at = updated_at + INTERVAL '7 hours';

-- Device Tokens
UPDATE device_tokens SET created_at = created_at + INTERVAL '7 hours';
UPDATE device_tokens SET updated_at = updated_at + INTERVAL '7 hours';
