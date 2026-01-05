// Component thanh tiêu đề màn hình chính (Home App Bar), chứa logo và nút tìm kiếm/profile.
import 'package:flutter/material.dart';

import '../Views/profile_screen.dart';
import '../Views/search_screen.dart';
import '../models/user_model.dart';
import '../utils.dart';

class HomeAppBar extends StatelessWidget {
  final User? user;

  const HomeAppBar({super.key, required this.user});

  // Xây dựng SliverAppBar với hiệu ứng cuộn, logo gradient và các action.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      elevation: 0,
      floating: true,
      pinned: true,
      leadingWidth: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 233, 11, 30),
                  Color.fromARGB(255, 240, 226, 16),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5E1A).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'CHILL PHIM',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF5BA3F5),
              backgroundImage: user?.avatar != null
                  ? Utils.getImageProvider(user!.avatar)
                  : null,
              child: user?.avatar == null || user!.avatar!.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
