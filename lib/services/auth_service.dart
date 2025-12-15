import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'api_config.dart';

/// Service class for handling authentication API calls
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Register a new user
  /// Returns AuthResponse with success status and message
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.registerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Login with email and password
  /// Returns AuthResponse with token and user data on success
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      // Save token and user data if login successful
      if (authResponse.success && authResponse.token != null) {
        await _saveAuthData(authResponse.token!, authResponse.user);
      }

      return authResponse;
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Verify email with OTP code
  /// Returns AuthResponse with success status
  Future<AuthResponse> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.verifyEmailUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Login with Google token
  /// Returns AuthResponse with token and user data on success
  Future<AuthResponse> googleLogin({required String googleToken}) async {
    try {
      final url = ApiConfig.googleLoginUrl;
      print('=== Google Login API Debug ===');
      print('URL: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'googleToken': googleToken}),
          )
          .timeout(ApiConfig.timeout);

      print('Status Code: ${response.statusCode}');
      print(
        'Response Body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      // Save token and user data if login successful
      if (authResponse.success && authResponse.token != null) {
        await _saveAuthData(authResponse.token!, authResponse.user);
      }

      return authResponse;
    } catch (e) {
      print('Google Login Error: $e');
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthData(String token, User? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);
    if (user != null) {
      await prefs.setString(ApiConfig.userKey, user.toJsonString());
    }
  }

  /// Get saved token from local storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  /// Get saved user from local storage
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(ApiConfig.userKey);
    if (userJson != null) {
      return User.fromJsonString(userJson);
    }
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Logout - clear saved data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.userKey);
  }
}
