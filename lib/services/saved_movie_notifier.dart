import 'package:flutter/material.dart';

import 'saved_movie_service.dart';

/// Notifier to synchronize saved movie state across components
class SavedMovieNotifier extends ChangeNotifier {
  static final SavedMovieNotifier _instance = SavedMovieNotifier._internal();
  factory SavedMovieNotifier() => _instance;
  SavedMovieNotifier._internal();

  final SavedMovieService _savedMovieService = SavedMovieService();

  // Cache of saved movie slugs
  final Set<String> _savedSlugs = {};
  bool _isLoaded = false;

  Set<String> get savedSlugs => Set.unmodifiable(_savedSlugs);
  bool get isLoaded => _isLoaded;

  /// Check if a movie is saved
  bool isMovieSaved(String slug) {
    return _savedSlugs.contains(slug);
  }

  /// Load all saved movies from API
  Future<void> loadSavedMovies() async {
    final response = await _savedMovieService.getSavedMovies();
    if (response.success && response.savedMovies != null) {
      _savedSlugs.clear();
      for (var item in response.savedMovies!) {
        _savedSlugs.add(item.movieSlug);
      }
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save a movie and notify all listeners
  Future<bool> saveMovie(String slug) async {
    final response = await _savedMovieService.saveMovie(slug);
    if (response.success) {
      _savedSlugs.add(slug);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Remove a movie and notify all listeners
  Future<bool> removeSavedMovie(String slug) async {
    final response = await _savedMovieService.removeSavedMovie(slug);
    if (response.success) {
      _savedSlugs.remove(slug);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Toggle save status and notify all listeners
  Future<bool> toggleSaveMovie(String slug) async {
    if (isMovieSaved(slug)) {
      return removeSavedMovie(slug);
    } else {
      return saveMovie(slug);
    }
  }

  /// Force refresh from server
  Future<void> refresh() async {
    await loadSavedMovies();
  }
}

// Global instance for easy access
final savedMovieNotifier = SavedMovieNotifier();
