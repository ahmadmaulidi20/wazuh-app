import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../domain/dashboard_notifier.dart';
import '../../../core/models/dashboard_data.dart';
import '../../alerts/presentation/alert_list_page.dart';
import '../../agents/presentation/agent_list_page.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/live_clock.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardView(),
          AlertListPage(),
          AgentListPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Agents'),
        ],
      ),
    );
  }
}

class _DashboardView extends ConsumerStatefulWidget {
  const _DashboardView();

  @override
  ConsumerState<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<_DashboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardNotifierProvider.notifier).loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardNotifierProvider.notifier).loadStats(),
          ),
        ],
      ),
      body: state.isLoading && state.data == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : _buildContent(state.data!),
    );
  }

  Widget _buildContent(DashboardData data) {
    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardNotifierProvider.notifier).loadStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LiveClock(),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard(
                  title: 'Total Alerts',
                  value: '${data.totalAlerts}',
                  icon: Icons.warning,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: 'Today',
                  value: '${data.alertsToday}',
                  icon: Icons.today,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  title: 'Total Agents',
                  value: '${data.totalAgents}',
                  icon: Icons.devices,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: 'Active',
                  value: '${data.activeAgents}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (data.alertsBySeverity.isNotEmpty) ...[
              const Text('Alerts by Severity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: data.alertsBySeverity.map((e) => e.count.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.alertsBySeverity.length) return const SizedBox();
                            return Text('L${data.alertsBySeverity[idx].level}', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    barGroups: data.alertsBySeverity.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.count.toDouble(),
                            color: Colors.cyanAccent,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (data.topAttackIps.isNotEmpty) ...[
              const Text('Top Attack IPs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...data.topAttackIps.map((ip) => ListTile(
                dense: true,
                leading: const Icon(Icons.language, color: Colors.red),
                title: Text(ip.ip),
                trailing: Text('${ip.count}x', style: const TextStyle(color: Colors.orange)),
              )),
              const SizedBox(height: 24),
            ],

            const Text('Recent Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...data.recentAlerts.map((alert) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(alert.ruleDescription ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(alert.sourceIp ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (alert.ruleLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('L${alert.ruleLevel}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                      ),
                    const SizedBox(width: 8),
                    StatusBadge(status: alert.status),
                  ],
                ),
                onTap: () => context.push('/alerts/${alert.id}'),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
