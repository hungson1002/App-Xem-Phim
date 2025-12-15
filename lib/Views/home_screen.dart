import 'package:flutter/material.dart';

import '../Components/bottom_navbar.dart';
import '../Components/movie_card.dart';
import '../Components/movie_slide.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
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
  final List<bool> _bookmarkedMovies = List.filled(10, false);
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
    });
  }

  final List<Map<String, String>> _featuredMovies = [
    {
      'title': 'Dune: Part Two',
      'year': '2024',
      'genre': 'Khoa học viễn tưởng',
      'image': 'https://picsum.photos/seed/dune/400/600',
    },
    {
      'title': 'Inception',
      'year': '2010',
      'genre': 'Khoa học viễn tưởng',
      'image': 'https://picsum.photos/seed/inception/400/600',
    },
    {
      'title': 'Interstellar',
      'year': '2014',
      'genre': 'Viễn tưởng',
      'image': 'https://picsum.photos/seed/interstellar/400/600',
    },
  ];

  final List<Map<String, String>> _newMovies = [
    {
      'title': 'The Fall Guy',
      'year': '2024',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/fallguy/200/300',
    },
    {
      'title': 'Civil War',
      'year': '2024',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/civilwar/200/300',
    },
    {
      'title': 'Furiosa',
      'year': '2024',
      'genre': 'Phiêu lưu',
      'image': 'https://picsum.photos/seed/furiosa/200/300',
    },
  ];

  final List<Map<String, String>> _recommendedMovies = [
    {
      'title': 'Joker',
      'year': '2019',
      'genre': 'Tội phạm',
      'image': 'https://picsum.photos/seed/joker/200/300',
    },
    {
      'title': 'Interstellar',
      'year': '2014',
      'genre': 'Viễn tưởng',
      'image': 'https://picsum.photos/seed/inter2/200/300',
    },
    {
      'title': 'Parasite',
      'year': '2019',
      'genre': 'Kịch tính',
      'image': 'https://picsum.photos/seed/parasite/200/300',
    },
  ];

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
                      backgroundImage: _user?.avatar != null
                          ? NetworkImage(_user!.avatar!)
                          : null,
                      child: _user?.avatar == null
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
                child: MovieSlide(
                  movies: _featuredMovies,
                  bookmarkedStates: _bookmarkedMovies,
                  onBookmark: (index) {
                    setState(() {
                      _bookmarkedMovies[index] = !_bookmarkedMovies[index];
                    });
                  },
                  onMovieTap: (index) {
                    // TODO: Navigate to movie detail
                    print('Tapped on ${_featuredMovies[index]['title']}');
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
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _newMovies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: _newMovies[index]['title']!,
                          imageUrl: _newMovies[index]['image']!,
                          year: _newMovies[index]['year'],
                          genre: _newMovies[index]['genre'],
                          isBookmarked: _bookmarkedMovies[index + 1],
                          onBookmark: () {
                            setState(() {
                              _bookmarkedMovies[index + 1] =
                                  !_bookmarkedMovies[index + 1];
                            });
                          },
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
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendedMovies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: _recommendedMovies[index]['title']!,
                          imageUrl: _recommendedMovies[index]['image']!,
                          year: _recommendedMovies[index]['year'],
                          genre: _recommendedMovies[index]['genre'],
                          isBookmarked: _bookmarkedMovies[index + 4],
                          onBookmark: () {
                            setState(() {
                              _bookmarkedMovies[index + 4] =
                                  !_bookmarkedMovies[index + 4];
                            });
                          },
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
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendedMovies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: _recommendedMovies[index]['title']!,
                          imageUrl: _recommendedMovies[index]['image']!,
                          year: _recommendedMovies[index]['year'],
                          genre: _recommendedMovies[index]['genre'],
                          isBookmarked: _bookmarkedMovies[index + 4],
                          onBookmark: () {
                            setState(() {
                              _bookmarkedMovies[index + 4] =
                                  !_bookmarkedMovies[index + 4];
                            });
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
