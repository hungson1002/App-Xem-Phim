import 'package:flutter/material.dart';

import '../Views/movie_detail_screen.dart';
import '../main.dart' show routeObserver;
import '../models/movie_model.dart';
import '../services/saved_movie_notifier.dart';
import '../utils/app_snackbar.dart';
import 'movie_card.dart';

class MovieSection extends StatefulWidget {
  final String title;
  final List<Movie> movies;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final IconData? titleIcon;

  const MovieSection({
    super.key,
    required this.title,
    required this.movies,
    required this.isLoading,
    this.onSeeAll,
    this.titleIcon,
  });

  @override
  State<MovieSection> createState() => _MovieSectionState();
}

class _MovieSectionState extends State<MovieSection> with RouteAware {
  Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    // Listen to saved movie changes
    savedMovieNotifier.addListener(_onSavedMoviesChanged);
    // Load saved movies if not loaded yet
    if (!savedMovieNotifier.isLoaded) {
      savedMovieNotifier.loadSavedMovies();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to global route observer
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    savedMovieNotifier.removeListener(_onSavedMoviesChanged);
    super.dispose();
  }

  void _onSavedMoviesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Called when the top route has been popped off, and this route shows up
  @override
  void didPopNext() {
    // Refresh saved movies from server when returning to this screen
    savedMovieNotifier.refresh();
  }

  Future<void> _toggleSaveMovie(Movie movie) async {
    final slug = movie.slug;

    // Set loading state
    setState(() {
      _loadingStates[slug] = true;
    });

    try {
      final isCurrentlySaved = savedMovieNotifier.isMovieSaved(slug);

      if (isCurrentlySaved) {
        final success = await savedMovieNotifier.removeSavedMovie(slug);
        if (success && mounted) {
          AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
        } else if (mounted) {
          AppSnackBar.showError(context, 'Không thể xóa phim');
        }
      } else {
        final success = await savedMovieNotifier.saveMovie(slug);
        if (success && mounted) {
          AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
        } else if (mounted) {
          AppSnackBar.showError(context, 'Không thể lưu phim');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[slug] = false;
        });
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
                    final isSaved = savedMovieNotifier.isMovieSaved(movie.slug);
                    final isLoading = _loadingStates[movie.slug] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: SizedBox(
                        width: 160,
                        child: Stack(
                          children: [
                            MovieCard(
                              title: movie.name,
                              imageUrl: movie.posterUrl.isNotEmpty
                                  ? movie.posterUrl
                                  : 'https://picsum.photos/200/300',
                              year: movie.year.toString(),
                              genre: movie.type,
                              isBookmarked: isSaved,
                              onBookmark: isLoading
                                  ? null
                                  : () => _toggleSaveMovie(movie),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MovieDetailScreen(
                                      movieId: movie.slug,
                                      movie: movie,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Loading overlay for bookmark button
                            if (isLoading)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
