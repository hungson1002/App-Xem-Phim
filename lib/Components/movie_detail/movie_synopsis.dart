import 'package:flutter/material.dart';

class MovieSynopsis extends StatelessWidget {
  final String content;
  final bool isDark;

  const MovieSynopsis({super.key, required this.content, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }
}
