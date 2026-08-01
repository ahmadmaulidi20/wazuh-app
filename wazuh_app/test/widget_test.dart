import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wazuh_app/app.dart';
import 'package:wazuh_app/features/auth/data/auth_repository.dart';
import 'package:wazuh_app/features/auth/domain/auth_notifier.dart';

class _FakeAuthRepository extends AuthRepository {
  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isLoggedIn() async => false;
}

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const WazuhApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wazuh Monitor'), findsOneWidget);
  });
}
