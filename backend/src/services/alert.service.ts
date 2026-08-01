import { Prisma } from '@prisma/client';
import { prisma } from '../utils/prisma';
import { AlertFilter } from '../types/wazuh';

export class AlertService {
  async list(params: { page: number; limit: number; filter?: AlertFilter }) {
    const { page, limit, filter } = params;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = {};
    if (filter?.status) where.status = filter.status;
    if (filter?.ruleLevel) where.ruleLevel = filter.ruleLevel;
    if (filter?.sourceIp) where.sourceIp = { contains: filter.sourceIp };
    if (filter?.agentId) where.agentId = filter.agentId;
    if (filter?.startDate || filter?.endDate) {
      where.timestamp = {};
      if (filter.startDate) (where.timestamp as Record<string, unknown>).gte = new Date(filter.startDate);
      if (filter.endDate) (where.timestamp as Record<string, unknown>).lte = new Date(filter.endDate);
    }

    const [data, total] = await Promise.all([
      prisma.alert.findMany({
        where,
        skip,
        take: limit,
        orderBy: { timestamp: 'desc' },
      }),
      prisma.alert.count({ where }),
    ]);

    return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getById(id: string) {
    return prisma.alert.findUnique({ where: { id } });
  }

  async updateStatus(id: string, status: string) {
    return prisma.alert.update({
      where: { id },
      data: { status },
    });
  }

  async create(data: Prisma.AlertUncheckedCreateInput) {
    return prisma.alert.create({ data });
  }

  async getByWazuhId(wazuhAlertId: string) {
    return prisma.alert.findUnique({ where: { wazuhAlertId } });
  }
}
