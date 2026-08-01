import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/alert_notifier.dart';
import '../domain/alert_recommendation_mapper.dart';
import '../../../shared/widgets/alert_card.dart';
import '../../../core/utils/date_format.dart';

class AlertListPage extends ConsumerStatefulWidget {
  const AlertListPage({super.key});

  @override
  ConsumerState<AlertListPage> createState() => _AlertListPageState();
}

class _AlertListPageState extends ConsumerState<AlertListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(alertListNotifierProvider.notifier).loadAlerts());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(alertListNotifierProvider.notifier).nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertListNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alertListNotifierProvider.notifier).loadAlerts(),
        child: state.isLoading && state.alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.alerts.isEmpty
                ? const Center(child: Text('No alerts'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: state.alerts.length + (state.page < state.totalPages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.alerts.length) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final alert = state.alerts[index];
                      return AlertCard(
                        id: alert.id,
                        description: alert.ruleDescription,
                        level: alert.ruleLevel,
                        sourceIp: alert.sourceIp,
                        timestamp: formatTime(alert.timestamp),
                        status: alert.status,
                        attackType: AlertRecommendationMapper.recommend(alert).attackType,
                        onTap: () => context.push('/alerts/${alert.id}'),
                      );
                    },
                  ),
      ),
    );
  }
}
