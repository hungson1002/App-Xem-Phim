import 'package:flutter/material.dart';

class GenreChipsSection extends StatelessWidget {
  final List<String> categories;
  final List<String> countries;

  const GenreChipsSection({
    super.key,
    required this.categories,
    required this.countries,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTags = [...categories, ...countries];

    if (allTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thể loại',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allTags.map((tag) => _buildChip(context, tag, isDark)).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF5BA3F5).withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
