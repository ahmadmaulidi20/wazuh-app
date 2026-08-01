import { Request, Response } from 'express';
import { AgentService } from '../services/agent.service';

export class AgentController {
  private agentService = new AgentService();

  async list(_req: Request, res: Response) {
    const agents = await this.agentService.list();
    res.json(agents);
  }
}
