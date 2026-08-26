import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { AlertController } from '../controllers/alert.controller';
import { AgentController } from '../controllers/agent.controller';
import { DashboardController } from '../controllers/dashboard.controller';
import { DeviceController } from '../controllers/device.controller';
import { WebhookController } from '../controllers/webhook.controller';
import { authMiddleware } from '../middleware/auth';
import { webhookAuth } from '../middleware/webhook-auth';
import { prisma } from '../utils/prisma';

const router = Router();

const authCtrl = new AuthController();
const alertCtrl = new AlertController();
const agentCtrl = new AgentController();
const dashCtrl = new DashboardController();
const deviceCtrl = new DeviceController();
const webhookCtrl = new WebhookController();

// Public
router.post('/auth/login', (req, res) => authCtrl.login(req, res));

// Webhook (API key auth)
router.post('/webhook/wazuh', webhookAuth, (req, res) => webhookCtrl.handleAlert(req, res));

// Protected
router.get('/dashboard', authMiddleware, (req, res) => dashCtrl.getStats(req, res));
router.get('/alerts', authMiddleware, (req, res) => alertCtrl.list(req, res));
router.get('/alerts/:id', authMiddleware, (req, res) => alertCtrl.getById(req, res));
router.patch('/alerts/:id', authMiddleware, (req, res) => alertCtrl.updateStatus(req, res));
router.get('/agents', authMiddleware, (req, res) => agentCtrl.list(req, res));
router.post('/device-token', authMiddleware, (req, res) => deviceCtrl.register(req, res));
router.delete('/device-token', authMiddleware, (req, res) => deviceCtrl.unregister(req, res));

// Temporary migration endpoint - REMOVE AFTER USE
router.post('/migrate-tz', webhookAuth, async (_req, res) => {
  try {
    const results: string[] = [];

    const r1 = await prisma.$executeRawUnsafe(
      `UPDATE users SET created_at = created_at AT TIME ZONE 'Asia/Jakarta', updated_at = updated_at AT TIME ZONE 'Asia/Jakarta'`
    );
    results.push(`users: ${r1} rows`);

    const r2 = await prisma.$executeRawUnsafe(
      `UPDATE agents SET last_seen = last_seen AT TIME ZONE 'Asia/Jakarta', created_at = created_at AT TIME ZONE 'Asia/Jakarta', updated_at = updated_at AT TIME ZONE 'Asia/Jakarta' WHERE last_seen IS NOT NULL OR created_at IS NOT NULL`
    );
    results.push(`agents: ${r2} rows`);

    const r3 = await prisma.$executeRawUnsafe(
      `UPDATE alerts SET timestamp = timestamp AT TIME ZONE 'Asia/Jakarta', created_at = created_at AT TIME ZONE 'Asia/Jakarta' WHERE timestamp IS NOT NULL OR created_at IS NOT NULL`
    );
    results.push(`alerts: ${r3} rows`);

    const r4 = await prisma.$executeRawUnsafe(
      `UPDATE device_tokens SET created_at = created_at AT TIME ZONE 'Asia/Jakarta', updated_at = updated_at AT TIME ZONE 'Asia/Jakarta'`
    );
    results.push(`device_tokens: ${r4} rows`);

    res.json({ success: true, results });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

export default router;
