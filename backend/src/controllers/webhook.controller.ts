import { Request, Response } from 'express';
import { z } from 'zod';
import { WebhookService } from '../services/webhook.service';
import { logger } from '../utils/logger';

const wazuhAlertSchema = z.object({
    id: z.string().optional(),
  rule: z.object({
    id: z.union([z.string(), z.number()]).optional(),
    description: z.string().optional(),
    level: z.number().int().min(0).max(15).optional(),
    groups: z.array(z.string()).optional(),
    firedtimes: z.number().optional(),
    frequency: z.number().optional(),
  }).optional(),
  agent: z.object({
    id: z.string().optional(),
    name: z.string().optional(),
    ip: z.string().optional(),
  }).optional(),
  manager: z.object({
    name: z.string().optional(),
  }).optional(),
  location: z.string().optional(),
  full_log: z.string().optional(),
  data: z.record(z.string(), z.unknown()).optional(),
  srcip: z.string().optional(),
  dstip: z.string().optional(),
  srcport: z.number().optional(),
  dstport: z.number().optional(),
  protocol: z.string().optional(),
  timestamp: z.string().optional(),
}).passthrough();

export class WebhookController {
  private webhookService = new WebhookService();

  async handleAlert(req: Request, res: Response) {
    const parsed = wazuhAlertSchema.safeParse(req.body);
    if (!parsed.success) {
      logger.warn(`Webhook validation failed: ${JSON.stringify(parsed.error.issues)}`);
      res.status(400).json({ error: 'Invalid alert payload', details: parsed.error.issues });
      return;
    }

    try {
      const alert = await this.webhookService.processAlert(parsed.data);
      res.json({ message: 'Alert processed', id: alert.id });
    } catch (err) {
      logger.error(`Webhook error: ${(err as Error).message}`);
      res.status(500).json({ error: 'Failed to process alert' });
    }
  }
}
