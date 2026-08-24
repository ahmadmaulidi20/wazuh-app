import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/firebase_options.dart';
import 'core/models/alert_model.dart';
import 'core/navigation/app_keys.dart';
import 'features/notifications/presentation/firebase_messaging_service.dart';
import 'features/notifications/presentation/web_notification_service.dart';
import 'features/notifications/domain/notification_notifier.dart';
import 'features/auth/domain/auth_notifier.dart';
import 'features/alerts/domain/alert_notifier.dart';
import 'features/alerts/data/alert_socket_service.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

String? firebaseInitError;

Future<void> _initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwin = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const settings = InitializationSettings(android: android, iOS: darwin);
  await notificationsPlugin.initialize(settings: settings);

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id');

  try {
    await _initNotifications();
  } catch (e) {
    debugPrint('Notification init skipped: $e');
  }

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    firebaseInitError = '$e';
    debugPrint('Firebase init skipped: $e');
  }

  runApp(const ProviderScope(child: WazuhApp()));
}

class WazuhApp extends ConsumerStatefulWidget {
  const WazuhApp({super.key});

  @override
  ConsumerState<WazuhApp> createState() => _WazuhAppState();
}

class _WazuhAppState extends ConsumerState<WazuhApp> {
  late final AlertSocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = AlertSocketService(onAlert: _handleIncomingAlert);
    Future.microtask(() => ref.read(authNotifierProvider.notifier).checkAuth());
    if (kIsWeb && firebaseInitError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('⚠️ Firebase gagal init: $firebaseInitError'),
            duration: const Duration(seconds: 15),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  Future<void> _handleIncomingAlert(Map<String, dynamic> alert) async {
    try {
      final model = AlertModel.fromJson(alert);
      ref.read(notificationNotifierProvider.notifier).addAlert(model);
    } catch (_) {}

    final title = alert['ruleDescription'] as String? ?? 'Wazuh Alert';
    final body = [
      if (alert['ruleLevel'] != null) 'Level ${alert['ruleLevel']}',
      if (alert['agentName'] != null) 'Agent ${alert['agentName']}',
      if (alert['sourceIp'] != null) 'Src ${alert['sourceIp']}',
    ].join(' | ');

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Lihat', onPressed: () {}),
      ),
    );

    if (kIsWeb) {
      WebNotificationService.show(title: title, body: body);
    }

    await _showAlertNotification(alert);
    ref.read(alertListNotifierProvider.notifier).loadAlerts();
  }

  Future<void> _showAlertNotification(Map<String, dynamic> alert) async {
    if (kIsWeb) return;
    final title = alert['ruleDescription'] as String? ?? 'Wazuh Alert';
    final body = [
      if (alert['ruleLevel'] != null) 'Level ${alert['ruleLevel']}',
      if (alert['agentName'] != null) 'Agent ${alert['agentName']}',
      if (alert['sourceIp'] != null) 'Src ${alert['sourceIp']}',
    ].join(' | ');

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'wazuh_alerts',
        'Wazuh Alerts',
        channelDescription: 'Notifikasi alert keamanan Wazuh real-time',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final id = (alert['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch) % 100000;
    await notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      if (next.isLoggedIn) {
        _socketService.connect();
        ref.read(notificationNotifierProvider.notifier).load();
        WebNotificationService.requestPermission();
        FirebaseMessagingService().initialize();
      } else {
        _socketService.disconnect();
      }
    });

    return MaterialApp.router(
      title: 'Wazuh Monitor',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
