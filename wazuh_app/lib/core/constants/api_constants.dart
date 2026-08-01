class ApiConstants {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://siemkampus-monitoring-app.duckdns.org/api');
  static const String login = '/auth/login';
  static const String dashboard = '/dashboard';
  static const String alerts = '/alerts';
  static const String agents = '/agents';
  static const String deviceToken = '/device-token';

  static const Duration timeout = Duration(seconds: 30);
}
