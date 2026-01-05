import 'package:flutter/material.dart';

/// Model cho một server với danh sách tập
class ServerData {
  final String name;
  final List<EpisodeData> episodes;

  const ServerData({required this.name, required this.episodes});
}

/// Model cho một tập phim
class EpisodeData {
  final String name;
  final String? slug;
  final bool isWatched;
  final String linkEmbed;
  final String linkM3u8;

  const EpisodeData({
    required this.name,
    this.slug,
    this.isWatched = false,
    this.linkEmbed = '',
    this.linkM3u8 = '',
  });
}

/// Widget hiển thị danh sách server và tập phim
class EpisodeServerList extends StatefulWidget {
  final List<ServerData> servers;
  final int? currentEpisodeIndex;
  final int? currentServerIndex;
  final Function(int serverIndex, int episodeIndex)? onEpisodeTap;
  final Color primaryColor;

  const EpisodeServerList({
    super.key,
    required this.servers,
    this.currentEpisodeIndex,
    this.currentServerIndex,
    this.onEpisodeTap,
    this.primaryColor = const Color(0xFF5BA3F5),
  });

  @override
  State<EpisodeServerList> createState() => _EpisodeServerListState();
}

class _EpisodeServerListState extends State<EpisodeServerList> {
  int _selectedServerIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedServerIndex = widget.currentServerIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.servers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh sách tập',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2332) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 48,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có danh sách tập',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Danh sách tập',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Server Tabs
        if (widget.servers.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.servers.asMap().entries.map((entry) {
                final index = entry.key;
                final server = entry.value;
                final isSelected = index == _selectedServerIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedServerIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.primaryColor
                            : (isDark
                                  ? const Color(0xFF1A2332)
                                  : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                      ),
                      child: Text(
                        server.name,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Episode Grid
        _buildEpisodeGrid(isDark),
      ],
    );
  }

  Widget _buildEpisodeGrid(bool isDark) {
    final episodes = widget.servers[_selectedServerIndex].episodes;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: episodes.asMap().entries.map((entry) {
        final index = entry.key;
        final episode = entry.value;
        final isCurrentEpisode =
            widget.currentServerIndex == _selectedServerIndex &&
            widget.currentEpisodeIndex == index;

        return GestureDetector(
          onTap: () => widget.onEpisodeTap?.call(_selectedServerIndex, index),
          child: Container(
            constraints: const BoxConstraints(minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isCurrentEpisode
                  ? LinearGradient(
                      colors: [
                        widget.primaryColor,
                        widget.primaryColor.withOpacity(0.8),
                      ],
                    )
                  : null,
              color: isCurrentEpisode
                  ? null
                  : (isDark ? const Color(0xFF1A2332) : Colors.grey[200]),
              borderRadius: BorderRadius.circular(8),
              border: isCurrentEpisode
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.3),
                    ),
              boxShadow: isCurrentEpisode
                  ? [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (episode.isWatched && !isCurrentEpisode) ...[
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: isDark ? Colors.green[400] : Colors.green,
                  ),
                  const SizedBox(width: 6),
                ],
                if (isCurrentEpisode) ...[
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  episode.name,
                  style: TextStyle(
                    color: isCurrentEpisode
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontSize: 13,
                    fontWeight: isCurrentEpisode
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
