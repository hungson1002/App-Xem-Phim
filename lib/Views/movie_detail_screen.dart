import 'package:flutter/material.dart';

import '../Components/comment_section.dart';
import '../Components/custom_button.dart';
import '../Components/episode_list_section.dart';
import '../Components/genre_chips_section.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final String slug;

  const MovieDetailScreen({super.key, required this.slug});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final MovieService _movieService = MovieService();
  final SavedMovieService _savedMovieService = SavedMovieService();
  Movie? _movie;
  bool _isLoading = true;
  bool _isBookmarked = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMovieDetail();
  }

  Future<void> _loadMovieDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final movie = await _movieService.getMovieDetail(widget.slug);
      final isSaved = await _savedMovieService.isMovieSaved(widget.slug);
      if (mounted) {
        setState(() {
          _movie = movie;
          _isBookmarked = isSaved;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0B0E13)
            : const Color(0xFFF5F5F5),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty || _movie == null) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0B0E13)
            : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
        ),
        body: Center(
          child: Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'Không tìm thấy phim',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Movie Poster with Play Button
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF0B0E13)
                : const Color(0xFFF5F5F5),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.favorite : Icons.favorite_border,
                    color: _isBookmarked ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    final wasSaved = _isBookmarked;
                    final result = await _savedMovieService.toggleBookmark(
                      widget.slug,
                    );
                    if (result['success'] == true && mounted) {
                      setState(() => _isBookmarked = !_isBookmarked);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            wasSaved ? 'Đã xóa khỏi danh sách' : 'Đã lưu phim',
                          ),
                          backgroundColor: wasSaved
                              ? Colors.orange
                              : const Color(0xFF5BA3F5),
                        ),
                      );
                    }
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.network(
                    _movie!.posterUrl.isNotEmpty
                        ? _movie!.posterUrl
                        : 'https://picsum.photos/800/1200',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[900]),
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0B0E13).withOpacity(0.7),
                          const Color(0xFF0B0E13),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Movie Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genre Tags and Rating
                  Wrap(
                    // Changed Row to Wrap to handle multiple genres
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._movie!.category
                          .take(2)
                          .map(
                            (cat) =>
                                _buildGenreChip(cat, const Color(0xFF5BA3F5)),
                          ),
                      if (_movie!.type.isNotEmpty)
                        _buildGenreChip(
                          _movie!.type.toUpperCase(),
                          const Color(0xFF1A2332),
                        ),

                      // Rating placeholder (API might not have rating yet)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.black, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'N/A', // Placeholder
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _movie!.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (_movie!.originName.isNotEmpty &&
                      _movie!.originName != _movie!.name)
                    Text(
                      _movie!.originName,
                      style: const TextStyle(
                        color: Color(0xFF5BA3F5),
                        fontSize: 20, // Smaller font for subtitle
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Year, Duration, Quality
                  Row(
                    children: [
                      Text(
                        _movie!.year.toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _movie!.time,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2332)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hd,
                              color: Color(0xFF5BA3F5),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _movie!.quality,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Xem ngay',
                          onPressed: () {},
                          backgroundColor: const Color(0xFF5BA3F5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isBookmarked
                              ? const Color(0xFF5BA3F5)
                              : (isDark
                                    ? const Color(0xFF1A2332)
                                    : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isBookmarked ? Icons.check : Icons.add,
                            color: isDark
                                ? Colors.white
                                : (_isBookmarked ? Colors.white : Colors.black),
                          ),
                          onPressed: () async {
                            final wasSaved = _isBookmarked;
                            final result = await _savedMovieService
                                .toggleBookmark(widget.slug);
                            if (result['success'] == true && mounted) {
                              setState(() => _isBookmarked = !_isBookmarked);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    wasSaved
                                        ? 'Đã xóa khỏi danh sách'
                                        : 'Đã lưu phim',
                                  ),
                                  backgroundColor: wasSaved
                                      ? Colors.orange
                                      : const Color(0xFF5BA3F5),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2332)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Danh sách',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Synopsis
                  Text(
                    'Nội dung',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _movie!
                        .content, // Note: Need to handle HTML tags if content has them.
                    // Current assumption: plain text or simple text. Flutter Text widget doesn't render HTML.
                    // If content has HTML, we might need flutter_html package.
                    // For now, let's assume it's acceptable string.
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  GenreChipsSection(
                    categories: _movie!.category,
                    countries: _movie!.country,
                  ),

                  const SizedBox(height: 24),

                  EpisodeListSection(
                    episodes: _movie!.episodes,
                    type: _movie!.type,
                    quality: _movie!.quality,
                  ),

                  const SizedBox(height: 24),
                  const SizedBox(height: 24),

                  // Comments Section (Using actual movie ID or Slug)
                  CommentSection(
                    movieId: widget.slug,
                  ), // Or pass _movie!.id if available and consistent

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
