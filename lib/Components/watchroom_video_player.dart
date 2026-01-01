import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_room_provider.dart';
import '../services/auth_service.dart';
import 'simple_video_player.dart';

class WatchRoomVideoPlayer extends StatefulWidget {
  const WatchRoomVideoPlayer({super.key});

  @override
  State<WatchRoomVideoPlayer> createState() => _WatchRoomVideoPlayerState();
}

class _WatchRoomVideoPlayerState extends State<WatchRoomVideoPlayer> {
  final AuthService _authService = AuthService();
  String? _currentUserId;

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
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[900],
                    child: _buildVideoContent(provider, room),
                  ),
                ),
              ),

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

  Widget _buildVideoContent(WatchRoomProvider provider, room) {
    final episodeInfo = room?.episodeInfo;
    if (episodeInfo != null &&
        (episodeInfo.linkM3u8.isNotEmpty || episodeInfo.linkEmbed.isNotEmpty)) {
      final videoUrl = episodeInfo.linkM3u8.isNotEmpty
          ? episodeInfo.linkM3u8
          : episodeInfo.linkEmbed;

      if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
        final isHost = _currentUserId != null && provider.isHost(_currentUserId!);
        
        return SimpleVideoPlayer(
          key: ValueKey(videoUrl),
          videoUrl: videoUrl,
          isPlaying: provider.isPlaying,
          currentTime: provider.currentTime,
          enableControls: true, // Always show controls
          isHost: isHost, // Pass host status to player
          onPlayPause: (isPlaying) {
            if (isHost) {
              if (isPlaying) {
                provider.playVideo();
              } else {
                provider.pauseVideo();
              }
            }
          },
          onSeek: (time) {
            if (isHost) {
              provider.seekVideo(time);
            }
          },
        );
      } else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'URL video không hợp lệ',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        );
      }
    } else {
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
            room?.movieInfo?.name ?? 'Video Player',
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
