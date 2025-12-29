import 'user_model.dart';

class Comment {
  final String id;
  final User? user;
  final String content;
  final DateTime createdAt;
  final String movieId;

  Comment({
    required this.id,
    this.user,
    required this.content,
    required this.createdAt,
    required this.movieId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? '',
      user: json['userId'] != null ? User.fromJson(json['userId']) : null,
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      movieId: json['movieId'] ?? '',
    );
  }

  // Helper method to get display time
  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
