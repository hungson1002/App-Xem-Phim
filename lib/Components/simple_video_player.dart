import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class SimpleVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;
  final double currentTime;
  final Function(bool) onPlayPause;
  final Function(double) onSeek;
  final bool enableControls;
  final bool isHost;

  const SimpleVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
    required this.currentTime,
    required this.onPlayPause,
    required this.onSeek,
    this.enableControls = true,
    this.isHost = false,
  });

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _wasPlaying = false; // Track previous playing state
  double _lastReportedPosition =
      0.0; // Track last reported position for seek detection

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _setupVideoPlayerListener() {
    _videoPlayerController.addListener(() {
      if (!mounted) return;

      final isPlaying = _videoPlayerController.value.isPlaying;
      final currentTime = _videoPlayerController.value.position.inSeconds
          .toDouble();

      // Detect play/pause state change
      if (isPlaying != _wasPlaying) {
        _wasPlaying = isPlaying;
        print('🎮 Video player state changed: playing=$isPlaying');

        // Notify parent (only for host)
        if (widget.isHost && widget.onPlayPause != null) {
          widget.onPlayPause!(isPlaying);
        }
      }

      // Detect seek (for host only)
      if (widget.isHost && widget.onSeek != null) {
        // Detect significant position jumps (seek events from scrubbing or skip buttons)
        // Check if position jumped more than 1.5 seconds from last known position
        final timeDiff = (currentTime - _lastReportedPosition).abs();

        if (timeDiff > 1.5) {
          print(
            '🎯 Seek detected: $_lastReportedPosition → $currentTime (diff: ${timeDiff.toStringAsFixed(1)}s)',
          );
          widget.onSeek!(currentTime);
        }
      }

      // Always update last reported position
      _lastReportedPosition = currentTime;
    });
  }

  @override
  void didUpdateWidget(SimpleVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isInitialized && _chewieController != null) {
      // Debug: Log widget updates
      if (widget.currentTime != oldWidget.currentTime ||
          widget.isPlaying != oldWidget.isPlaying) {
        print(
          '📱 Widget updated - isHost: ${widget.isHost}, time: ${oldWidget.currentTime} → ${widget.currentTime}, playing: ${oldWidget.isPlaying} → ${widget.isPlaying}',
        );
      }

      // Sync play/pause state from provider
      if (widget.isPlaying != oldWidget.isPlaying) {
        if (widget.isPlaying && !_videoPlayerController.value.isPlaying) {
          print('▶️ Syncing play state');
          _videoPlayerController.play();
        } else if (!widget.isPlaying &&
            _videoPlayerController.value.isPlaying) {
          print('⏸️ Syncing pause state');
          _videoPlayerController.pause();
        }
      }

      // Sync seek position from provider (ONLY for non-host viewers)
      // Host should not be synced back, as they control the video
      if (!widget.isHost) {
        final currentPosition = _videoPlayerController.value.position.inSeconds
            .toDouble();
        final timeDiff = (widget.currentTime - currentPosition).abs();

        // Reduced threshold to 0.5s for more responsive sync
        if (timeDiff > 0.5) {
          print(
            '🔄 Viewer syncing position: $currentPosition → ${widget.currentTime} (diff: ${timeDiff.toStringAsFixed(1)}s)',
          );
          _videoPlayerController.seekTo(
            Duration(seconds: widget.currentTime.round()),
          );
        } else {
          // Log when sync is skipped
          if (widget.currentTime != oldWidget.currentTime) {
            print(
              '⏭️ Viewer sync skipped - diff too small: ${timeDiff.toStringAsFixed(1)}s',
            );
          }
        }
      } else {
        // Log host position changes
        if (widget.currentTime != oldWidget.currentTime) {
          final currentPosition = _videoPlayerController
              .value
              .position
              .inSeconds
              .toDouble();
          print(
            '👑 Host position changed: widget=${widget.currentTime}, actual=$currentPosition',
          );
        }
      }
    }
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.videoUrl.isEmpty || !widget.videoUrl.startsWith('http')) {
        setState(() {
          _hasError = true;
          _errorMessage = 'URL video không hợp lệ';
        });
        return;
      }

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
          'Referer': _getReferer(widget.videoUrl),
        },
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.isPlaying,
        looping: false,
        showControls: widget.enableControls,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging:
            true, // Allow all users to change playback speed
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red, // Red handle for all users
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white30,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể phát video',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Seek to initial position if currentTime > 0 (for sync when joining room)
      if (widget.currentTime > 0) {
        print('🎬 Seeking to initial position: ${widget.currentTime}s');
        await _videoPlayerController.seekTo(
          Duration(seconds: widget.currentTime.round()),
        );
      }

      // Auto-play if host is playing
      if (widget.isPlaying) {
        print('▶️ Auto-playing video (host is playing)');
        await _videoPlayerController.play();
      }

      // Setup listener to track play/pause state changes
      _setupVideoPlayerListener();

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Không thể khởi tạo video player';
      });
    }
  }

  String _getReferer(String url) {
    if (url.contains('phimmoichillz')) {
      return 'https://phimmoichillz.net/';
    } else if (url.contains('kkphim')) {
      return 'https://kkphim.vip/';
    } else {
      return 'https://phimapi.com/';
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Không thể phát video',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Đang tải video...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),

          // Block all interactions for viewers
          if (!widget.isHost)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true, // Block ALL touch events
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}
