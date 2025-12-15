import 'package:flutter/material.dart';

import '../Components/bottom_navbar.dart';
import '../Components/movie_card.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 1;

  final List<Map<String, String>> _searchResults = [
    {
      'title': 'Avengers: Endgame',
      'year': '2019',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/avengers1/200/300',
    },
    {
      'title': 'Avengers: Infinity War',
      'year': '2018',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/avengers2/200/300',
    },
    {
      'title': 'The Avengers',
      'year': '2012',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/avengers3/200/300',
    },
    {
      'title': 'Avengers: Age of Ultron',
      'year': '2015',
      'genre': 'Hành động',
      'image': 'https://picsum.photos/seed/avengers4/200/300',
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
        case 2:
          destination = const BookmarkScreen();
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
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2332) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark ? Colors.grey : Colors.black54,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tìm phim, diễn viên, đạo diễn...',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey : Colors.black45,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.mic,
                            color: isDark ? Colors.grey : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Category Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('Tất cả', true),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Hành động', false),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Tình cảm', false),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Kinh dị', false),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search Suggestions Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                'Gợi ý tìm kiếm',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Suggestion Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('🔥 Top Gun: Maverick'),
                  _buildSuggestionChip('Avatar 2'),
                  _buildSuggestionChip('Spider-Man'),
                  _buildSuggestionChip('Phim Hàn Quốc mới'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search History Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lịch sử',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Xoá tất cả',
                      style: TextStyle(color: Color(0xFF5BA3F5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // History Items
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildHistoryItem('Avengers: Endgame'),
                  _buildHistoryItem('Phim hài tết 2024'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Results Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kết quả hàng đầu',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Xem thêm',
                      style: TextStyle(color: Color(0xFF5BA3F5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search Results Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return MovieCard(
                    title: _searchResults[index]['title']!,
                    imageUrl: _searchResults[index]['image']!,
                    year: _searchResults[index]['year'],
                    genre: _searchResults[index]['genre'],
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

  Widget _buildCategoryChip(String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF5BA3F5)
            : (isDark ? const Color(0xFF1A2332) : const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected || isDark ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.history,
        color: isDark ? Colors.grey : Colors.black45,
        size: 20,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.close,
        color: isDark ? Colors.grey : Colors.black45,
        size: 20,
      ),
      onTap: () {},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
