class WebNotificationService {
  static Future<bool> requestPermission() async => false;
  static bool get canNotify => false;
  static void show({required String title, String? body}) {}
}
