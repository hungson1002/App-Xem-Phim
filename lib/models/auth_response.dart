// Model phản hồi xác thực từ API.
import 'user_model.dart';

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final User? user;

  AuthResponse({required this.success, this.message, this.token, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      user: json['auth'] != null ? User.fromJson(json['auth']) : null,
    );
  }

  factory AuthResponse.error(String message) {
    return AuthResponse(success: false, message: message);
  }
}
