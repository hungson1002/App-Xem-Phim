import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class CommentService {
  static final CommentService _instance = CommentService._internal();

  factory CommentService() => _instance;

  CommentService._internal();

  final AuthService _authService = AuthService();

  // Lấy danh sách bình luận cho một bộ phim
  Future<List<Comment>> getComments(String movieId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getCommentsUrl(movieId)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> commentsData = data['data'];
          return commentsData.map((e) => Comment.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  // Thêm bình luận mới
  Future<Comment?> addComment(String movieId, String content) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print("LỖI: Chưa có Token (Chưa đăng nhập)");
        return null;
      }

      print("Đang gửi đến: ${ApiConfig.addCommentUrl}");

      final response = await http
          .post(
            Uri.parse(ApiConfig.addCommentUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'movieId': movieId, 'content': content}),
          )
          .timeout(ApiConfig.timeout);

      print("Status Code: ${response.statusCode}");
      print("Server Response: ${response.body}");

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Comment.fromJson(data['data']);
        }
      }

      // Nếu không phải 201 thì in ra lỗi để biết đường sửa
      print(
        "GỬI THẤT BẠI. Code: ${response.statusCode}, Lý do: ${response.body}",
      );
      return null;
    } catch (e) {
      print('LỖI KẾT NỐI (Socket/Timeout): $e');
      return null;
    }
  }

  // Xóa bình luận
  Future<bool> deleteComment(String movieId, String commentId) async {
    try {
      final token = await _authService.getToken();
      final url = '${ApiConfig.baseUrl}/api/comments/$movieId/$commentId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Sửa bình luận
  Future<bool> updateComment(
    String movieId,
    String commentId,
    String newContent,
  ) async {
    try {
      final token = await _authService.getToken();
      final url = '${ApiConfig.baseUrl}/api/comments/$movieId/$commentId';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': newContent}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating comment: $e');
      return false;
    }
  }
}
