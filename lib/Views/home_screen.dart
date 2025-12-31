import 'dart:convert';
import 'package:flutter/material.dart';

import '../Components/bottom_navbar.dart';
import '../Components/movie_card.dart';
import '../Components/movie_slide.dart';
import '../models/user_model.dart';
import '../models/movie_model.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

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
  List<Movie> _recommendedMovies = []; // Could filter by category
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getUser();
    
    // Fetch real data
    // Example: Feature = limit 5, New = limit 10, Recommended = category 'hanh-dong'
    final featured = await _movieService.getMoviesLimit(5);
    final newRelease = await _movieService.getMoviesByYear(2025, limit: 10);
    final recommended = await _movieService.getMoviesByCategory('hanh-dong', limit: 10);

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

  ImageProvider? _getAvatarImage() {
    if (_user?.avatar == null || _user!.avatar!.isEmpty) {
      return null;
    }

    final avatar = _user!.avatar!;
    if (avatar.startsWith('data:image')) {
      // Base64 image
      try {
        final base64Data = avatar.split(',').last;
        return MemoryImage(base64Decode(base64Data));
      } catch (e) {
        return null;
      }
    } else {
      // URL image
      return NetworkImage(avatar);
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
    );
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
            SliverAppBar(
              backgroundColor: isDark
                  ? const Color(0xFF0B0E13)
                  : const Color(0xFFF5F5F5),
              elevation: 0,
              floating: true,
              pinned: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA3F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.movie, color: Colors.white),
                ),
              ),
              title: Text(
                'MovieApp',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF5BA3F5),
                      backgroundImage: _getAvatarImage(),
                      child: _user?.avatar == null || _user!.avatar!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            // Featured Movie Slide
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _isLoading ? const Center(child: CircularProgressIndicator()) : MovieSlide(
                  movies: _featuredMovies.map((m) => {
                    'title': m.name,
                    'year': m.year.toString(),
                    'genre': m.type, // or category name
                    'image': m.posterUrl
                  }).toList(),
                  bookmarkedStates: List.filled(_featuredMovies.length, false), // TODO: implement real bookmark check
                  onBookmark: (index) {
                     // TODO: Call API
                  },
                  onMovieTap: (index) {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(), // TODO: Pass movie slug/id
                      ),
                    );
                  },
                ),
              ),
            ),

            // Tiếp tục xem Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Color(0xFF5BA3F5),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tiếp tục xem',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(color: Color(0xFF5BA3F5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _newMovies.length,
                  itemBuilder: (context, index) {
                    final movie = _newMovies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: movie.name,
                          imageUrl: movie.posterUrl.isNotEmpty ? movie.posterUrl : 'https://picsum.photos/200/300',
                          year: movie.year.toString(),
                          genre: movie.type, 
                          isBookmarked: false, // TODO
                          onBookmark: () {},
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MovieDetailScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Phim mới ra mắt Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phim mới ra mắt',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'XEM TẤT CẢ',
                        style: TextStyle(
                          color: Color(0xFF5BA3F5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendedMovies.length,
                  itemBuilder: (context, index) {
                     final movie = _recommendedMovies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: movie.name,
                          imageUrl: movie.posterUrl.isNotEmpty ? movie.posterUrl : 'https://picsum.photos/200/300',
                          year: movie.year.toString(),
                          genre: movie.type,
                          isBookmarked: false,
                          onBookmark: () {},
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MovieDetailScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Top 10 tại Việt Nam Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top 10 tại Việt Nam',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'XEM TẤT CẢ',
                        style: TextStyle(
                          color: Color(0xFF5BA3F5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendedMovies.length,
                  itemBuilder: (context, index) {
                    final movie = _recommendedMovies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: movie.name,
                          imageUrl: movie.posterUrl.isNotEmpty ? movie.posterUrl : 'https://picsum.photos/200/300',
                          year: movie.year.toString(),
                          genre: movie.type, 
                          isBookmarked: false, // TODO
                          onBookmark: () {},
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MovieDetailScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
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

  Widget _buildCategoryChip(String label, bool isSelected, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF5BA3F5)
            : (isDark ? const Color(0xFF1A2332) : const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isSelected || !isDark ? Colors.white : Colors.black,
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected || isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
