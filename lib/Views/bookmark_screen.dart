import 'package:flutter/material.dart';

import '../Components/bookmark_card.dart';
import '../Components/bottom_navbar.dart';
import '../services/bookmark_service.dart';
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
  String? _errorMessage;

  final BookmarkService _bookmarkService = BookmarkService();
  List<BookmarkItem> _bookmarkedMovies = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _bookmarkService.getBookmarks();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          _bookmarkedMovies = response.bookmarks ?? [];
        } else {
          _errorMessage = response.message ?? 'Không thể tải danh sách phim';
        }
      });
    }
  }

  Future<void> _deleteBookmark(int index) async {
    final bookmark = _bookmarkedMovies[index];

    final response = await _bookmarkService.removeBookmark(bookmark.movieId);

    if (response.success && mounted) {
      setState(() {
        _bookmarkedMovies.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa khỏi danh sách lưu')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Không thể xóa phim')),
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
            onPressed: _loadBookmarks,
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
              onPressed: _loadBookmarks,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_bookmarkedMovies.isEmpty) {
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
        // Movie Count and View Toggle
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
                    onPressed: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bookmarked Movies Grid/List
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
      itemCount: _bookmarkedMovies.length,
      itemBuilder: (context, index) {
        final bookmark = _bookmarkedMovies[index];
        return BookmarkCard(
          title: bookmark.movieName,
          year: bookmark.year.toString(),
          genre: bookmark.category.isNotEmpty ? bookmark.category.first : '',
          imageUrl: bookmark.posterUrl,
          onDelete: () => _deleteBookmark(index),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MovieDetailScreen(movieId: bookmark.movieId),
              ),
            ).then((_) => _loadBookmarks()); // Refresh after returning
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _bookmarkedMovies.length,
      itemBuilder: (context, index) {
        final bookmark = _bookmarkedMovies[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 140,
            child: BookmarkCard(
              title: bookmark.movieName,
              year: bookmark.year.toString(),
              genre: bookmark.category.isNotEmpty
                  ? bookmark.category.first
                  : '',
              imageUrl: bookmark.posterUrl,
              onDelete: () => _deleteBookmark(index),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MovieDetailScreen(movieId: bookmark.movieId),
                  ),
                ).then((_) => _loadBookmarks()); // Refresh after returning
              },
            ),
          ),
        );
      },
    );
  }
}
