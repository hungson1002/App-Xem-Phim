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

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _setupVideoPlayerListener() {
    _videoPlayerController.addListener(() {
      if (!mounted) return;

      final isPlaying = _videoPlayerController.value.isPlaying;

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
        final currentTime = _videoPlayerController.value.position.inSeconds
            .toDouble();
        // Only notify on significant seeks (>2 seconds difference from widget.currentTime)
        if ((currentTime - widget.currentTime).abs() > 2.0) {
          widget.onSeek!(currentTime);
        }
      }
    });
  }

  @override
  void didUpdateWidget(SimpleVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isInitialized && _chewieController != null) {
      // Sync play/pause state from provider
      if (widget.isPlaying != oldWidget.isPlaying) {
        if (widget.isPlaying && !_videoPlayerController.value.isPlaying) {
          _videoPlayerController.play();
        } else if (!widget.isPlaying &&
            _videoPlayerController.value.isPlaying) {
          _videoPlayerController.pause();
        }
      }

      // Sync seek position from provider (only if difference is significant)
      final currentPosition = _videoPlayerController.value.position.inSeconds
          .toDouble();
      if ((widget.currentTime - currentPosition).abs() > 1.0) {
        print('🔄 Syncing position: $currentPosition → ${widget.currentTime}');
        _videoPlayerController.seekTo(
          Duration(seconds: widget.currentTime.round()),
        );
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
        // Disable playback controls for non-host viewers
        allowPlaybackSpeedChanging: widget.isHost,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: widget.isHost ? Colors.red : Colors.grey,
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

          // Transparent overlay for non-host viewers to prevent control interactions
          // Video will still play and sync, but viewers cannot manually control it
          if (!widget.isHost)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false, // We want to capture gestures
                child: GestureDetector(
                  onTap: () {
                    // Show temporary snackbar when viewer tries to interact
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chỉ host mới có thể điều khiển video'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
