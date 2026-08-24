import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

class FcmWebHelper {
  const FcmWebHelper();

  void log(String message) => web.console.log(message.toJS);

  void error(String message) => web.console.error(message.toJS);

  bool hasGlobal(String name) {
    try {
      return (web.window as JSObject).getProperty(name.toJS) != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureServiceWorker() async {
    try {
      final sw = web.window.navigator.serviceWorker;
      final existing = await sw.getRegistration().toDart;
      final currentScope = existing?.scope ?? '(belum ada)';
      web.console.log('FCM: service worker saat ini: $currentScope'.toJS);
      final hasMessagingSw =
          existing != null && currentScope.contains('firebase-messaging-sw');
      if (!hasMessagingSw) {
        final reg = await sw.register('firebase-messaging-sw.js'.toJS).toDart;
        web.console.log('FCM: SW terdaftar → scope ${reg.scope}'.toJS);
      }
    } catch (e) {
      web.console.error('FCM: SW register gagal: $e'.toJS);
    }
  }

  void reloadPage() {
    try {
      web.window.location.reload();
    } catch (_) {}
  }
}

const fcmWebHelper = FcmWebHelper();
