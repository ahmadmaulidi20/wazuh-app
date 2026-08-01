export interface WazuhAlert {
  id?: string;
  rule?: {
    id?: string | number;
    description?: string;
    level?: number;
    groups?: string[];
    firedtimes?: number;
    frequency?: number;
  };
  agent?: {
    id?: string;
    name?: string;
    ip?: string;
  };
  manager?: {
    name?: string;
  };
  location?: string;
  full_log?: string;
  data?: Record<string, unknown>;
  srcip?: string;
  dstip?: string;
  srcport?: number;
  dstport?: number;
  protocol?: string;
  timestamp?: string;
  [key: string]: unknown;
}

export interface DashboardResponse {
  totalAlerts: number;
  alertsToday: number;
  totalAgents: number;
  activeAgents: number;
  alertsBySeverity: { level: number; count: number }[];
  topAttackIps: { ip: string; count: number }[];
  recentAlerts: {
    id: string;
    ruleDescription: string | null;
    ruleLevel: number | null;
    sourceIp: string | null;
    timestamp: Date | null;
    status: string;
  }[];
}

export interface PaginationQuery {
  page: number;
  limit: number;
}

export interface AlertFilter {
  status?: string;
  ruleLevel?: number;
  sourceIp?: string;
  agentId?: string;
  startDate?: string;
  endDate?: string;
}
