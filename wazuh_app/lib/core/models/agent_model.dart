class AgentModel {
  final String id;
  final String wazuhAgentId;
  final String name;
  final String? ip;
  final String status;
  final String? osName;
  final String? osVersion;
  final String? lastSeen;

  const AgentModel({
    required this.id,
    required this.wazuhAgentId,
    required this.name,
    this.ip,
    this.status = 'pending',
    this.osName,
    this.osVersion,
    this.lastSeen,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] as String,
      wazuhAgentId: json['wazuhAgentId'] as String,
      name: json['name'] as String,
      ip: json['ip'] as String?,
      status: json['status'] as String? ?? 'pending',
      osName: json['osName'] as String?,
      osVersion: json['osVersion'] as String?,
      lastSeen: json['lastSeen'] as String?,
    );
  }
}
