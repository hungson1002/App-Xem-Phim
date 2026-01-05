// Component hiển thị danh sách tập phim trong phòng xem chung.
import 'package:flutter/material.dart';
import '../../models/movie_detail_model.dart';
import '../../utils/app_snackbar.dart';

class WatchRoomEpisodeList extends StatelessWidget {
  final List<EpisodeInfo> episodes;
  final int currentEpisodeIndex;
  final bool isHost;
  final Function(int) onEpisodeTap;

  const WatchRoomEpisodeList({
    super.key,
    required this.episodes,
    required this.currentEpisodeIndex,
    required this.isHost,
    required this.onEpisodeTap,
  });

  // Xây dựng giao diện danh sách tập, chỉ Host mới có quyền đổi tập.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'Danh sách tập',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (!isHost) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Chỉ host',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(episodes.length, (index) {
              final episode = episodes[index];
              final isSelected = index == currentEpisodeIndex;
              return GestureDetector(
                onTap: () {
                  if (isHost) {
                    onEpisodeTap(index);
                  } else {
                    AppSnackBar.showWarning(
                      context,
                      'Chỉ host mới có thể đổi tập',
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF5BA3F5)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    episode.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
