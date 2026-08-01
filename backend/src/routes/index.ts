import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { AlertController } from '../controllers/alert.controller';
import { AgentController } from '../controllers/agent.controller';
import { DashboardController } from '../controllers/dashboard.controller';
import { DeviceController } from '../controllers/device.controller';
import { WebhookController } from '../controllers/webhook.controller';
import { authMiddleware } from '../middleware/auth';
import { webhookAuth } from '../middleware/webhook-auth';

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

export default router;
