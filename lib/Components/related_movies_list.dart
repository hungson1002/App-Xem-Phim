// Component danh sách phim liên quan (Recommend), hiển thị trong chi tiết xem phim.
import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import 'cached_image_widget.dart';

class RelatedMoviesList extends StatefulWidget {
  final String categorySlug;
  final String currentMovieId;
  final Function(String slug) onMovieTap;

  const RelatedMoviesList({
    super.key,
    required this.categorySlug,
    required this.currentMovieId,
    required this.onMovieTap,
  });

  @override
  State<RelatedMoviesList> createState() => _RelatedMoviesListState();
}

class _RelatedMoviesListState extends State<RelatedMoviesList> {
  final MovieService _movieService = MovieService();
  List<Movie> _movies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRelatedMovies();
  }

  @override
  void didUpdateWidget(RelatedMoviesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categorySlug != widget.categorySlug) {
      _fetchRelatedMovies();
    }
  }

  Future<void> _fetchRelatedMovies() async {
    if (widget.categorySlug.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    final movies = await _movieService.getMoviesByCategory(
      widget.categorySlug,
      limit: 10,
    );

    if (mounted) {
      setState(() {
        _movies = movies.where((m) => m.slug != widget.currentMovieId).toList();
        _isLoading = false;
      });
    }
  }

  // Xây dựng danh sách phim liên quan (cuộn ngang).
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Có thể bạn thích',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _movies.length,
            itemBuilder: (context, index) {
              final movie = _movies[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => widget.onMovieTap(movie.slug),
                  child: SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedImageWidget(
                          imageUrl: movie.posterUrl,
                          width: 130,
                          height: 160,
                          borderRadius: BorderRadius.circular(8),
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
