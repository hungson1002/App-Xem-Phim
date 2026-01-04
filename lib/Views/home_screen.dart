import 'package:flutter/material.dart';

import '../Components/app_snackbar.dart';
import '../Components/bottom_navbar.dart';
import '../Components/home_app_bar.dart';
import '../Components/movie_section.dart';
import '../Components/movie_slide.dart';
import '../main.dart';
import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_service.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final MovieService _movieService = MovieService();
  final SavedMovieService _savedMovieService = SavedMovieService();
  User? _user;

  List<Movie> _featuredMovies = [];
  List<Movie> _newMovies = [];
  List<Movie> _recommendedMovies = [];
  Set<String> _savedMovieSlugs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer để detect khi route thay đổi
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Được gọi khi một route khác được pop và HomeScreen hiển thị lại
    _refreshSavedMovies();
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
    final savedSlugs = await _savedMovieService.getSavedMovieSlugs();

    if (mounted) {
      setState(() {
        _user = user;
        _featuredMovies = featured;
        _newMovies = newRelease;
        _recommendedMovies = recommended;
        _savedMovieSlugs = savedSlugs;
        _isLoading = false;
      });
    }
  }

  /// Chỉ refresh lại danh sách phim đã lưu (không load lại toàn bộ dữ liệu)
  Future<void> _refreshSavedMovies() async {
    final savedSlugs = await _savedMovieService.getSavedMovieSlugs();
    if (mounted) {
      setState(() {
        _savedMovieSlugs = savedSlugs;
      });
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        return;
      case 1:
        destination = const SearchScreen();
        break;
      case 2:
        destination = const BookmarkScreen();
        break;
      case 3:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    ).then((_) {
      // Refresh saved movies khi quay lại từ BookmarkScreen hoặc các màn hình khác
      _refreshSavedMovies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                                'slug': m.slug,
                              },
                            )
                            .toList(),
                        bookmarkedStates: _featuredMovies
                            .map((m) => _savedMovieSlugs.contains(m.slug))
                            .toList(),
                        onBookmark: (index) async {
                          final movie = _featuredMovies[index];
                          final slug = movie.slug;
                          final wasSaved = _savedMovieSlugs.contains(slug);

                          final result = await _savedMovieService
                              .toggleBookmark(slug);
                          if (result['success'] == true && mounted) {
                            // Refresh để tạo Set mới, giúp MovieSection detect thay đổi
                            await _refreshSavedMovies();

                            if (wasSaved) {
                              AppSnackBar.showWarning(
                                context,
                                'Đã xóa khỏi danh sách',
                              );
                            } else {
                              AppSnackBar.showSuccess(context, 'Đã lưu phim');
                            }
                          }
                        },
                        onMovieTap: (index) {
                          final slug = _featuredMovies[index].slug;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailScreen(slug: slug),
                            ),
                          ).then((_) => _refreshSavedMovies());
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
                savedMovieSlugs: _savedMovieSlugs,
                onSeeAll: () {},
                titleIcon: Icons.play_circle_outline,
                onBookmarkChanged: _refreshSavedMovies,
              ),
            ),

            // Phim mới ra mắt Section
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Phim mới ra mắt',
                movies: _newMovies,
                isLoading: _isLoading,
                savedMovieSlugs: _savedMovieSlugs,
                onSeeAll: () {},
                onBookmarkChanged: _refreshSavedMovies,
              ),
            ),

            // Top 10 tại Việt Nam Section
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Top 10 tại Việt Nam',
                movies: _recommendedMovies,
                isLoading: _isLoading,
                savedMovieSlugs: _savedMovieSlugs,
                onSeeAll: () {},
                onBookmarkChanged: _refreshSavedMovies,
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
