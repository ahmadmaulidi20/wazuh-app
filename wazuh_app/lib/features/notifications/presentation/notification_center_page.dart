import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/notification_notifier.dart';
import '../../../core/utils/date_format.dart';

class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends ConsumerState<NotificationCenterPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationNotifierProvider.notifier).markAllRead(),
              child: const Text('Tandai dibaca'),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? const Center(child: Text('Belum ada notifikasi'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationNotifierProvider.notifier).load(),
                  child: ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final alert = state.notifications[index];
                      final t = DateTime.tryParse(alert.timestamp ?? '');
                      final isUnread = state.lastSeenAt == null ||
                          t == null ||
                          t.isAfter(state.lastSeenAt!);
                      final subtitle = [
                        if (alert.ruleLevel != null) 'Level ${alert.ruleLevel}',
                        if (alert.agentName != null) 'Agent ${alert.agentName}',
                        if (alert.sourceIp != null) alert.sourceIp!,
                        formatTime(alert.timestamp),
                      ].join(' • ');
                      return ListTile(
                        leading: Icon(
                          isUnread ? Icons.notifications_active : Icons.notifications_none,
                          color: isUnread ? Colors.orange : Colors.grey,
                        ),
                        title: Text(
                          alert.ruleDescription ?? 'Wazuh Alert',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isUnread
                            ? const Icon(Icons.circle, size: 10, color: Colors.orange)
                            : null,
                        onTap: () {
                          ref.read(notificationNotifierProvider.notifier).markAllRead();
                          context.push('/alerts/${alert.id}');
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
