import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MovieProgress {
  final String movieSlug;
  final int serverIndex;
  final int episodeIndex;
  final int positionSeconds;
  final int lastUpdated;

  MovieProgress({
    required this.movieSlug,
    required this.serverIndex,
    required this.episodeIndex,
    required this.positionSeconds,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'movieSlug': movieSlug,
      'serverIndex': serverIndex,
      'episodeIndex': episodeIndex,
      'positionSeconds': positionSeconds,
      'lastUpdated': lastUpdated,
    };
  }

  factory MovieProgress.fromJson(Map<String, dynamic> json) {
    return MovieProgress(
      movieSlug: json['movieSlug'] ?? '',
      serverIndex: json['serverIndex'] ?? 0,
      episodeIndex: json['episodeIndex'] ?? 0,
      positionSeconds: json['positionSeconds'] ?? 0,
      lastUpdated: json['lastUpdated'] ?? 0,
    );
  }
}

class HistoryService {
  static const String _prefix = 'movie_progress_';

  Future<void> saveProgress(MovieProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix${progress.movieSlug}';
      final jsonStr = jsonEncode(progress.toJson());
      await prefs.setString(key, jsonStr);
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  Future<MovieProgress?> getProgress(String movieSlug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$movieSlug';
      final jsonStr = prefs.getString(key);

      if (jsonStr != null) {
        return MovieProgress.fromJson(jsonDecode(jsonStr));
      }
    } catch (e) {
      print('Error getting progress: $e');
    }
    return null;
  }

  Future<void> clearProgress(String movieSlug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$movieSlug';
      await prefs.remove(key);
    } catch (e) {
      print('Error clearing progress: $e');
    }
  }
}
