import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/alert_notifier.dart';
import '../../../shared/widgets/severity_badge.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/models/alert_recommendation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../domain/alert_recommendation_mapper.dart';

class AlertDetailPage extends ConsumerStatefulWidget {
  final String alertId;
  const AlertDetailPage({super.key, required this.alertId});

  @override
  ConsumerState<AlertDetailPage> createState() => _AlertDetailPageState();
}

class _AlertDetailPageState extends ConsumerState<AlertDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(alertDetailNotifierProvider(widget.alertId).notifier).loadAlert(widget.alertId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertDetailNotifierProvider(widget.alertId));

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Detail')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.alert == null
              ? const Center(child: Text('Alert not found'))
              : _buildContent(state.alert!),
    );
  }

  Widget _buildContent(AlertModel alert) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (alert.ruleLevel != null) SeverityBadge(level: alert.ruleLevel!),
              const SizedBox(width: 12),
              StatusBadge(status: alert.status),
              const Spacer(),
              Text(
                formatTimestamp(alert.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            alert.ruleDescription ?? 'Unknown Alert',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _RecommendationCard(
            recommendation: AlertRecommendationMapper.recommend(alert),
            level: alert.ruleLevel,
          ),
          const SizedBox(height: 24),

          _DetailRow(label: 'Rule ID', value: '${alert.ruleId ?? '-'}'),
          _DetailRow(label: 'Rule Level', value: '${alert.ruleLevel ?? '-'}'),
          _DetailRow(label: 'Rule Groups', value: alert.ruleGroups ?? '-'),
          _DetailRow(label: 'Source IP', value: alert.sourceIp ?? '-'),
          _DetailRow(label: 'Source Port', value: '${alert.sourcePort ?? '-'}'),
          _DetailRow(label: 'Destination IP', value: alert.destinationIp ?? '-'),
          _DetailRow(label: 'Destination Port', value: '${alert.destinationPort ?? '-'}'),
          _DetailRow(label: 'Protocol', value: alert.protocol ?? '-'),
          _DetailRow(label: 'Agent', value: alert.agentName ?? '-'),
          _DetailRow(label: 'Location', value: alert.location ?? '-'),
          const SizedBox(height: 24),

          if (alert.fullLog != null) ...[
            const Text('Full Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                alert.fullLog!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (alert.status == 'new')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(alertDetailNotifierProvider(widget.alertId).notifier)
                      .updateStatus(widget.alertId, 'acknowledged');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Acknowledge'),
              ),
            ),
          if (alert.status == 'acknowledged')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(alertDetailNotifierProvider(widget.alertId).notifier)
                      .updateStatus(widget.alertId, 'resolved');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Resolve'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final AlertRecommendation recommendation;
  final int? level;

  const _RecommendationCard({required this.recommendation, this.level});

  @override
  Widget build(BuildContext context) {
    final accent = level != null ? SeverityColors.getColor(level!) : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                recommendation.attackType,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.summary,
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rekomendasi tindakan:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...recommendation.actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(action, style: const TextStyle(fontSize: 13, height: 1.35)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
