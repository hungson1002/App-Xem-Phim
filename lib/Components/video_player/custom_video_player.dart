import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  // Callbacks for sync (used in WatchRoom)
  final void Function(Duration position)? onPlay;
  final void Function(Duration position)? onPause;
  final void Function(Duration position)? onSeek;

  // Control restrictions for WatchRoom guests
  final bool showControls;

  // External control for syncing
  final Stream<VideoCommand>? commandStream;

  // History / Progress
  final Duration? startAt;
  final void Function(Duration position)? onProgress;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = false,
    this.onPlay,
    this.onPause,
    this.onSeek,
    this.showControls = true,
    this.commandStream,
    this.startAt,
    this.onProgress,
  });

  @override
  State<CustomVideoPlayer> createState() => CustomVideoPlayerState();
}

// Video command for external control
enum VideoCommandType { play, pause, seek }

class VideoCommand {
  final VideoCommandType type;
  final Duration? seekPosition;

  VideoCommand.play() : type = VideoCommandType.play, seekPosition = null;
  VideoCommand.pause() : type = VideoCommandType.pause, seekPosition = null;
  VideoCommand.seek(Duration position)
    : type = VideoCommandType.seek,
      seekPosition = position;
}

class CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;

  // Track state for callbacks
  bool _wasPlaying = false;
  Duration _lastPosition = Duration.zero;

  // Flag to ignore callbacks when receiving external commands
  bool _isExternalCommand = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();

    // Listen to external commands
    widget.commandStream?.listen(_handleExternalCommand);
  }

  @override
  void didUpdateWidget(CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _videoPlayerController.removeListener(_onVideoStateChanged);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
  }

  // Handle external commands (from socket sync)
  void _handleExternalCommand(VideoCommand command) {
    if (!mounted || _chewieController == null) return;

    _isExternalCommand = true;

    switch (command.type) {
      case VideoCommandType.play:
        _videoPlayerController.play();
        break;
      case VideoCommandType.pause:
        _videoPlayerController.pause();
        break;
      case VideoCommandType.seek:
        if (command.seekPosition != null) {
          _videoPlayerController.seekTo(command.seekPosition!);
        }
        break;
    }

    // Reset flag after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _isExternalCommand = false;
    });
  }

  // Public methods for external control
  void play() {
    _videoPlayerController.play();
  }

  void pause() {
    _videoPlayerController.pause();
  }

  void seekTo(Duration position) {
    _videoPlayerController.seekTo(position);
  }

  Duration get currentPosition => _videoPlayerController.value.position;
  bool get isPlaying => _videoPlayerController.value.isPlaying;

  void _onVideoStateChanged() {
    if (!mounted || _isExternalCommand) return;

    final isPlaying = _videoPlayerController.value.isPlaying;
    final position = _videoPlayerController.value.position;

    // Detect play/pause changes
    if (isPlaying && !_wasPlaying) {
      // Started playing
      widget.onPlay?.call(position);
    } else if (!isPlaying && _wasPlaying) {
      // Paused
      widget.onPause?.call(position);
    }

    // Detect seek (position changed significantly while paused or just after play)
    final positionDiff = (position - _lastPosition).abs();
    if (positionDiff > const Duration(seconds: 2) && _wasPlaying == isPlaying) {
      // Likely a seek operation
      widget.onSeek?.call(position);
    }

    _wasPlaying = isPlaying;
    _lastPosition = position;
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isError = false;
      _chewieController = null;
    });

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      // Seek to initial position if provided
      if (widget.startAt != null && widget.startAt! > Duration.zero) {
        await _videoPlayerController.seekTo(widget.startAt!);
      }

      // Add listener for sync callbacks and progress
      _videoPlayerController.addListener(_onVideoStateChanged);

      // Progress listener (VideoPlayerController notifies often)
      _videoPlayerController.addListener(() {
        if (!mounted || !_videoPlayerController.value.isInitialized) return;
        widget.onProgress?.call(_videoPlayerController.value.position);
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        showControls: widget.showControls,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Lỗi phát video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        // Customize the player UI if needed
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF5BA3F5),
          handleColor: const Color(0xFF5BA3F5),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[700]!,
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Không thể tải video',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null &&
        _videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5BA3F5)),
        ),
      );
    }
  }
}
