import { prisma } from '../utils/prisma';
import { DashboardResponse } from '../types/wazuh';

export class DashboardService {
  async getStats(): Promise<DashboardResponse> {
    const now = new Date();
    const todayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    const [
      totalAlerts,
      alertsToday,
      totalAgents,
      activeAgents,
      alertsBySeverity,
      topAttackIps,
    ] = await Promise.all([
      prisma.alert.count(),
      prisma.alert.count({ where: { timestamp: { gte: todayStart } } }),
      prisma.agent.count(),
      prisma.agent.count({ where: { status: 'active' } }),
      prisma.alert.groupBy({
        by: ['ruleLevel'],
        _count: { ruleLevel: true },
        orderBy: { ruleLevel: 'desc' },
      }),
      prisma.alert.groupBy({
        by: ['sourceIp'],
        _count: { sourceIp: true },
        orderBy: { _count: { sourceIp: 'desc' } },
        take: 10,
      }),
    ]);

    const recentAlerts = await prisma.alert.findMany({
      take: 5,
      orderBy: { timestamp: 'desc' },
      select: {
        id: true,
        ruleDescription: true,
        ruleLevel: true,
        sourceIp: true,
        timestamp: true,
        status: true,
      },
    });

    return {
      totalAlerts,
      alertsToday,
      totalAgents,
      activeAgents,
      alertsBySeverity: alertsBySeverity.map((a) => ({
        level: a.ruleLevel ?? 0,
        count: a._count.ruleLevel,
      })),
      topAttackIps: topAttackIps.map((a) => ({
        ip: a.sourceIp ?? 'unknown',
        count: a._count.sourceIp,
      })),
      recentAlerts: recentAlerts.map((a) => ({
        id: a.id,
        ruleDescription: a.ruleDescription,
        ruleLevel: a.ruleLevel,
        sourceIp: a.sourceIp,
        timestamp: a.timestamp,
        status: a.status,
      })),
    };
  }
}
