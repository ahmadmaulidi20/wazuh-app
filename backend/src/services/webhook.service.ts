import { prisma } from '../utils/prisma';
import { WazuhAlert } from '../types/wazuh';
import { AlertService } from './alert.service';
import { AgentService } from './agent.service';
import { FcmService } from './fcm.service';
import { alertHub } from './alert-hub';
import { Prisma } from '@prisma/client';
import { logger } from '../utils/logger';
import { parseWazuhTimestamp, wibNow } from '../utils/wib';

export class WebhookService {
  private alertService = new AlertService();
  private agentService = new AgentService();
  private fcmService = new FcmService();

  async processAlert(payload: WazuhAlert) {
    // Dedup 1: by wazuh alert id (race-condition safe via try/catch P2002)
    if (payload.id) {
      const existing = await this.alertService.getByWazuhId(payload.id);
      if (existing) {
        logger.info(`Duplicate alert skipped: ${payload.id}`);
        return existing;
      }
    }

    // Upsert agent if present
    if (payload.agent?.id) {
      await this.agentService.upsert({
        wazuhAgentId: payload.agent.id,
        name: payload.agent.name || `Agent-${payload.agent.id}`,
        ip: payload.agent.ip,
        status: 'active',
        lastSeen: wibNow(),
      });
    }

    // Parse ruleId safely – fall back to null on NaN
    const rawRuleId = payload.rule?.id;
    const ruleId = typeof rawRuleId === 'string'
      ? (Number.isFinite(parseInt(rawRuleId, 10)) ? parseInt(rawRuleId, 10) : null)
      : typeof rawRuleId === 'number'
        ? rawRuleId
        : null;

    const alertData = {
      wazuhAlertId: payload.id,
      ruleId,
      ruleDescription: payload.rule?.description?.slice(0, 500),
      ruleLevel: payload.rule?.level,
      ruleGroups: payload.rule?.groups?.join(', '),
      sourceIp: payload.srcip ?? (payload.data?.srcip as string) ?? (payload.data?.src_ip as string),
      sourcePort: payload.srcport ?? (Number(payload.data?.srcport) || undefined),
      destinationIp: payload.dstip ?? (payload.data?.dstip as string) ?? (payload.data?.dest_ip as string),
      destinationPort: payload.dstport ?? (Number(payload.data?.dstport) || undefined),
      protocol: payload.protocol,
      agentId: payload.agent?.id,
      agentName: payload.agent?.name,
      location: payload.location,
      fullLog: payload.full_log?.slice(0, 2000),
      rawData: JSON.parse(JSON.stringify(payload)) as unknown as Prisma.InputJsonValue,
      timestamp: parseWazuhTimestamp(payload.timestamp),
    };

    let alert;
    try {
      alert = await this.alertService.create(alertData);
    } catch (err) {
      // P2002 = unique constraint violation (race condition dedup)
      if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
        logger.info(`Duplicate alert caught by DB constraint: ${payload.id ?? '(no id)'}`);
        if (payload.id) {
          const existing = await this.alertService.getByWazuhId(payload.id);
          if (existing) return existing;
        }
        throw err;
      }
      throw err;
    }

    // Broadcast alert to real-time clients (WebSocket) – wrapped in try/catch
    try {
      alertHub.broadcast({ type: 'alert', data: alert });
    } catch (err) {
      logger.error(`WebSocket broadcast failed: ${(err as Error).message}`);
    }

    // Send FCM notification (only for level >= 7)
    if (payload.rule?.level && payload.rule.level >= 7) {
      try {
        await this.fcmService.sendAlertNotification({
          ruleDescription: payload.rule?.description,
          ruleLevel: payload.rule?.level,
          sourceIp: payload.srcip ?? (payload.data?.srcip as string) ?? (payload.data?.src_ip as string),
        });
      } catch (err) {
        logger.error(`FCM notification failed: ${(err as Error).message}`);
      }
    }

    logger.info(`Alert processed: ${payload.rule?.description} (level ${payload.rule?.level})`);
    return alert;
  }
}
