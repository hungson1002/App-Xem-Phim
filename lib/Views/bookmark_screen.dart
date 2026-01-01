import 'package:flutter/material.dart';

import '../Components/bookmark_card.dart';
import '../Components/bottom_navbar.dart';
import '../services/saved_movie_service.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  int _currentIndex = 2;
  bool _isGridView = true;
  bool _isLoading = true;

  final SavedMovieService _savedMovieService = SavedMovieService();
  List<Map<String, dynamic>> _bookmarkedMovies = [];

  @override
  void initState() {
    super.initState();
    _loadSavedMovies();
  }

  Future<void> _loadSavedMovies() async {
    setState(() => _isLoading = true);
    final savedMovies = await _savedMovieService.getSavedMovies();
    if (mounted) {
      setState(() {
        _bookmarkedMovies = savedMovies;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMovie(String movieSlug, int index) async {
    final result = await _savedMovieService.removeMovie(movieSlug);
    if (result['success'] == true && mounted) {
      setState(() {
        _bookmarkedMovies.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa khỏi danh sách'),
          backgroundColor: Colors.orange,
        ),
      );
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

  // Helper methods to extract movie data
  String _getTitle(Map<String, dynamic> item) {
    final movie = item['movie'];
    if (movie is Map<String, dynamic>) {
      return movie['name'] ?? movie['title'] ?? 'Unknown';
    }
    return item['movieSlug'] ?? 'Unknown';
  }

  String _getSlug(Map<String, dynamic> item) {
    return item['movieSlug'] ?? '';
  }

  String _getImage(Map<String, dynamic> item) {
    final movie = item['movie'];
    if (movie is Map<String, dynamic>) {
      return movie['poster_url'] ??
          movie['thumb_url'] ??
          'https://picsum.photos/200/300';
    }
    return 'https://picsum.photos/200/300';
  }

  String _getYear(Map<String, dynamic> item) {
    final movie = item['movie'];
    if (movie is Map<String, dynamic>) {
      return movie['year']?.toString() ?? '';
    }
    return '';
  }

  String _getGenre(Map<String, dynamic> item) {
    final movie = item['movie'];
    if (movie is Map<String, dynamic>) {
      return movie['type'] ?? '';
    }
    return '';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedMovies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: isDark ? Colors.grey : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có phim nào được lưu',
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_bookmarkedMovies.length} mục',
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
                            onPressed: () =>
                                setState(() => _isGridView = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: _bookmarkedMovies.length,
                          itemBuilder: (context, index) {
                            final item = _bookmarkedMovies[index];
                            final slug = _getSlug(item);
                            return BookmarkCard(
                              title: _getTitle(item),
                              year: _getYear(item),
                              genre: _getGenre(item),
                              imageUrl: _getImage(item),
                              onDelete: () => _removeMovie(slug, index),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MovieDetailScreen(slug: slug),
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _bookmarkedMovies.length,
                          itemBuilder: (context, index) {
                            final item = _bookmarkedMovies[index];
                            final slug = _getSlug(item);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SizedBox(
                                height: 140,
                                child: BookmarkCard(
                                  title: _getTitle(item),
                                  year: _getYear(item),
                                  genre: _getGenre(item),
                                  imageUrl: _getImage(item),
                                  onDelete: () => _removeMovie(slug, index),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MovieDetailScreen(slug: slug),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
