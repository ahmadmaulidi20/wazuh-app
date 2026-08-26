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
    // Dedup by wazuh alert id
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

    // Create alert
    const ruleId = typeof payload.rule?.id === 'string' ? parseInt(payload.rule.id, 10) : payload.rule?.id;
    const alert = await this.alertService.create({
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
      rawData: JSON.parse(JSON.stringify(payload)),
      timestamp: parseWazuhTimestamp(payload.timestamp),
    });

    // Broadcast alert to real-time clients (WebSocket)
    alertHub.broadcast({ type: 'alert', data: alert });

    // Send FCM notification (only for level >= 7)
    if (payload.rule?.level && payload.rule.level >= 7) {
      await this.fcmService.sendAlertNotification({
        ruleDescription: payload.rule?.description,
        ruleLevel: payload.rule?.level,
        sourceIp: payload.srcip ?? (payload.data?.srcip as string) ?? (payload.data?.src_ip as string),
      });
    }

    logger.info(`Alert processed: ${payload.rule?.description} (level ${payload.rule?.level})`);
    return alert;
  }
}
