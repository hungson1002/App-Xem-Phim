import 'package:flutter/material.dart';

import '../Components/bottom_navbar.dart';
import '../Components/home_app_bar.dart';
import '../Components/movie_section.dart';
import '../Components/movie_slide.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_notifier.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'watch_rooms_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final MovieService _movieService = MovieService();
  User? _user;

  List<Movie> _featuredMovies = [];
  List<Movie> _newMovies = [];
  List<Movie> _recommendedMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Listen to saved movie changes
    savedMovieNotifier.addListener(_onSavedMoviesChanged);
    _loadData();
  }

  @override
  void dispose() {
    savedMovieNotifier.removeListener(_onSavedMoviesChanged);
    super.dispose();
  }

  void _onSavedMoviesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getUser();

    // Lấy dữ liệu thực từ API
    final featured = await _movieService.getMoviesLimit(5);
    final newRelease = await _movieService.getMoviesByYear(2025, limit: 10);
    final recommended = await _movieService.getMoviesByCategory(
      'hanh-dong',
      limit: 10,
    );

    // Load saved movies state
    await savedMovieNotifier.loadSavedMovies();

    if (mounted) {
      setState(() {
        _user = user;
        _featuredMovies = featured;
        _newMovies = newRelease;
        _recommendedMovies = recommended;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaveMovie(int index) async {
    if (index >= _featuredMovies.length) return;

    final movie = _featuredMovies[index];
    final isCurrentlySaved = savedMovieNotifier.isMovieSaved(movie.slug);

    if (isCurrentlySaved) {
      final success = await savedMovieNotifier.removeSavedMovie(movie.slug);
      if (success && mounted) {
        AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
      }
    } else {
      final success = await savedMovieNotifier.saveMovie(movie.slug);
      if (success && mounted) {
        AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
      } else if (mounted) {
        AppSnackBar.showError(context, 'Không thể lưu phim');
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        return; // Current screen
      case 1:
        destination = const SearchScreen();
        break;
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get saved states for featured movies from notifier
    final featuredSavedStates = _featuredMovies
        .map((m) => savedMovieNotifier.isMovieSaved(m.slug))
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            HomeAppBar(user: _user),

            // Featured Movie Slide
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : MovieSlide(
                        movies: _featuredMovies
                            .map(
                              (m) => {
                                'title': m.name,
                                'year': m.year.toString(),
                                'genre': m.type,
                                'image': m.posterUrl,
                              },
                            )
                            .toList(),
                        bookmarkedStates: featuredSavedStates,
                        onBookmark: _toggleSaveMovie,
                        onMovieTap: (index) {
                          final movie = _featuredMovies[index];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(
                                movieId: movie.slug,
                                movie: movie,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Tiếp tục xem Section
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Tiếp tục xem',
                movies: _newMovies,
                isLoading: _isLoading,
                onSeeAll: () {
                  // Xử lý xem tất cả
                },
                titleIcon: Icons.play_circle_outline,
              ),
            ),

            // Phim mới ra mắt Section
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Phim mới ra mắt',
                movies: _newMovies,
                isLoading: _isLoading,
                onSeeAll: () {},
              ),
            ),

            // Top 10 tại Việt Nam Section
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Top 10 tại Việt Nam',
                movies: _recommendedMovies,
                isLoading: _isLoading,
                onSeeAll: () {},
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
