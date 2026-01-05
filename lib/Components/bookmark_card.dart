// Component thẻ hiển thị phim đã lưu, bao gồm ảnh, rating và nút xóa.
import 'package:flutter/material.dart';
import 'cached_image_widget.dart';

class BookmarkCard extends StatelessWidget {
  final String title;
  final String year;
  final String genre;
  final String imageUrl;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const BookmarkCard({
    super.key,
    required this.title,
    required this.year,
    required this.genre,
    required this.imageUrl,
    required this.onDelete,
    this.onTap,
  });

  // Xây dựng giao diện thẻ bookmark với ảnh bìa, rating và thông tin cơ bản.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Stack(
                  children: [
                    CachedImageWidget(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(12),
                    ),

                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.black, size: 12),
                            SizedBox(width: 4),
                            Text(
                              '8.8',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5BA3F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$year · $genre',
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.black54,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
