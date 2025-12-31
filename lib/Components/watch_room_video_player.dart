import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_room_provider.dart';
import '../services/auth_service.dart';
import 'fijk_video_player.dart';

class WatchRoomVideoPlayer extends StatefulWidget {
  const WatchRoomVideoPlayer({super.key});

  @override
  State<WatchRoomVideoPlayer> createState() => _WatchRoomVideoPlayerState();
}

class _WatchRoomVideoPlayerState extends State<WatchRoomVideoPlayer> {
  final AuthService _authService = AuthService();
  String? _currentUserId;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getUser();
    setState(() {
      _currentUserId = user?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchRoomProvider>(
      builder: (context, provider, child) {
        final room = provider.currentRoom;
        if (room == null) {
          return const Center(child: Text('Không có phòng'));
        }

        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Video placeholder (replace with actual video player)
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[900],
                    child: _buildVideoContent(provider, room),
                  ),
                ),
              ),

              // Video controls overlay
              if (_showControls)
                Positioned.fill(child: _buildVideoControls(provider)),

              // Sync indicator
              if (provider.isSyncing)
                const Positioned(
                  top: 16,
                  right: 16,
                  child: Card(
                    color: Colors.black54,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đang đồng bộ...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoControls(WatchRoomProvider provider) {
    final canControl =
        _currentUserId != null && provider.canControlVideo(_currentUserId!);

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black26,
        child: Column(
          children: [
            const Spacer(),

            // Play/Pause button
            Center(
              child: IconButton(
                iconSize: 64,
                icon: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: canControl
                    ? () {
                        if (provider.isPlaying) {
                          provider.pauseVideo();
                        } else {
                          provider.playVideo();
                        }
                      }
                    : null,
              ),
            ),

            const Spacer(),

            // Progress bar and controls
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bar
                  Row(
                    children: [
                      Text(
                        _formatTime(provider.currentTime),
                        style: const TextStyle(color: Colors.white),
                      ),

                      Expanded(
                        child: Slider(
                          value: provider.currentTime,
                          max: 3600, // 1 hour max for demo
                          onChanged: canControl
                              ? (value) {
                                  provider.updateCurrentTime(value);
                                }
                              : null,
                          onChangeEnd: canControl
                              ? (value) {
                                  provider.seekVideo(value);
                                }
                              : null,
                          activeColor: Colors.red,
                          inactiveColor: Colors.white30,
                        ),
                      ),

                      const Text(
                        '1:00:00', // Demo duration
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                            ),
                            onPressed: canControl
                                ? () {
                                    final newTime = (provider.currentTime - 10)
                                        .clamp(0.0, 3600.0);
                                    provider.seekVideo(newTime);
                                  }
                                : null,
                          ),

                          IconButton(
                            icon: Icon(
                              provider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: canControl
                                ? () {
                                    if (provider.isPlaying) {
                                      provider.pauseVideo();
                                    } else {
                                      provider.playVideo();
                                    }
                                  }
                                : null,
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                            ),
                            onPressed: canControl
                                ? () {
                                    final newTime = (provider.currentTime + 10)
                                        .clamp(0.0, 3600.0);
                                    provider.seekVideo(newTime);
                                  }
                                : null,
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sync, color: Colors.white),
                            onPressed: provider.requestSync,
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // Volume control
                            },
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // Fullscreen toggle
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Control permission indicator
                  if (!canControl)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Chỉ host mới có thể điều khiển video',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent(WatchRoomProvider provider, room) {
    final episodeInfo = room?.episodeInfo;

    print('🎬 Building video content');
    print('🏠 Room: $room');
    print('📺 Episode info: $episodeInfo');
    print('📺 Episode linkM3u8: ${episodeInfo?.linkM3u8}');
    print('📺 Episode linkEmbed: ${episodeInfo?.linkEmbed}');

    if (episodeInfo != null &&
        (episodeInfo.linkM3u8.isNotEmpty || episodeInfo.linkEmbed.isNotEmpty)) {
      // Có video URL - sử dụng WebView video player
      final videoUrl = episodeInfo.linkEmbed.isNotEmpty
          ? episodeInfo.linkEmbed
          : episodeInfo.linkM3u8;

      print('🎬 Using WebView with URL: $videoUrl');

      // Kiểm tra URL format
      if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
        // Sử dụng Fijk Player cho tất cả video URLs
        return FijkVideoPlayer(
          videoUrl: videoUrl,
          isPlaying: provider.isPlaying,
          currentTime: provider.currentTime,
          onPlayPause: (isPlaying) {
            if (isPlaying) {
              provider.playVideo();
            } else {
              provider.pauseVideo();
            }
          },
          onSeek: (time) {
            provider.seekVideo(time);
          },
        );
      } else {
        // URL không hợp lệ
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'URL video không hợp lệ',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'URL: $videoUrl',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }
    } else {
      // Không có video URL - hiển thị placeholder
      print('❌ No video URL found');
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.isPlaying ? Icons.play_circle : Icons.pause_circle,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            room.movieInfo?.name ?? 'Video Player',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTime(provider.currentTime),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có video URL',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      );
    }
  }

  String _formatTime(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
