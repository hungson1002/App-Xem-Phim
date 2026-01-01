import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class SavedMovieService {
  static final SavedMovieService _instance = SavedMovieService._internal();
  factory SavedMovieService() => _instance;
  SavedMovieService._internal();

  final AuthService _authService = AuthService();

  /// Lưu phim vào danh sách bookmark
  Future<Map<String, dynamic>> saveMovie(String movieSlug) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.savedMoviesUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'movieID': movieSlug}),
          )
          .timeout(ApiConfig.timeout);

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// Xóa phim khỏi danh sách bookmark
  Future<Map<String, dynamic>> removeMovie(String movieSlug) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
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

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  /// Lấy danh sách phim đã lưu
  Future<List<Map<String, dynamic>>> getSavedMovies() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      final response = await http
          .get(
            Uri.parse(ApiConfig.savedMoviesUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Lấy danh sách slug phim đã lưu
  Future<Set<String>> getSavedMovieSlugs() async {
    final savedMovies = await getSavedMovies();
    final Set<String> slugs = {};

    for (final item in savedMovies) {
      // movieSlug là field được trả về từ backend aggregate
      final slug = item['movieSlug']?.toString() ?? '';
      if (slug.isNotEmpty) {
        slugs.add(slug);
      }
    }
    return slugs;
  }

  /// Kiểm tra phim đã được lưu chưa
  Future<bool> isMovieSaved(String movieSlug) async {
    final savedSlugs = await getSavedMovieSlugs();
    return savedSlugs.contains(movieSlug);
  }

  /// Toggle trạng thái bookmark
  Future<Map<String, dynamic>> toggleBookmark(String movieSlug) async {
    final isSaved = await isMovieSaved(movieSlug);
    if (isSaved) {
      return await removeMovie(movieSlug);
    } else {
      return await saveMovie(movieSlug);
    }
  }
}
