import { Request, Response } from 'express';
import { AlertService } from '../services/alert.service';

export class AlertController {
  private alertService = new AlertService();

  async list(req: Request, res: Response) {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const filter = {
      status: req.query.status as string | undefined,
      ruleLevel: req.query.ruleLevel ? Number(req.query.ruleLevel) : undefined,
      sourceIp: req.query.sourceIp as string | undefined,
      agentId: req.query.agentId as string | undefined,
      startDate: req.query.startDate as string | undefined,
      endDate: req.query.endDate as string | undefined,
    };

    const result = await this.alertService.list({ page, limit, filter });
    res.json(result);
  }

  async getById(req: Request, res: Response) {
    const id = req.params.id as string;
    const alert = await this.alertService.getById(id);
    if (!alert) {
      res.status(404).json({ error: 'Alert not found' });
      return;
    }
    res.json(alert);
  }

  async updateStatus(req: Request, res: Response) {
    const id = req.params.id as string;
    const { status } = req.body;
    if (!['new', 'acknowledged', 'resolved'].includes(status)) {
      res.status(400).json({ error: 'Invalid status' });
      return;
    }
    const alert = await this.alertService.updateStatus(id, status);
    res.json(alert);
  }
}
