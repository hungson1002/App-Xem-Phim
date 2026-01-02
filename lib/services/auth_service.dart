import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

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

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = ApiConfig.loginUrl;
      print('=== Login API Debug ===');
      print('URL: $url');
      print('Email: $email');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.timeout);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      // Save token and user data if login successful
      if (authResponse.success && authResponse.token != null) {
        print('Login successful, saving token...');
        await _saveAuthData(authResponse.token!, authResponse.user);
      } else {
        print('Login failed: ${authResponse.message}');
      }

      return authResponse;
    } catch (e) {
      print('Login Error: $e');
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

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

  Future<AuthResponse> googleLogin({required String googleToken}) async {
    try {
      final url = ApiConfig.googleLoginUrl;
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'googleToken': googleToken}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);

      if (authResponse.success && authResponse.token != null) {
        await _saveAuthData(authResponse.token!, authResponse.user);
      }

      return authResponse;
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<AuthResponse> updateProfile({
    required String userId,
    String? name,
    String? avatar,
    String? password,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthResponse.error('Chưa đăng nhập');
      }

      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (avatar != null && avatar.isNotEmpty) body['avatar'] = avatar;
      if (password != null && password.isNotEmpty) body['password'] = password;

      final url = ApiConfig.updateUserUrl(userId);

      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['user'] != null) {
          final updatedUser = User.fromJson(data['user']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(ApiConfig.userKey, updatedUser.toJsonString());
        }
        return AuthResponse.fromJson(data);
      } else {
        return AuthResponse.error(data['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<void> _saveAuthData(String token, User? user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);
    if (user != null) {
      await prefs.setString(ApiConfig.userKey, user.toJsonString());
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(ApiConfig.userKey);
    if (userJson != null) {
      return User.fromJsonString(userJson);
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
    await prefs.remove(ApiConfig.userKey);
  }

  Future<AuthResponse> resendVerifyOtp({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.resendVerifyOtpUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<AuthResponse> forgotPassword({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.forgotPasswordUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<AuthResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.resetPasswordUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': otp,
              'newPassword': newPassword,
            }),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return AuthResponse.fromJson(data);
    } catch (e) {
      return AuthResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }
}
