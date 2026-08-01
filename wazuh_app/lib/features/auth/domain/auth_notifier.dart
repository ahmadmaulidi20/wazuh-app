import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;
  final UserModel? user;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> checkAuth() async {
    final token = await _repository.getToken();
    if (token != null) {
      final payload = _decodeJwtPayload(token);
      if (payload != null) {
        final exp = payload['exp'];
        if (exp != null && (exp as int) > (DateTime.now().millisecondsSinceEpoch ~/ 1000)) {
          state = state.copyWith(
            isLoggedIn: true,
            user: UserModel(
              id: payload['userId'] as String? ?? '',
              username: payload['username'] as String? ?? '',
              role: payload['role'] as String? ?? 'admin',
            ),
          );
          return;
        }
      }
      await _repository.logout();
    }
    state = const AuthState();
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized.padRight(normalized.length + (4 - normalized.length % 4) % 4, '=');
      final decoded = utf8.decode(base64.decode(padded));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.login(username, password);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: result.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
