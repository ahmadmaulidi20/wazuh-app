import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient _client = ApiClient();

  Future<void> initialize() async {
    await _requestPermission();
    final token = await _getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('FCM Permission: ${settings.authorizationStatus}');
    }
  }

  Future<String?> _getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) print('FCM Token error: $e');
      return null;
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _client.post(
        ApiConstants.deviceToken,
        data: {
          'token': token,
          'platform': _getPlatform(),
        },
      );
    } catch (e) {
      if (kDebugMode) print('FCM Register error: $e');
    }
  }

  String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'web';
  }

  void _handleMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('FCM Message: ${message.notification?.title}');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Handle background notification
}
