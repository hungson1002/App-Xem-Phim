import 'package:flutter/material.dart';
import '../models/movie_detail_model.dart';

import '../Components/video_player/custom_video_player.dart';
import '../Components/episode_server_list.dart';
import '../Components/comment_section.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MovieDetail movieDetail;
  final int initialServerIndex;
  final int initialEpisodeIndex;

  const VideoPlayerScreen({
    super.key,
    required this.movieDetail,
    this.initialServerIndex = 0,
    this.initialEpisodeIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _currentServerIndex;
  late int _currentEpisodeIndex;
  late List<ServerData> _servers;

  @override
  void initState() {
    super.initState();
    _currentServerIndex = widget.initialServerIndex;
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _convertEpisodes();
  }

  void _convertEpisodes() {
    _servers = widget.movieDetail.episodes
        .map(
          (server) => ServerData(
            name: server.serverName,
            episodes: server.episodes
                .map(
                  (ep) => EpisodeData(
                    name: ep.name,
                    slug: ep.slug,
                    linkEmbed: ep.linkEmbed,
                    linkM3u8: ep.linkM3u8,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get current episode URL
    // Priority: m3u8 > embed
    // However, m3u8 needs referer or valid token sometimes.
    // Let's assume m3u8 works directly or handled by player.

    // We need to fetch the actual link from ServerData/EpisodeData
    // But wait, ServerData in EpisodeServerList is a UI model.
    // We should use the raw data from MovieDetail to get the link.

    final currentServer = widget.movieDetail.episodes[_currentServerIndex];
    final currentEpisode = currentServer.episodes[_currentEpisodeIndex];

    // Prefer m3u8 for native player
    String videoUrl = currentEpisode.linkM3u8;
    if (videoUrl.isEmpty) {
      videoUrl = currentEpisode.linkEmbed;
    }

    // Auto proxy HLS if needed (optional, but good if domain is blocked)
    // But video player might handle redirects.

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Area (Fixed aspect ratio)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  CustomVideoPlayer(
                    key: ValueKey(
                      '${_currentServerIndex}_$_currentEpisodeIndex',
                    ), // Reset player on change
                    videoUrl: videoUrl,
                    autoPlay: true,
                  ),
                  // Back button overlay
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info and List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movieDetail.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentServer.serverName} - ${currentEpisode.name}',
                            style: const TextStyle(
                              color: Color(0xFF5BA3F5),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.grey, height: 1),

                    // Episode List
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: EpisodeServerList(
                        servers: _servers,
                        currentServerIndex: _currentServerIndex,
                        currentEpisodeIndex: _currentEpisodeIndex,
                        onEpisodeTap: (serverIdx, episodeIdx) {
                          setState(() {
                            _currentServerIndex = serverIdx;
                            _currentEpisodeIndex = episodeIdx;
                          });
                        },
                      ),
                    ),

                    const Divider(color: Colors.grey, height: 1),

                    // Comment Section
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CommentSection(movieId: widget.movieDetail.slug),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
