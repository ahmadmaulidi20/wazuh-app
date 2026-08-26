-- Konversi semua timestamp dari UTC ke WIB (+7 jam)
-- created_at TIDAK diubah karena sudah WIB dari PostgreSQL NOW()

-- Alerts: timestamp field (UTC dari parseWazuhTimestamp → WIB)
UPDATE alerts SET timestamp = timestamp + INTERVAL '7 hours' WHERE timestamp IS NOT NULL;

-- Agents: last_seen field (UTC dari new Date() → WIB)
UPDATE agents SET last_seen = last_seen + INTERVAL '7 hours' WHERE last_seen IS NOT NULL;

-- Semua updated_at field (UTC dari Prisma @updatedAt → WIB)
UPDATE users SET updated_at = updated_at + INTERVAL '7 hours';
UPDATE agents SET updated_at = updated_at + INTERVAL '7 hours';
UPDATE device_tokens SET updated_at = updated_at + INTERVAL '7 hours';
