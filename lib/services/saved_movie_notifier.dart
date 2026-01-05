// Notifier để đồng bộ trạng thái phim đã lưu giữa các thành phần UI.
import 'package:flutter/material.dart';
import 'saved_movie_service.dart';

class SavedMovieNotifier extends ChangeNotifier {
  static final SavedMovieNotifier _instance = SavedMovieNotifier._internal();
  factory SavedMovieNotifier() => _instance;
  SavedMovieNotifier._internal();

  final SavedMovieService _savedMovieService = SavedMovieService();

  final Set<String> _savedSlugs = {};
  bool _isLoaded = false;

  Set<String> get savedSlugs => Set.unmodifiable(_savedSlugs);
  bool get isLoaded => _isLoaded;

  bool isMovieSaved(String slug) {
    return _savedSlugs.contains(slug);
  }

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

  Future<bool> saveMovie(String slug) async {
    final response = await _savedMovieService.saveMovie(slug);
    if (response.success) {
      _savedSlugs.add(slug);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeSavedMovie(String slug) async {
    final response = await _savedMovieService.removeSavedMovie(slug);
    if (response.success) {
      _savedSlugs.remove(slug);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> toggleSaveMovie(String slug) async {
    if (isMovieSaved(slug)) {
      return removeSavedMovie(slug);
    } else {
      return saveMovie(slug);
    }
  }

  Future<void> refresh() async {
    await loadSavedMovies();
  }
}

final savedMovieNotifier = SavedMovieNotifier();
