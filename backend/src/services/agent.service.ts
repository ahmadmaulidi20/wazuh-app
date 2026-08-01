import { prisma } from '../utils/prisma';

export class AgentService {
  async list() {
    return prisma.agent.findMany({ orderBy: { name: 'asc' } });
  }

  async upsert(data: {
    wazuhAgentId: string;
    name: string;
    ip?: string;
    status?: string;
    osName?: string;
    osVersion?: string;
    lastSeen?: Date;
  }) {
    return prisma.agent.upsert({
      where: { wazuhAgentId: data.wazuhAgentId },
      update: { ...data },
      create: { ...data },
    });
  }
}
