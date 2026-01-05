// Component thanh tìm kiếm với nút filter tùy chọn.
import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback? onFilterTap;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.hintText = 'Tìm phim, diễn viên, đạo diễn...',
  });

  // Xây dựng thanh tìm kiếm với icon search, input và nút xóa text.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: isDark ? Colors.grey : Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey : Colors.black45,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.grey : Colors.black54,
                size: 20,
              ),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
          if (onFilterTap != null) ...[
            Container(
              height: 24,
              width: 1,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            IconButton(
              icon: Icon(
                Icons.tune,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: onFilterTap,
            ),
          ],
        ],
      ),
    );
  }
}
