/// API Configuration for the Flutter app

class ApiConfig {
  // Base URL for the backend API
  // Android Emulator: dùng 10.0.2.2 thay cho localhost
  static const String baseUrl = 'http://10.0.2.2:4000';

  // API Endpoints
  static const String authEndpoint = '/api/auth';

  // Auth endpoints
  static String get registerUrl => '$baseUrl$authEndpoint/register';
  static String get loginUrl => '$baseUrl$authEndpoint/login';
  static String get verifyEmailUrl => '$baseUrl$authEndpoint/verify-email';
  static String get googleLoginUrl => '$baseUrl$authEndpoint/google-login';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);

  // Shared Preferences keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
