import { Request, Response } from 'express';
import { DashboardService } from '../services/dashboard.service';

export class DashboardController {
  private dashboardService = new DashboardService();

  async getStats(_req: Request, res: Response) {
    const stats = await this.dashboardService.getStats();
    res.json(stats);
  }
}
