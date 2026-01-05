// Modal tạo phòng xem phim, cho phép tìm kiếm và chọn phim.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/movie_service.dart';

class CreateRoomModal extends StatefulWidget {
  final Function(String slug, String name, String? poster) onCreate;

  const CreateRoomModal({super.key, required this.onCreate});

  @override
  State<CreateRoomModal> createState() => _CreateRoomModalState();

  static Future<void> show(
    BuildContext context, {
    required Function(String slug, String name, String? poster) onCreate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateRoomModal(onCreate: onCreate),
    );
  }
}

class _CreateRoomModalState extends State<CreateRoomModal> {
  final TextEditingController _searchController = TextEditingController();
  final MovieService _movieService = MovieService();

  List<dynamic> _allMovies = [];
  List<dynamic> _filteredMovies = [];
  bool _isLoading = true;
  String? _selectedSlug;
  String? _selectedName;
  String? _selectedPoster;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialMovies() async {
    try {
      final movies = await _movieService.getMoviesLimit(50);
      if (mounted) {
        setState(() {
          _allMovies = movies;
          _filteredMovies = List.from(movies);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      if (query.isEmpty) {
        setState(() {
          _filteredMovies = List.from(_allMovies);
        });
        return;
      }

      setState(() => _isLoading = true);
      try {
        final results = await _movieService.searchMovies(query, limit: 30);
        if (mounted) {
          setState(() {
            _filteredMovies = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  // Xây dựng giao diện Modal tìm kiếm phim và nút tạo phòng.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn phim',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tìm phim bạn muốn xem cùng mọi người',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Nhập tên phim...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMovies.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy phim',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = _filteredMovies[index];
                      final isSelected = _selectedSlug == movie.slug;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSlug = movie.slug;
                            _selectedName = movie.name;
                            _selectedPoster = movie.posterUrl;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5BA3F5).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF5BA3F5)
                                  : (isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  movie.posterUrl,
                                  width: 48,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 48,
                                    height: 72,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.movie,
                                      size: 20,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${movie.year} • ${movie.type}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF5BA3F5),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200]!,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedSlug == null
                    ? null
                    : () {
                        widget.onCreate(
                          _selectedSlug!,
                          _selectedName!,
                          _selectedPoster,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BA3F5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[600],
                ),
                child: const Text(
                  'TẠO PHÒNG',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
