import 'package:flutter/material.dart';

import '../Components/bookmark_card.dart';
import '../Components/bottom_navbar.dart';
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

  final List<Map<String, String>> _bookmarkedMovies = [
    {
      'title': 'Spider-Man: No Way Home',
      'year': '2021',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/spiderman/200/300',
    },
    {
      'title': 'Dune: Part Two',
      'year': '2024',
      'genre': 'Khoa học viễn tưởng',
      'image': 'https://picsum.photos/seed/dune2/200/300',
    },
    {
      'title': 'The Creator',
      'year': '2023',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/creator/200/300',
    },
    {
      'title': 'Oppenheimer',
      'year': '2023',
      'genre': 'Tiểu sử',
      'image': 'https://picsum.photos/seed/oppenheimer/200/300',
    },
  ];

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      // Quay về trang chủ
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      // Chuyển đến tab khác
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
              Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
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
                      onPressed: () {
                        setState(() {
                          _isGridView = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.list,
                        color: !_isGridView
                            ? const Color(0xFF5BA3F5)
                            : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isGridView = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bookmarked Movies Grid/List
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
                      return BookmarkCard(
                        title: _bookmarkedMovies[index]['title']!,
                        year: _bookmarkedMovies[index]['year']!,
                        genre: _bookmarkedMovies[index]['genre']!,
                        imageUrl: _bookmarkedMovies[index]['image']!,
                        onDelete: () {
                          setState(() {
                            _bookmarkedMovies.removeAt(index);
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
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _bookmarkedMovies.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          height: 140,
                          child: BookmarkCard(
                            title: _bookmarkedMovies[index]['title']!,
                            year: _bookmarkedMovies[index]['year']!,
                            genre: _bookmarkedMovies[index]['genre']!,
                            imageUrl: _bookmarkedMovies[index]['image']!,
                            onDelete: () {
                              setState(() {
                                _bookmarkedMovies.removeAt(index);
                              });
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MovieDetailScreen(),
                                ),
                              );
                            },
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
