// Component thẻ (Chip) hiển thị tên danh mục, có trạng thái chọn.
import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.icon,
  });

  // Xây dựng giao diện Chip với màu sắc thay đổi theo trạng thái chọn.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF5BA3F5)
            : (isDark ? const Color(0xFF1A2332) : const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isSelected || !isDark ? Colors.white : Colors.black,
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected || isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
