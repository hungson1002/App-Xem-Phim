// Service API quản lý danh sách phim đã lưu (Saved Movies).
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class SavedMovieResponse {
  final bool success;
  final String? message;
  final List<SavedMovieItem>? savedMovies;

  SavedMovieResponse({required this.success, this.message, this.savedMovies});

  factory SavedMovieResponse.fromJson(Map<String, dynamic> json) {
    List<SavedMovieItem>? movieList;
    if (json['data'] != null) {
      movieList = (json['data'] as List)
          .map((item) => SavedMovieItem.fromJson(item))
          .toList();
    }

    return SavedMovieResponse(
      success: json['success'] ?? false,
      message: json['message'],
      savedMovies: movieList,
    );
  }

  factory SavedMovieResponse.error(String message) {
    return SavedMovieResponse(success: false, message: message);
  }
}

class SavedMovieItem {
  final String id;
  final String movieSlug;
  final Movie? movie;
  final DateTime createdAt;

  SavedMovieItem({
    required this.id,
    required this.movieSlug,
    this.movie,
    required this.createdAt,
  });

  factory SavedMovieItem.fromJson(Map<String, dynamic> json) {
    return SavedMovieItem(
      id: json['_id'] ?? '',
      movieSlug: json['movieSlug'] ?? '',
      movie: json['movie'] != null ? Movie.fromJson(json['movie']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class SavedMovieService {
  static final SavedMovieService _instance = SavedMovieService._internal();
  factory SavedMovieService() => _instance;
  SavedMovieService._internal();

  final AuthService _authService = AuthService();

  Future<SavedMovieResponse> getSavedMovies() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return SavedMovieResponse.error('Chưa đăng nhập');
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.getSavedMoviesUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return SavedMovieResponse.fromJson(data);
    } catch (e) {
      return SavedMovieResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<SavedMovieResponse> saveMovie(String movieSlug) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return SavedMovieResponse.error('Chưa đăng nhập');
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.saveMovieUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'movieID': movieSlug}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return SavedMovieResponse(
        success: data['success'] ?? false,
        message: data['message'],
      );
    } catch (e) {
      return SavedMovieResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<SavedMovieResponse> removeSavedMovie(String movieSlug) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return SavedMovieResponse.error('Chưa đăng nhập');
      }

      final response = await http
          .delete(
            Uri.parse(ApiConfig.removeSavedMovieUrl(movieSlug)),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      return SavedMovieResponse(
        success: data['success'] ?? false,
        message: data['message'],
      );
    } catch (e) {
      return SavedMovieResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<bool> isMovieSaved(String movieSlug) async {
    try {
      final response = await getSavedMovies();
      if (!response.success || response.savedMovies == null) {
        return false;
      }
      return response.savedMovies!.any((item) => item.movieSlug == movieSlug);
    } catch (e) {
      return false;
    }
  }

  Future<SavedMovieResponse> toggleSaveMovie(String movieSlug) async {
    final isSaved = await isMovieSaved(movieSlug);
    if (isSaved) {
      return removeSavedMovie(movieSlug);
    } else {
      return saveMovie(movieSlug);
    }
  }
}
