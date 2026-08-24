class FcmWebHelper {
  const FcmWebHelper();

  void log(String message) {}
  void error(String message) {}
  bool hasGlobal(String name) => false;
  Future<void> ensureServiceWorker() async {}
  void reloadPage() {}
}

const fcmWebHelper = FcmWebHelper();
