-- Migration: Normalize timestamps and add missing indexes
-- This migration ensures all timestamps are in WIB-as-UTC format
-- and adds performance indexes for common query patterns.

-- Note: The actual timestamp normalization should be done via the pgAdmin SQL script
-- (temp/fix_database_pgadmin.sql) as it requires careful analysis of existing data.

-- Add composite index for common alert filtering patterns
CREATE INDEX IF NOT EXISTS "alerts_status_ruleLevel_idx" ON "alerts"("status", "rule_level");
CREATE INDEX IF NOT EXISTS "alerts_timestamp_status_idx" ON "alerts"("timestamp", "status");
CREATE INDEX IF NOT EXISTS "alerts_agentId_timestamp_idx" ON "alerts"("agent_id", "timestamp");

-- Add index for agent lookup by status
CREATE INDEX IF NOT EXISTS "agents_status_idx" ON "agents"("status");

-- Add index for device token cleanup queries
CREATE INDEX IF NOT EXISTS "device_tokens_user_id_idx" ON "device_tokens"("user_id");
