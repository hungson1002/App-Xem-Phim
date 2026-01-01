import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import 'movie_card.dart';
import '../Views/movie_detail_screen.dart';

class SearchResultsGrid extends StatelessWidget {
  final List<Movie> movies;

  const SearchResultsGrid({super.key, required this.movies});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(
          title: movie.name,
          imageUrl: movie.posterUrl,
          year: movie.year.toString(),
          genre: movie.category.isNotEmpty ? movie.category.first : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailScreen(slug: movie.slug),
              ),
            );
          },
        );
      },
    );
  }
}
