// Component hiển thị thông tin tiêu đề, năm sản xuất, thời lượng và chất lượng phim.
import 'package:flutter/material.dart';

class MovieInfoHeader extends StatelessWidget {
  final String movieName;
  final String originName;
  final int year;
  final String time;
  final String quality;
  final bool isDark;

  const MovieInfoHeader({
    super.key,
    required this.movieName,
    required this.originName,
    required this.year,
    required this.time,
    required this.quality,
    required this.isDark,
  });

  // Hiển thị tên phim, tên gốc và các thông tin metadata.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        Row(
          children: [
            Text(
              year > 0 ? year.toString() : '',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2332) : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hd, color: Color(0xFF5BA3F5), size: 16),
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
      ],
    );
  }
}
