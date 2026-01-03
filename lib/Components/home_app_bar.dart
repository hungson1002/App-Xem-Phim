import 'package:flutter/material.dart';

import '../Views/profile_screen.dart';
import '../Views/search_screen.dart';
import '../Views/watchrooms_list_screen.dart';
import '../models/user_model.dart';
import '../utils.dart';

class HomeAppBar extends StatelessWidget {
  final User? user;

  const HomeAppBar({super.key, required this.user});

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
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 233, 11, 30),
                Color.fromARGB(255, 240, 226, 16),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        ),
      ),
      title: Text(
        'CHILL PHIM',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
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
        IconButton(
          icon: Icon(Icons.people, color: isDark ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WatchRoomsScreen()),
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
