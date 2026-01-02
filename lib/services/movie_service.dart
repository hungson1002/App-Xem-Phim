import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import 'api_config.dart';

class MovieService {
  // Get latest movies with limit
  Future<List<Movie>> getMoviesLimit(int limit) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getMoviesLimitUrl(limit)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies: $e');
      return [];
    }
  }

  // Get movies by category
  Future<List<Movie>> getMoviesByCategory(
    String slug, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getMoviesByCategoryUrl(slug)).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies by category: $e');
      return [];
    }
  }

  // Get movies by year
  Future<List<Movie>> getMoviesByYear(
    int year, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getMoviesByYearUrl(year)).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies by year: $e');
      return [];
    }
  }

  // Get movie details
  Future<Movie?> getMovieDetail(String slug) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getMovieDetailUrl(slug)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Movie.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching movie detail: $e');
      return null;
    }
  }

  // Search movies
  Future<List<Movie>> searchMovies(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.searchMoviesUrl).replace(
        queryParameters: {
          'q': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }
}
