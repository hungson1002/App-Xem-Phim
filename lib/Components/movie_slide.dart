// Component slide phim (Banner), tự động cuộn và có hiệu ứng zoom.
import 'dart:async';

import 'package:flutter/material.dart';
import 'cached_image_widget.dart';

class MovieSlide extends StatefulWidget {
  final List<Map<String, String>> movies;
  final Function(int)? onMovieTap;
  final Function(int)? onBookmark;
  final List<bool>? bookmarkedStates;

  const MovieSlide({
    super.key,
    required this.movies,
    this.onMovieTap,
    this.onBookmark,
    this.bookmarkedStates,
  });

  @override
  State<MovieSlide> createState() => _MovieSlideState();
}

class _MovieSlideState extends State<MovieSlide> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && widget.movies.isNotEmpty) {
        int nextPage = (_currentPage + 1) % widget.movies.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Xây dựng Slide Banner với hiệu ứng scale và opacity cho item không active.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.movies.length,
            itemBuilder: (context, index) {
              final isActive = _currentPage == index;
              final movie = widget.movies[index];

              return AnimatedScale(
                scale: isActive ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 300),
                child: AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: () => widget.onMovieTap?.call(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedImageWidget(
                            imageUrl: movie['image'] ?? '',
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(20),
                          ),

                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.95),
                                ],
                                stops: const [0.0, 0.4, 0.7, 1.0],
                              ),
                            ),
                          ),

                          Positioned(
                            top: 14,
                            left: 14,
                            right: 14,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (movie['rating'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.black87,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          movie['rating']!,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const SizedBox(),

                                GestureDetector(
                                  onTap: () => widget.onBookmark?.call(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      (widget.bookmarkedStates?[index] ?? false)
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color:
                                          (widget.bookmarkedStates?[index] ??
                                              false)
                                          ? Colors.amber
                                          : Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (movie['year'] != null)
                                      _buildTag(movie['year']!),
                                    if (movie['genre'] != null)
                                      _buildTag(movie['genre']!),
                                    if (movie['quality'] != null)
                                      _buildTag(
                                        movie['quality']!,
                                        highlight: true,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        widget.onMovieTap?.call(index),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 22,
                                    ),
                                    label: const Text(
                                      'Xem ngay',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.movies.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? const Color(0xFF6C63FF)
                    : Colors.grey[700],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF6C63FF).withOpacity(0.9)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: highlight ? null : Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
