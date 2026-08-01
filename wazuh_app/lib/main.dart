import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/notifications/presentation/firebase_messaging_service.dart';
import 'features/auth/domain/auth_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id');

  try {
    await Firebase.initializeApp();
    await FirebaseMessagingService().initialize();
  } catch (e) {
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authNotifierProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Wazuh Monitor',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
