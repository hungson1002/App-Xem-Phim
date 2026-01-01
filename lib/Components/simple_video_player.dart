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

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(SimpleVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isInitialized && _chewieController != null) {
      // Sync play/pause state from provider
      if (widget.isPlaying != oldWidget.isPlaying) {
        if (widget.isPlaying && !_videoPlayerController.value.isPlaying) {
          _videoPlayerController.play();
        } else if (!widget.isPlaying && _videoPlayerController.value.isPlaying) {
          _videoPlayerController.pause();
        }
      }

      // Sync seek position from provider (only if difference is significant)
      final currentPosition = _videoPlayerController.value.position.inSeconds.toDouble();
      if ((widget.currentTime - currentPosition).abs() > 2.0) {
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
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
