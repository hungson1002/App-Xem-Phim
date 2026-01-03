import 'package:flutter/material.dart';

import '../Views/movie_detail_screen.dart';
import '../models/movie_model.dart';
import '../services/saved_movie_service.dart';
import 'app_snackbar.dart';
import 'movie_card.dart';

class MovieSection extends StatefulWidget {
  final String title;
  final List<Movie> movies;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final IconData? titleIcon;
  final Set<String>? savedMovieSlugs;
  final VoidCallback? onBookmarkChanged;

  const MovieSection({
    super.key,
    required this.title,
    required this.movies,
    required this.isLoading,
    this.onSeeAll,
    this.titleIcon,
    this.savedMovieSlugs,
    this.onBookmarkChanged,
  });

  @override
  State<MovieSection> createState() => _MovieSectionState();
}

class _MovieSectionState extends State<MovieSection> {
  final SavedMovieService _savedMovieService = SavedMovieService();
  Set<String> _localSavedSlugs = {};

  @override
  void initState() {
    super.initState();
    _localSavedSlugs = Set.from(widget.savedMovieSlugs ?? {});
  }

  @override
  void didUpdateWidget(MovieSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.savedMovieSlugs != oldWidget.savedMovieSlugs) {
      _localSavedSlugs = Set.from(widget.savedMovieSlugs ?? {});
    }
  }

  Future<void> _toggleBookmark(Movie movie) async {
    final slug = movie.slug;
    final wasSaved = _localSavedSlugs.contains(slug);

    final result = await _savedMovieService.toggleBookmark(slug);

    if (result['success'] == true && mounted) {
      setState(() {
        if (wasSaved) {
          _localSavedSlugs.remove(slug);
        } else {
          _localSavedSlugs.add(slug);
        }
      });

      // Thông báo cho parent widget biết bookmark đã thay đổi
      widget.onBookmarkChanged?.call();

      if (wasSaved) {
        AppSnackBar.showWarning(context, 'Đã xóa khỏi danh sách');
      } else {
        AppSnackBar.showSuccess(context, 'Đã lưu phim');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.titleIcon != null) ...[
                    Icon(
                      widget.titleIcon,
                      color: const Color(0xFF5BA3F5),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.onSeeAll != null)
                TextButton(
                  onPressed: widget.onSeeAll,
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
        SizedBox(
          height: 250,
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.movies.length,
                  itemBuilder: (context, index) {
                    final movie = widget.movies[index];
                    final isBookmarked = _localSavedSlugs.contains(movie.slug);
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: MovieCard(
                          title: movie.name,
                          imageUrl: movie.posterUrl.isNotEmpty
                              ? movie.posterUrl
                              : 'https://picsum.photos/200/300',
                          year: movie.year.toString(),
                          genre: movie.type,
                          isBookmarked: isBookmarked,
                          onBookmark: () => _toggleBookmark(movie),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MovieDetailScreen(slug: movie.slug),
                              ),
                            ).then((_) {
                              // Khi quay lại từ detail screen, thông báo để refresh
                              widget.onBookmarkChanged?.call();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
