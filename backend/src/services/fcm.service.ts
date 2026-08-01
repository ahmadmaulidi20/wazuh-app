import { getMessaging } from '../config/firebase';
import { prisma } from '../utils/prisma';
import { logger } from '../utils/logger';

export class FcmService {
  async sendAlertNotification(alert: {
    ruleDescription?: string | null;
    ruleLevel?: number | null;
    sourceIp?: string | null;
  }) {
    try {
      const messaging = getMessaging();
      const tokens = await prisma.deviceToken.findMany({
        select: { token: true, id: true },
      });

      if (tokens.length === 0) return;

      const title = alert.ruleLevel && alert.ruleLevel >= 10
        ? `Critical Alert (Level ${alert.ruleLevel})`
        : `Alert (Level ${alert.ruleLevel})`;

      const body = alert.ruleDescription
        ? `${alert.ruleDescription}${alert.sourceIp ? ` from ${alert.sourceIp}` : ''}`
        : `Security alert${alert.sourceIp ? ` from ${alert.sourceIp}` : ''}`;

      const message = {
        notification: { title, body },
        tokens: tokens.map((t) => t.token),
      };

      const response = await messaging.sendEachForMulticast(message);

      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (resp.error) {
          const code = resp.error.code;
          if (code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered') {
            invalidTokens.push(tokens[idx].token);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await prisma.deviceToken.deleteMany({
          where: { token: { in: invalidTokens } },
        });
        logger.info(`Cleaned ${invalidTokens.length} invalid FCM tokens`);
      }

      logger.info(`FCM sent: ${response.successCount} success, ${response.failureCount} failed`);
    } catch (err) {
      logger.error(`FCM error: ${(err as Error).message}`);
    }
  }
}
