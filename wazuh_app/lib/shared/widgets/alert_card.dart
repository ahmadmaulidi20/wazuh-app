import 'package:flutter/material.dart';
import 'severity_badge.dart';

class AlertCard extends StatelessWidget {
  final String id;
  final String? description;
  final int? level;
  final String? sourceIp;
  final String? timestamp;
  final String status;
  final VoidCallback onTap;

  const AlertCard({
    super.key,
    required this.id,
    this.description,
    this.level,
    this.sourceIp,
    this.timestamp,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (level != null) ...[
                SeverityBadge(level: level!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description ?? 'Unknown Alert',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (sourceIp != null) ...[
                          const Icon(Icons.language, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(sourceIp!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 12),
                        ],
                        if (timestamp != null)
                          Text(
                            timestamp!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
