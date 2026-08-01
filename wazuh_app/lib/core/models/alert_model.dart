class AlertModel {
  final String id;
  final String? wazuhAlertId;
  final int? ruleId;
  final String? ruleDescription;
  final int? ruleLevel;
  final String? ruleGroups;
  final String? sourceIp;
  final int? sourcePort;
  final String? destinationIp;
  final int? destinationPort;
  final String? protocol;
  final String? agentId;
  final String? agentName;
  final String? location;
  final String? fullLog;
  final String? timestamp;
  final String status;
  final String? createdAt;

  const AlertModel({
    required this.id,
    this.wazuhAlertId,
    this.ruleId,
    this.ruleDescription,
    this.ruleLevel,
    this.ruleGroups,
    this.sourceIp,
    this.sourcePort,
    this.destinationIp,
    this.destinationPort,
    this.protocol,
    this.agentId,
    this.agentName,
    this.location,
    this.fullLog,
    this.timestamp,
    this.status = 'new',
    this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      wazuhAlertId: json['wazuhAlertId'] as String?,
      ruleId: json['ruleId'] as int?,
      ruleDescription: json['ruleDescription'] as String?,
      ruleLevel: json['ruleLevel'] as int?,
      ruleGroups: json['ruleGroups'] as String?,
      sourceIp: json['sourceIp'] as String?,
      sourcePort: json['sourcePort'] as int?,
      destinationIp: json['destinationIp'] as String?,
      destinationPort: json['destinationPort'] as int?,
      protocol: json['protocol'] as String?,
      agentId: json['agentId'] as String?,
      agentName: json['agentName'] as String?,
      location: json['location'] as String?,
      fullLog: json['fullLog'] as String?,
      timestamp: json['timestamp'] as String?,
      status: json['status'] as String? ?? 'new',
      createdAt: json['createdAt'] as String?,
    );
  }
}

class AlertListResponse {
  final List<AlertModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AlertListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AlertListResponse.fromJson(Map<String, dynamic> json) {
    return AlertListResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
