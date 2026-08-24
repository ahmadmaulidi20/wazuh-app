import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/alerts/presentation/alert_detail_page.dart';
import '../../features/notifications/presentation/notification_center_page.dart';
import '../../features/auth/domain/auth_notifier.dart';

class _AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void update(bool loggedIn) {
    if (_isLoggedIn != loggedIn) {
      _isLoggedIn = loggedIn;
      notifyListeners();
    }
  }
}

final _authListenable = _AuthNotifier();

final routerProvider = Provider<GoRouter>((ref) {
  ref.listen<AuthState>(authNotifierProvider, (prev, next) {
    _authListenable.update(next.isLoggedIn);
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _authListenable,
    redirect: (context, state) {
      final isLoggedIn = _authListenable.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterPage(),
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (context, state) => AlertDetailPage(
          alertId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
