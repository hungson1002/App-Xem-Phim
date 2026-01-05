import 'package:flutter/material.dart';

import '../Components/cast_list.dart';
import '../Components/comment_section.dart';
import '../Components/custom_button.dart';
import '../Components/episode_server_list.dart';
import '../Components/movie_genre_tags.dart';
import '../Components/cached_image_widget.dart';
import '../Components/related_movies_list.dart';
import '../models/movie_detail_model.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_service.dart';
import '../utils/app_snackbar.dart';
import 'video_player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId; // This should be slug
  final Movie? movie;

  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isSaved = false;
  bool _isSaveLoading = false;
  final SavedMovieService _savedMovieService = SavedMovieService();
  bool _isLoading = true;
  String? _errorMessage;

  final MovieService _movieService = MovieService();

  MovieDetail? _movieDetail;
  List<CastMember> _cast = [];
  List<ServerData> _servers = [];
  int _currentServerIndex = 0;
  int _currentEpisodeIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkSaveStatus();
  }

  Future<void> _checkSaveStatus() async {
    final isSaved = await _savedMovieService.isMovieSaved(widget.movieId);
    if (mounted) {
      setState(() => _isSaved = isSaved);
    }
    _loadMovieDetail();
  }

  Future<void> _loadMovieDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Use slug from movieId or from movie object
    final slug = widget.movie?.slug ?? widget.movieId;
    final movieDetail = await _movieService.getMovieDetailFull(slug);

    if (mounted) {
      if (movieDetail != null) {
        setState(() {
          _movieDetail = movieDetail;
          _isLoading = false;

          // Convert actors to CastMember
          _cast = movieDetail.actors
              .map((name) => CastMember(name: name))
              .toList();

          // Convert episodes to ServerData
          _servers = movieDetail.episodes
              .map(
                (server) => ServerData(
                  name: server.serverName,
                  episodes: server.episodes
                      .map((ep) => EpisodeData(name: ep.name, slug: ep.slug))
                      .toList(),
                ),
              )
              .toList();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải thông tin phim';
        });
      }
    }
  }

  Future<void> _toggleSaveMovie() async {
    if (_isSaveLoading) return;

    setState(() => _isSaveLoading = true);

    try {
      if (_isSaved) {
        // Remove from saved list
        final response = await _savedMovieService.removeSavedMovie(
          widget.movieId,
        );
        if (response.success && mounted) {
          setState(() => _isSaved = false);
          AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
        } else if (mounted) {
          AppSnackBar.showError(
            context,
            response.message ?? 'Không thể xóa phim',
          );
        }
      } else {
        // Save movie using movieId (slug)
        final response = await _savedMovieService.saveMovie(widget.movieId);
        if (response.success && mounted) {
          setState(() => _isSaved = true);
          AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
        } else if (mounted) {
          AppSnackBar.showError(
            context,
            response.message ?? 'Không thể lưu phim',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Có lỗi xảy ra');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaveLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading indicator
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0B0E13)
            : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0B0E13)
            : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMovieDetail,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Use _movieDetail data or fallback to widget.movie
    final posterUrl = _movieDetail?.posterUrl ?? widget.movie?.posterUrl ?? '';
    final movieName = _movieDetail?.name ?? widget.movie?.name ?? 'Tên phim';
    final originName =
        _movieDetail?.originName ?? widget.movie?.originName ?? '';
    final year = _movieDetail?.year ?? widget.movie?.year ?? 0;
    final time = _movieDetail?.time ?? widget.movie?.time ?? '';
    final quality = _movieDetail?.quality ?? widget.movie?.quality ?? 'HD';

    // Extract category names for display
    final categoryNames =
        _movieDetail?.category.map((c) => c.name).toList() ??
        widget.movie?.category ??
        [];

    // Extract first category slug for related movies
    final firstCategorySlug = _movieDetail?.category.isNotEmpty == true
        ? _movieDetail!.category.first.slug
        : '';

    final content =
        _movieDetail?.content ?? widget.movie?.content ?? 'Chưa có mô tả.';

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
                child: _isSaveLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSaved
                              ? const Color(0xFF5BA3F5)
                              : Colors.white,
                        ),
                        onPressed: _toggleSaveMovie,
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
                  CachedImageWidget(
                    imageUrl: posterUrl.isNotEmpty
                        ? posterUrl
                        : 'https://via.placeholder.com/400x600',
                    fit: BoxFit.cover,
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
                  MovieGenreTags(
                    genres: categoryNames.isNotEmpty ? categoryNames : ['Phim'],
                    rating: 8.5,
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    movieName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (originName.isNotEmpty)
                    Text(
                      originName,
                      style: const TextStyle(
                        color: Color(0xFF5BA3F5),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Year, Duration, Quality
                  Row(
                    children: [
                      Text(
                        year > 0 ? year.toString() : '',
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
                        time,
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
                              quality,
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
                          onPressed: () {
                            if (_servers.isNotEmpty &&
                                _servers[0].episodes.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(
                                    movieDetail: _movieDetail!,
                                    initialServerIndex: 0,
                                    initialEpisodeIndex: 0,
                                  ),
                                ),
                              );
                            } else {
                              AppSnackBar.showError(
                                context,
                                'Chưa có tập phim nào',
                              );
                            }
                          },
                          backgroundColor: const Color(0xFF5BA3F5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save to list button
                      GestureDetector(
                        onTap: _isSaveLoading ? null : _toggleSaveMovie,
                        child: Container(
                          width: 80,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _isSaved
                                ? const Color(0xFF5BA3F5).withOpacity(0.2)
                                : (isDark
                                      ? const Color(0xFF1A2332)
                                      : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(12),
                            border: _isSaved
                                ? Border.all(
                                    color: const Color(0xFF5BA3F5),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: _isSaveLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF5BA3F5),
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSaved ? Icons.check : Icons.add,
                                      color: _isSaved
                                          ? const Color(0xFF5BA3F5)
                                          : (isDark
                                                ? Colors.white
                                                : Colors.black),
                                      size: 24,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isSaved ? 'Đã lưu' : 'Lưu',
                                      style: TextStyle(
                                        color: _isSaved
                                            ? const Color(0xFF5BA3F5)
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                        fontSize: 10,
                                        fontWeight: _isSaved
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
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
                    content,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Episode/Server List
                  EpisodeServerList(
                    servers: _servers,
                    currentServerIndex: _currentServerIndex,
                    currentEpisodeIndex: _currentEpisodeIndex,
                    onEpisodeTap: (serverIndex, episodeIndex) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(
                            movieDetail: _movieDetail!,
                            initialServerIndex: serverIndex,
                            initialEpisodeIndex: episodeIndex,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Cast List
                  CastList(
                    cast: _cast,
                    onSeeAllTap: () {
                      // TODO: Navigate to full cast list
                    },
                  ),

                  const SizedBox(height: 24),

                  // Comments Section
                  CommentSection(movieId: widget.movieId),

                  const SizedBox(height: 24),

                  // Related Movies (Replaced with new component)
                  RelatedMoviesList(
                    categorySlug: firstCategorySlug,
                    currentMovieId: widget.movieId,
                    onMovieTap: (slug) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MovieDetailScreen(movieId: slug),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
