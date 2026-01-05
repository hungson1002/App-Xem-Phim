// Màn hình tìm kiếm phim, hỗ trợ tìm theo tên hoặc lọc theo danh mục.
import 'dart:async';
import 'package:flutter/material.dart';

import '../Components/bottom_navbar.dart';
import '../Components/search_bar_widget.dart';
import '../Components/category_filter_list.dart';
import '../Components/search_results_grid.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_notifier.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'watch_rooms_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MovieService _movieService = MovieService();
  final ScrollController _scrollController = ScrollController();

  int _currentIndex = 1;

  List<Movie> _movies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  int _currentPage = 1;
  bool _hasMore = true;
  static const int _limit = 20;

  Timer? _debounce;

  final Map<String, String> _categorySlugs = {
    'Tất cả': '',
    'Hành động': 'hanh-dong',
    'Tình cảm': 'tinh-cam',
    'Kinh dị': 'kinh-di',
    'Hoạt hình': 'hoat-hinh',
    'Viễn tưởng': 'vien-tuong',
  };

  late List<String> _categories;
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _categories = _categorySlugs.keys.toList();

    savedMovieNotifier.addListener(_onSavedMoviesChanged);
    if (!savedMovieNotifier.isLoaded) {
      savedMovieNotifier.loadSavedMovies();
    }

    _scrollController.addListener(_onScroll);

    _loadMovies();
  }

  @override
  void dispose() {
    savedMovieNotifier.removeListener(_onSavedMoviesChanged);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSavedMoviesChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreMovies();
      }
    }
  }

  Future<void> _loadMovies() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      List<Movie> newMovies;

      if (_searchQuery.isNotEmpty) {
        newMovies = await _movieService.searchMovies(
          _searchQuery,
          page: 1,
          limit: _limit,
        );
      } else {
        if (_selectedCategory == 'Tất cả') {
          newMovies = await _movieService.searchMovies(
            '',
            page: 1,
            limit: _limit,
          );
        } else {
          final slug = _categorySlugs[_selectedCategory]!;
          newMovies = await _movieService.getMoviesByCategory(
            slug,
            page: 1,
            limit: _limit,
          );
        }
      }

      if (mounted) {
        setState(() {
          _movies = newMovies;
          _currentPage = 1;
          _hasMore = newMovies.length >= _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreMovies() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      List<Movie> newMovies;
      final nextPage = _currentPage + 1;

      if (_searchQuery.isNotEmpty) {
        newMovies = await _movieService.searchMovies(
          _searchQuery,
          page: nextPage,
          limit: _limit,
        );
      } else {
        if (_selectedCategory == 'Tất cả') {
          newMovies = await _movieService.searchMovies(
            '',
            page: nextPage,
            limit: _limit,
          );
        } else {
          final slug = _categorySlugs[_selectedCategory]!;
          newMovies = await _movieService.getMoviesByCategory(
            slug,
            page: nextPage,
            limit: _limit,
          );
        }
      }

      if (mounted) {
        setState(() {
          _movies.addAll(newMovies);
          _currentPage = nextPage;
          _hasMore = newMovies.length >= _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _searchQuery = query;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadMovies();
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _searchQuery = '';
    });

    _loadMovies();
  }

  Future<void> _toggleSaveMovie(Movie movie) async {
    final slug = movie.slug;
    final isCurrentlySaved = savedMovieNotifier.isMovieSaved(slug);

    if (isCurrentlySaved) {
      final success = await savedMovieNotifier.removeSavedMovie(slug);
      if (success && mounted) {
        AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
      } else if (mounted) {
        AppSnackBar.showError(context, 'Không thể xóa phim');
      }
    } else {
      final success = await savedMovieNotifier.saveMovie(slug);
      if (success && mounted) {
        AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
      } else if (mounted) {
        AppSnackBar.showError(context, 'Không thể lưu phim');
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Widget destination;
      switch (index) {
        case 2:
          destination = const BookmarkScreen();
          break;
        case 3:
          destination = const WatchRoomsScreen();
          break;
        case 4:
          destination = const ProfileScreen();
          break;
        default:
          return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onFilterTap: () {},
                    ),
                  ),
                ],
              ),
            ),

            CategoryFilterList(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SearchResultsGrid(
                scrollController: _scrollController,
                movies: _movies,
                isLoading: _isLoading && _movies.isEmpty,
                emptyMessage: _searchQuery.isEmpty
                    ? 'Không có phim nào'
                    : 'Không tìm thấy kết quả cho "$_searchQuery"',
                isBookmarked: (movie) =>
                    savedMovieNotifier.isMovieSaved(movie.slug),
                onBookmark: _toggleSaveMovie,
                onMovieTap: (movie) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MovieDetailScreen(movieId: movie.slug, movie: movie),
                    ),
                  );
                },
              ),
            ),

            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
