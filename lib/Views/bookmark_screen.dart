// Màn hình hiển thị danh sách phim đã lưu (Yêu thích).
import 'package:flutter/material.dart';
import '../Components/bookmark_card.dart';
import '../Components/bottom_navbar.dart';
import '../services/saved_movie_service.dart';
import '../utils/app_snackbar.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'watch_rooms_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  int _currentIndex = 2;
  bool _isGridView = true;
  bool _isLoading = true;
  String? _errorMessage;
  final SavedMovieService _savedMovieService = SavedMovieService();
  List<SavedMovieItem> _savedMovies = [];

  @override
  void initState() {
    super.initState();
    _loadSavedMovies();
  }

  Future<void> _loadSavedMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _savedMovieService.getSavedMovies();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _savedMovies = response.savedMovies ?? [];
        } else {
          _errorMessage = response.message ?? 'Không thể tải danh sách phim';
        }
      });
    }
  }

  Future<void> _deleteSavedMovie(int index) async {
    final savedMovie = _savedMovies[index];

    final response = await _savedMovieService.removeSavedMovie(
      savedMovie.movieSlug,
    );

    if (response.success && mounted) {
      setState(() {
        _savedMovies.removeAt(index);
      });
      AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
    } else if (mounted) {
      AppSnackBar.showError(context, response.message ?? 'Không thể xóa phim');
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Widget destination;
      switch (index) {
        case 1:
          destination = const SearchScreen();
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
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0B0E13)
            : const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(
          'Phim đã lưu',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: _loadSavedMovies,
          ),
        ],
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSavedMovies,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_savedMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có phim nào được lưu',
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm phim yêu thích vào danh sách!',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_savedMovies.length} mục',
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.black54,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      color: _isGridView
                          ? const Color(0xFF5BA3F5)
                          : Colors.grey,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.list,
                      color: !_isGridView
                          ? const Color(0xFF5BA3F5)
                          : Colors.grey,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _isGridView ? _buildGridView() : _buildListView()),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _savedMovies.length,
      itemBuilder: (context, index) {
        final savedMovie = _savedMovies[index];
        final movie = savedMovie.movie;
        return BookmarkCard(
          title: movie?.name ?? 'Unknown',
          year: movie?.year.toString() ?? '',
          genre: movie?.category.isNotEmpty == true
              ? movie!.category.first
              : '',
          imageUrl: movie?.posterUrl ?? '',
          onDelete: () => _deleteSavedMovie(index),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MovieDetailScreen(movieId: savedMovie.movieSlug),
              ),
            ).then((_) => _loadSavedMovies());
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _savedMovies.length,
      itemBuilder: (context, index) {
        final savedMovie = _savedMovies[index];
        final movie = savedMovie.movie;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 140,
            child: BookmarkCard(
              title: movie?.name ?? 'Unknown',
              year: movie?.year.toString() ?? '',
              genre: movie?.category.isNotEmpty == true
                  ? movie!.category.first
                  : '',
              imageUrl: movie?.posterUrl ?? '',
              onDelete: () => _deleteSavedMovie(index),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MovieDetailScreen(movieId: savedMovie.movieSlug),
                  ),
                ).then((_) => _loadSavedMovies());
              },
            ),
          ),
        );
      },
    );
  }
}
