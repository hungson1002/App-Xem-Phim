/// API Configuration for the Flutter app

class ApiConfig {
  // Base URL for the backend API
  // Web: dùng IP thực của máy
  // Android Emulator: dùng 10.0.2.2 thay cho localhost
  static const String baseUrl = 'http://10.0.4.1:4000';

  // API Endpoints
  static const String authEndpoint = '/api/auth';
  static const String userEndpoint = '/api/user';
  static const String commentEndpoint = '/api/comments';
  static const String movieEndpoint = '/api/movies';

  // Auth endpoints
  static String get registerUrl => '$baseUrl$authEndpoint/register';
  static String get loginUrl => '$baseUrl$authEndpoint/login';
  static String get verifyEmailUrl => '$baseUrl$authEndpoint/verify-email';
  static String get googleLoginUrl => '$baseUrl$authEndpoint/google-login';
  static String get resendVerifyOtpUrl =>
      '$baseUrl$authEndpoint/resend-verify-otp';
  static String get forgotPasswordUrl =>
      '$baseUrl$authEndpoint/forgot-password';
  static String get resetPasswordUrl => '$baseUrl$authEndpoint/reset-password';

  // User endpoints
  static String updateUserUrl(String userId) => '$baseUrl$userEndpoint/$userId';

  // Comment endpoints
  static String getCommentsUrl(String movieId) =>
      '$baseUrl$commentEndpoint/$movieId';
  static String get addCommentUrl => '$baseUrl$commentEndpoint/add';

  // Movie endpoints
  static String getMoviesLimitUrl(int limit) => '$baseUrl$movieEndpoint/limit/$limit';
  static String getMoviesByCategoryUrl(String slug) => '$baseUrl$movieEndpoint/category/$slug';
  static String getMoviesByCountryUrl(String slug) => '$baseUrl$movieEndpoint/country/$slug';
  static String getMoviesByYearUrl(int year) => '$baseUrl$movieEndpoint/year/$year';
  static String getMovieDetailUrl(String slug) => '$baseUrl$movieEndpoint/$slug';
  static String get searchMoviesUrl => '$baseUrl$movieEndpoint/search';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);

  // Shared Preferences keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
