import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/firebase_options.dart';
import '../../../core/navigation/app_keys.dart';
import 'web_notification_service.dart';

class FirebaseMessagingService {
  static const String _buildTag = '[build-c5]';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiClient _client = ApiClient();

  Future<void> initialize() async {
    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeNative();
    }
  }

  Future<void> _initializeWeb() async {
    try {
      _logSdkStatus();

      final granted = await _ensureWebPermission();
      if (!granted) return;

      final token = await _getToken();
      if (token == null) {
        _showSnack('⚠️ Gagal mendapat token FCM web.\nCek F12 → Console (log "FCM:"). $_buildTag');
        return;
      }

      await _registerToken(token);

      try {
        FirebaseMessaging.onMessage.listen(_handleMessage);
        FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
      } catch (e, st) {
        final msg = 'FCM listener gagal: $e\n$st';
        web.console.error(msg.toJS);
        _showSnack('⚠️ $msg\n$_buildTag');
      }
    } catch (e, st) {
      final msg = 'FCM init gagal: $e\n$st';
      web.console.error(msg.toJS);
      _showSnack('⚠️ $msg\n$_buildTag');
    }
  }

  void _logSdkStatus() {
    try {
      final globals = web.window as JSObject;
      final hasCore = globals.getProperty('firebase_core'.toJS) != null;
      final hasMessaging = globals.getProperty('firebase_messaging'.toJS) != null;
      web.console.log(
          'FCM: SDK globals → firebase_core=$hasCore, firebase_messaging=$hasMessaging'
              .toJS);
    } catch (e) {
      web.console.error('FCM: status SDK gagal dibaca: $e'.toJS);
    }
  }

  Future<void> _ensureWebServiceWorker() async {
    try {
      final navigator = web.window.navigator;
      final sw = navigator.serviceWorker;
      final existing = await sw.getRegistration().toDart;
      final currentScope = existing?.scope ?? '(belum ada)';
      web.console.log('FCM: service worker saat ini: $currentScope'.toJS);
      final hasMessagingSw =
          existing != null && currentScope.contains('firebase-messaging-sw');
      if (!hasMessagingSw) {
        final reg =
            await sw.register('firebase-messaging-sw.js'.toJS).toDart;
        web.console.log('FCM: SW terdaftar → scope ${reg.scope}'.toJS);
      }
    } catch (e) {
      web.console.error('FCM: SW register gagal: $e'.toJS);
    }
  }

  /// Memastikan izin notifikasi web siap sebelum getToken.
  Future<bool> _ensureWebPermission() async {
    try {
      web.console.log('FCM: meminta izin notifikasi...'.toJS);
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings.authorizationStatus;
      web.console.log('FCM: authorizationStatus = $status'.toJS);

      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        return true;
      }

      if (status == AuthorizationStatus.denied) {
        _showPermissionGuidance(
          title: 'Izin Notifikasi Diblokir',
          message: 'Browser menandai izin notifikasi untuk situs ini sebagai '
              'DIBLOKIR, sehingga aplikasi tidak bisa menerima push.\n\n'
              'Cara perbaiki:\n'
              '1. Klik ikon 🔒 di address bar\n'
              '2. Pilih "Site settings"\n'
              '3. Bagian Notifications → ubah ke "Allow"\n'
              '4. Muat ulang halaman\n\n'
              '(Pastikan di chrome://settings/content/notifications saklar '
              '"Sites can ask to send notifications" AKTIF)',
        );
        return false;
      }

      _showPermissionGuidance(
        title: 'Izin Belum Diberikan',
        message: 'Status izin: $status. Klik "Allow" saat prompt muncul, lalu '
            'muat ulang halaman agar push aktif.',
      );
      return false;
    } catch (e, st) {
      final msg = 'FCM fase izin gagal: $e\n$st';
      web.console.error(msg.toJS);
      _showSnack('⚠️ $msg\n$_buildTag');
      return false;
    }
  }

  Future<void> _initializeNative() async {
    try {
      await _requestPermission();

      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      FirebaseMessaging.onMessage.listen(_handleMessage);
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    } catch (e, st) {
      if (kDebugMode) {
        print('FCM init error: $e\n$st');
      }
    }
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
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        if (kIsWeb) {
          await _ensureWebServiceWorker();
          web.console.log('FCM: getToken percobaan $attempt...'.toJS);
          final String? token =
              await _messaging.getToken(vapidKey: FirebaseMessagingVapidKey.web);
          web.console.log(
              'FCM: token diperoleh (${token?.length ?? 0} chars)'.toJS);
          if (token != null) return token;
          web.console.log('FCM: token null, coba lagi.'.toJS);
        } else {
          return await _messaging.getToken();
        }
      } catch (e, st) {
        final msg = 'FCM getToken percobaan $attempt gagal: $e\n$st';
        web.console.error(msg.toJS);
        _showSnack('⚠️ $msg\n$_buildTag');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  void _showSnack(String message) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPermissionGuidance({
    required String title,
    required String message,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('$title\n\n$message'),
        duration: const Duration(seconds: 20),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Muat Ulang',
          onPressed: () {
            if (kIsWeb) web.window.location.reload();
          },
        ),
      ),
    );
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
      if (kIsWeb) {
        web.console.log('FCM: token terdaftar (platform web)'.toJS);
      }
    } catch (e, st) {
      if (kIsWeb) {
        final msg = 'FCM register gagal: $e\n$st';
        web.console.error(msg.toJS);
        _showSnack('⚠️ $msg\n$_buildTag');
      } else if (kDebugMode) {
        print('FCM Register error: $e');
      }
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
    if (kIsWeb) {
      WebNotificationService.show(
        title: message.notification?.title ?? 'Wazuh Alert',
        body: message.notification?.body,
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Handle background notification
}
