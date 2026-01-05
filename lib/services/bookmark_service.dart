import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Response model for bookmark operations
class BookmarkResponse {
  final bool success;
  final String? message;
  final List<BookmarkItem>? bookmarks;
  final bool? isBookmarked;

  BookmarkResponse({
    required this.success,
    this.message,
    this.bookmarks,
    this.isBookmarked,
  });

  factory BookmarkResponse.fromJson(Map<String, dynamic> json) {
    List<BookmarkItem>? bookmarkList;
    if (json['bookmarks'] != null) {
      bookmarkList = (json['bookmarks'] as List)
          .map((item) => BookmarkItem.fromJson(item))
          .toList();
    }

    return BookmarkResponse(
      success: json['success'] ?? false,
      message: json['message'],
      bookmarks: bookmarkList,
      isBookmarked: json['isBookmarked'],
    );
  }

  factory BookmarkResponse.error(String message) {
    return BookmarkResponse(success: false, message: message);
  }
}

/// Model for a single bookmark item
class BookmarkItem {
  final String id;
  final String movieId;
  final String movieSlug;
  final String movieName;
  final String posterUrl;
  final int year;
  final List<String> category;
  final DateTime createdAt;

  BookmarkItem({
    required this.id,
    required this.movieId,
    required this.movieSlug,
    required this.movieName,
    required this.posterUrl,
    required this.year,
    required this.category,
    required this.createdAt,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['_id'] ?? '',
      movieId: json['movieId'] ?? '',
      movieSlug: json['movieSlug'] ?? '',
      movieName: json['movieName'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      year: json['year'] ?? 0,
      category: json['category'] != null
          ? List<String>.from(json['category'])
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Service class for bookmark operations
class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  final AuthService _authService = AuthService();

  /// Get all bookmarks for the current user
  Future<BookmarkResponse> getBookmarks() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return BookmarkResponse.error('Chưa đăng nhập');
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.getBookmarksUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return BookmarkResponse.fromJson(data);
    } catch (e) {
      return BookmarkResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Add a movie to bookmarks
  Future<BookmarkResponse> addBookmark(Movie movie) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return BookmarkResponse.error('Chưa đăng nhập');
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.addBookmarkUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'movieId': movie.id,
              'movieSlug': movie.slug,
              'movieName': movie.name,
              'posterUrl': movie.posterUrl,
              'year': movie.year,
              'category': movie.category,
            }),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return BookmarkResponse.fromJson(data);
    } catch (e) {
      return BookmarkResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Remove a movie from bookmarks
  Future<BookmarkResponse> removeBookmark(String movieId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return BookmarkResponse.error('Chưa đăng nhập');
      }

      final response = await http
          .delete(
            Uri.parse(ApiConfig.removeBookmarkUrl(movieId)),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return BookmarkResponse.fromJson(data);
    } catch (e) {
      return BookmarkResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Check if a movie is bookmarked
  Future<bool> checkBookmark(String movieId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return false;
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.checkBookmarkUrl(movieId)),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return data['isBookmarked'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
