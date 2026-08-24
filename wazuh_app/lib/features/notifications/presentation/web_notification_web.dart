import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class WebNotificationService {
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    try {
      final promise = web.Notification.requestPermission();
      final result = await promise.toDart;
      return result.toDart == 'granted';
    } catch (_) {
      return false;
    }
  }

  static bool get canNotify => kIsWeb && web.Notification.permission == 'granted';

  static void show({required String title, String? body}) {
    if (!canNotify) return;
    try {
      web.Notification(title, web.NotificationOptions(body: body ?? ''));
    } catch (_) {}
  }
}
