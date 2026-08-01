
class SeverityCount {
  final int level;
  final int count;

  const SeverityCount({required this.level, required this.count});

  factory SeverityCount.fromJson(Map<String, dynamic> json) {
    return SeverityCount(
      level: json['level'] as int,
      count: json['count'] as int,
    );
  }
}

class TopAttackIp {
  final String ip;
  final int count;

  const TopAttackIp({required this.ip, required this.count});

  factory TopAttackIp.fromJson(Map<String, dynamic> json) {
    return TopAttackIp(
      ip: json['ip'] as String,
      count: json['count'] as int,
    );
  }
}

class RecentAlert {
  final String id;
  final String? ruleDescription;
  final int? ruleLevel;
  final String? sourceIp;
  final String? timestamp;
  final String status;

  const RecentAlert({
    required this.id,
    this.ruleDescription,
    this.ruleLevel,
    this.sourceIp,
    this.timestamp,
    this.status = 'new',
  });

  factory RecentAlert.fromJson(Map<String, dynamic> json) {
    return RecentAlert(
      id: json['id'] as String,
      ruleDescription: json['ruleDescription'] as String?,
      ruleLevel: json['ruleLevel'] as int?,
      sourceIp: json['sourceIp'] as String?,
      timestamp: json['timestamp'] as String?,
      status: json['status'] as String? ?? 'new',
    );
  }
}

class DashboardData {
  final int totalAlerts;
  final int alertsToday;
  final int totalAgents;
  final int activeAgents;
  final List<SeverityCount> alertsBySeverity;
  final List<TopAttackIp> topAttackIps;
  final List<RecentAlert> recentAlerts;

  const DashboardData({
    required this.totalAlerts,
    required this.alertsToday,
    required this.totalAgents,
    required this.activeAgents,
    this.alertsBySeverity = const [],
    this.topAttackIps = const [],
    this.recentAlerts = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalAlerts: json['totalAlerts'] as int,
      alertsToday: json['alertsToday'] as int,
      totalAgents: json['totalAgents'] as int,
      activeAgents: json['activeAgents'] as int,
      alertsBySeverity: (json['alertsBySeverity'] as List<dynamic>?)
              ?.map((e) => SeverityCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topAttackIps: (json['topAttackIps'] as List<dynamic>?)
              ?.map((e) => TopAttackIp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentAlerts: (json['recentAlerts'] as List<dynamic>?)
              ?.map((e) => RecentAlert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
