// Component hiển thị thông tin phim (tên, server, tập) trong phòng xem chung.
import 'package:flutter/material.dart';

class WatchRoomInfo extends StatelessWidget {
  final String movieName;
  final String? serverName;
  final String? episodeName;

  const WatchRoomInfo({
    super.key,
    required this.movieName,
    this.serverName,
    this.episodeName,
  });

  // Hiển thị tên phim và thông tin tập/server hiện tại.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movieName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (serverName != null && episodeName != null)
            Text(
              '$serverName - $episodeName',
              style: const TextStyle(color: Color(0xFF5BA3F5), fontSize: 15),
            ),
        ],
      ),
    );
  }
}
