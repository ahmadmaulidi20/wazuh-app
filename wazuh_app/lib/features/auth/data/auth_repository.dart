import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<AuthResponse> login(String username, String password) async {
    final response = await _client.post(
      ApiConstants.login,
      data: {'username': username, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    final auth = AuthResponse.fromJson(data);

    await _storage.write(key: 'jwt_token', value: auth.token);
    return auth;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
