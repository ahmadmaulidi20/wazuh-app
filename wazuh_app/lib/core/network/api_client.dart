import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.timeout,
      receiveTimeout: ApiConstants.timeout,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _storage.delete(key: 'jwt_token');
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _request(() => _dio.get(path, queryParameters: queryParameters));

  Future<Response> post(String path, {dynamic data}) =>
      _request(() => _dio.post(path, data: data));

  Future<Response> patch(String path, {dynamic data}) =>
      _request(() => _dio.patch(path, data: data));

  Future<Response> delete(String path, {dynamic data}) =>
      _request(() => _dio.delete(path, data: data));

  Future<Response> _request(Future<Response> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ApiException('Connection timed out. Please check your network.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const ApiException('Cannot connect to server. Please check your network.');
      }
      if (e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? (data['error'] as String? ?? 'Request failed') : 'Request failed';
        throw ApiException(msg, statusCode: e.response!.statusCode);
      }
      throw const ApiException('An unexpected error occurred.');
    }
  }
}
