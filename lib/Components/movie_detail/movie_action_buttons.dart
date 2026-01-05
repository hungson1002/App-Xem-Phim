import 'package:flutter/material.dart';
import '../custom_button.dart';

class MovieActionButtons extends StatelessWidget {
  final VoidCallback onWatchPressed;
  final VoidCallback onSavePressed;
  final bool isSaved;
  final bool isSaveLoading;
  final bool isDark;

  const MovieActionButtons({
    super.key,
    required this.onWatchPressed,
    required this.onSavePressed,
    required this.isSaved,
    required this.isSaveLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Xem ngay',
            onPressed: onWatchPressed,
            backgroundColor: const Color(0xFF5BA3F5),
          ),
        ),
        const SizedBox(width: 12),
        // Save to list button
        GestureDetector(
          onTap: isSaveLoading ? null : onSavePressed,
          child: Container(
            width: 80,
            height: 56,
            decoration: BoxDecoration(
              color: isSaved
                  ? const Color(0xFF5BA3F5).withOpacity(0.2)
                  : (isDark ? const Color(0xFF1A2332) : Colors.grey[200]),
              borderRadius: BorderRadius.circular(12),
              border: isSaved
                  ? Border.all(color: const Color(0xFF5BA3F5), width: 1.5)
                  : null,
            ),
            child: isSaveLoading
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
                        isSaved ? Icons.check : Icons.add,
                        color: isSaved
                            ? const Color(0xFF5BA3F5)
                            : (isDark ? Colors.white : Colors.black),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSaved ? 'Đã lưu' : 'Lưu',
                        style: TextStyle(
                          color: isSaved
                              ? const Color(0xFF5BA3F5)
                              : (isDark ? Colors.white : Colors.black),
                          fontSize: 10,
                          fontWeight: isSaved
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
