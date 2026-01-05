import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/socket_service.dart';

/// Synced video player - host can control, guest syncs automatically
class SyncedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isHost;
  final String roomCode;
  final double initialTime;
  final SocketService socketService;

  const SyncedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isHost,
    required this.roomCode,
    required this.initialTime,
    required this.socketService,
  });

  @override
  State<SyncedVideoPlayer> createState() => _SyncedVideoPlayerState();
}

class _SyncedVideoPlayerState extends State<SyncedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isError = false;
  bool _isInitialized = false;
  bool _isSyncing = false;

  final List<StreamSubscription> _subscriptions = [];
  bool _wasPlaying = false;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Guest syncs to host
    if (!widget.isHost) {
      _subscriptions.add(
        widget.socketService.onVideoPlay.listen((state) {
          if (_isSyncing || _videoController == null) return;
          _isSyncing = true;
          final target = Duration(
            milliseconds: (state.currentTime * 1000).toInt(),
          );
          _videoController!.seekTo(target);
          _videoController!.play();
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _isSyncing = false,
          );
        }),
      );

      _subscriptions.add(
        widget.socketService.onVideoPause.listen((state) {
          if (_isSyncing || _videoController == null) return;
          _isSyncing = true;
          final target = Duration(
            milliseconds: (state.currentTime * 1000).toInt(),
          );
          _videoController!.pause();
          _videoController!.seekTo(target);
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _isSyncing = false,
          );
        }),
      );

      _subscriptions.add(
        widget.socketService.onVideoSeek.listen((state) {
          if (_isSyncing || _videoController == null) return;
          _isSyncing = true;
          final target = Duration(
            milliseconds: (state.currentTime * 1000).toInt(),
          );
          _videoController!.seekTo(target);
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _isSyncing = false,
          );
        }),
      );
    }
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoController!.initialize();

      if (widget.initialTime > 0) {
        await _videoController!.seekTo(
          Duration(milliseconds: (widget.initialTime * 1000).toInt()),
        );
      }

      if (widget.isHost) {
        _videoController!.addListener(_onVideoStateChanged);
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: widget.isHost,
        // Host sees all controls, guest sees only fullscreen button
        showControls: true,
        showControlsOnInitialize: widget.isHost,
        customControls: widget.isHost ? null : const GuestControls(),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Lỗi: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF5BA3F5),
          handleColor: const Color(0xFF5BA3F5),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey[700]!,
        ),
      );

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) setState(() => _isError = true);
    }
  }

  void _onVideoStateChanged() {
    if (!mounted || _isSyncing || _videoController == null) return;

    final isPlaying = _videoController!.value.isPlaying;
    final position = _videoController!.value.position;

    if (isPlaying && !_wasPlaying) {
      widget.socketService.emitPlay(position.inMilliseconds / 1000);
    } else if (!isPlaying && _wasPlaying) {
      widget.socketService.emitPause(position.inMilliseconds / 1000);
    }

    final diff = (position - _lastPosition).abs();
    if (diff > const Duration(seconds: 2) && _wasPlaying == isPlaying) {
      widget.socketService.emitSeek(position.inMilliseconds / 1000);
    }

    _wasPlaying = isPlaying;
    _lastPosition = position;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _videoController?.removeListener(_onVideoStateChanged);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
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
              SizedBox(height: 8),
              Text(
                'Không thể tải video',
                style: TextStyle(color: Colors.white),
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
          child: CircularProgressIndicator(color: Color(0xFF5BA3F5)),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}

/// Custom controls for guest - only shows fullscreen button
class GuestControls extends StatelessWidget {
  const GuestControls({super.key});

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);

    return Stack(
      children: [
        // Progress bar (view only)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            color: Colors.grey[800],
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: chewieController.videoPlayerController,
              builder: (context, value, child) {
                final duration = value.duration.inMilliseconds;
                final position = value.position.inMilliseconds;
                final progress = duration > 0 ? position / duration : 0.0;
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(color: const Color(0xFF5BA3F5)),
                );
              },
            ),
          ),
        ),

        // Fullscreen button only
        Positioned(
          bottom: 8,
          right: 8,
          child: IconButton(
            icon: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: () {
              chewieController.toggleFullScreen();
            },
          ),
        ),
      ],
    );
  }
}
