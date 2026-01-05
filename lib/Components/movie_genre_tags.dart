// Component hiển thị các tag thể loại phim và rating.
import 'package:flutter/material.dart';

class MovieGenreTags extends StatelessWidget {
  final List<String> genres;
  final double? rating;
  final Color primaryColor;

  const MovieGenreTags({
    super.key,
    required this.genres,
    this.rating,
    this.primaryColor = const Color(0xFF5BA3F5),
  });

  // Xây dựng danh sách tag (Chip) và Badge rating nếu có.
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...genres.asMap().entries.map((entry) {
          final index = entry.key;
          final genre = entry.value;
          return _buildGenreChip(
            genre.toUpperCase(),
            index == 0 ? primaryColor : const Color(0xFF1A2332),
          );
        }),

        if (rating != null) _buildRatingBadge(rating!),
      ],
    );
  }

  Widget _buildGenreChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: color == primaryColor
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.black87, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
