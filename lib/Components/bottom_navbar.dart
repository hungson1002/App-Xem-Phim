// Component thanh điều hướng dưới cùng (Bottom Navigation Bar).
import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Xây dựng giao diện thanh điều hướng với 5 tab chính.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5BA3F5),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Đã lưu'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Xem chung'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
