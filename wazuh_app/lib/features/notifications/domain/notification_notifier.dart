import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alerts/domain/alert_notifier.dart';
import '../../alerts/data/alert_repository.dart';
import '../../../core/models/alert_model.dart';

class NotificationState {
  final bool isLoading;
  final List<AlertModel> notifications;
  final int unreadCount;
  final DateTime? lastSeenAt;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.lastSeenAt,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<AlertModel>? notifications,
    int? unreadCount,
    DateTime? lastSeenAt,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final AlertRepository _repository;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _lastSeenKey = 'notification_last_seen';

  NotificationNotifier(this._repository) : super(const NotificationState()) {
    _loadLastSeen();
  }

  Future<void> _loadLastSeen() async {
    try {
      final raw = await _storage.read(key: _lastSeenKey);
      if (raw != null) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          state = state.copyWith(lastSeenAt: parsed);
        }
      }
    } catch (_) {}
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.list(limit: 30);
      state = state.copyWith(
        isLoading: false,
        notifications: result.data,
        unreadCount: _countUnread(result.data, state.lastSeenAt),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void addAlert(AlertModel alert) {
    state = state.copyWith(
      notifications: [
        alert,
        ...state.notifications.where((n) => n.id != alert.id),
      ],
      unreadCount: state.unreadCount + 1,
    );
  }

  Future<void> markAllRead() async {
    final now = DateTime.now().toUtc();
    try {
      await _storage.write(key: _lastSeenKey, value: now.toIso8601String());
    } catch (_) {}
    state = state.copyWith(unreadCount: 0, lastSeenAt: now);
  }

  int _countUnread(List<AlertModel> alerts, DateTime? lastSeen) {
    if (lastSeen == null) return alerts.length;
    return alerts.where((a) {
      final t = DateTime.tryParse(a.timestamp ?? '');
      return t == null || t.isAfter(lastSeen);
    }).length;
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.read(alertRepositoryProvider));
});
