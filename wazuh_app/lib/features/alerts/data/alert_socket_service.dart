import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_constants.dart';

class AlertSocketService {
  static const _tokenKey = 'jwt_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _reconnecting = false;
  bool _disposed = false;

  final void Function(Map<String, dynamic> alert)? onAlert;
  final void Function(bool connected)? onStatusChanged;

  AlertSocketService({this.onAlert, this.onStatusChanged});

  String _resolveWsUrl() {
    final uri = Uri.parse(ApiConstants.baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port/ws';
  }

  Future<void> connect() async {
    if (_disposed) return;
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      onStatusChanged?.call(false);
      return;
    }
    disconnect();
    final channel = WebSocketChannel.connect(Uri.parse('${_resolveWsUrl()}?token=$token'));
    _channel = channel;
    onStatusChanged?.call(true);
    _subscription = channel.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message as String);
          if (decoded is Map<String, dynamic> && decoded['type'] == 'alert') {
            final data = decoded['data'];
            if (data is Map<String, dynamic>) {
              onAlert?.call(data);
            }
          }
        } catch (_) {}
      },
      onError: (_) => _scheduleReconnect(),
      onDone: () => _scheduleReconnect(),
    );
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _scheduleReconnect() {
    onStatusChanged?.call(false);
    if (_reconnecting || _disposed) return;
    _reconnecting = true;
    Future.delayed(const Duration(seconds: 5), () {
      _reconnecting = false;
      connect();
    });
  }

  void dispose() {
    _disposed = true;
    disconnect();
  }
}
