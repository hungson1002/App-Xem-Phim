import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import 'movie_card.dart';

class SearchResultsGrid extends StatelessWidget {
  final List<Movie> movies;
  final bool isLoading;
  final Function(Movie) onMovieTap;
  final Function(Movie)? onBookmark;
  final bool Function(Movie)? isBookmarked;
  final String emptyMessage;
  final ScrollController? scrollController;

  const SearchResultsGrid({
    super.key,
    required this.movies,
    required this.isLoading,
    required this.onMovieTap,
    this.onBookmark,
    this.isBookmarked,
    this.emptyMessage = 'Không tìm thấy phim nào',
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        final isSaved = isBookmarked?.call(movie) ?? false;

        return MovieCard(
          title: movie.name,
          imageUrl: movie.posterUrl,
          year: movie.year.toString(),
          genre: 'Phim',
          isBookmarked: isSaved,
          onBookmark: onBookmark != null ? () => onBookmark!(movie) : null,
          onTap: () => onMovieTap(movie),
        );
      },
    );
  }
}
