import 'dart:convert';

/// User model representing the authenticated user
class User {
  final String id;
  final String name;
  final String email;
  final String? provider;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.provider,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      provider: json['provider'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'provider': provider,
      'avatar': avatar,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory User.fromJsonString(String jsonString) {
    return User.fromJson(jsonDecode(jsonString));
  }
}
