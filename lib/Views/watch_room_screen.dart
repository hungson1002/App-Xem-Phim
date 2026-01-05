// Màn hình phòng xem chung, hỗ trợ đồng bộ video và chat giữa các thành viên.
import 'dart:async';
import 'package:flutter/material.dart';

import '../models/movie_detail_model.dart';
import '../models/user_model.dart';
import '../models/watch_room_model.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import '../services/socket_service.dart';
import '../services/watch_room_service.dart';
import '../utils/app_snackbar.dart';

import '../Components/watch_room/watch_room_player.dart';
import '../Components/watch_room/watch_room_info.dart';
import '../Components/watch_room/watch_room_participants.dart';
import '../Components/watch_room/watch_room_episode_list.dart';

class WatchRoomScreen extends StatefulWidget {
  final WatchRoom room;
  final bool isHost;

  const WatchRoomScreen({super.key, required this.room, required this.isHost});

  @override
  State<WatchRoomScreen> createState() => _WatchRoomScreenState();
}

class _WatchRoomScreenState extends State<WatchRoomScreen> {
  final SocketService _socketService = SocketService();
  final WatchRoomService _watchRoomService = WatchRoomService();
  final AuthService _authService = AuthService();
  final MovieService _movieService = MovieService();

  late WatchRoom _room;
  User? _user;
  MovieDetail? _movieDetail;
  bool _isLoading = true;

  String? _currentVideoUrl;
  int _currentServerIndex = 0;
  int _currentEpisodeIndex = 0;

  final List<StreamSubscription> _subscriptions = [];

  Key _playerKey = UniqueKey();

  bool _isSyncing = false;

  bool _showSyncIndicator = false;
  IconData _syncIndicatorIcon = Icons.play_arrow;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _currentServerIndex = widget.room.currentServer;
    _currentEpisodeIndex = widget.room.currentEpisode;
    _initRoom();
  }

  Future<void> _initRoom() async {
    _user = await _authService.getUser();
    _movieDetail = await _movieService.getMovieDetailFull(_room.movieSlug);

    if (_movieDetail != null) {
      _updateVideoUrl();
    }

    final token = await _authService.getToken();
    _socketService.connect(token: token);

    if (_user != null) {
      _socketService.joinRoom(
        _room.roomCode,
        _user!.id,
        _user!.name.isNotEmpty ? _user!.name : _user!.email,
      );
    }

    _setupSocketListeners();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupSocketListeners() {
    _subscriptions.add(
      _socketService.onSyncState.listen((state) {
        if (!mounted || _isSyncing) return;
        setState(() {
          _currentServerIndex = state.currentServer;
          _currentEpisodeIndex = state.currentEpisode;
          _updateVideoUrl();
        });
      }),
    );

    if (!widget.isHost) {
      _subscriptions.add(
        _socketService.onVideoPlay.listen((state) {
          if (!mounted) return;
          _showSyncIcon(Icons.play_arrow);
        }),
      );

      _subscriptions.add(
        _socketService.onVideoPause.listen((state) {
          if (!mounted) return;
          _showSyncIcon(Icons.pause);
        }),
      );

      _subscriptions.add(
        _socketService.onVideoSeek.listen((state) {
          if (!mounted) return;
          _showSyncIcon(Icons.fast_forward);
        }),
      );
    }

    _subscriptions.add(
      _socketService.onEpisodeChange.listen((data) {
        if (!mounted || _isSyncing) return;
        final serverIndex = data['serverIndex'] as int;
        final episodeIndex = data['episodeIndex'] as int;
        setState(() {
          _currentServerIndex = serverIndex;
          _currentEpisodeIndex = episodeIndex;
          _updateVideoUrl();
          _playerKey = UniqueKey();
        });
        AppSnackBar.showInfo(context, 'Đổi tập phim');
      }),
    );

    _subscriptions.add(
      _socketService.onUserJoined.listen((data) {
        if (!mounted) return;
        final userName = data['userName'] ?? 'Ai đó';
        AppSnackBar.showInfo(context, '$userName đã tham gia');
        _refreshRoom();
      }),
    );

    _subscriptions.add(
      _socketService.onUserLeft.listen((data) {
        if (!mounted) return;
        _refreshRoom();
      }),
    );

    _subscriptions.add(
      _socketService.onRoomClosed.listen((message) {
        if (!mounted) return;
        AppSnackBar.showWarning(context, message);
        Navigator.pop(context);
      }),
    );
  }

  void _showSyncIcon(IconData icon) {
    setState(() {
      _showSyncIndicator = true;
      _syncIndicatorIcon = icon;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSyncIndicator = false);
      }
    });
  }

  void _updateVideoUrl() {
    if (_movieDetail == null) return;
    if (_movieDetail!.episodes.isEmpty) return;
    final server = _movieDetail!.episodes[_currentServerIndex];
    if (server.episodes.isEmpty) return;
    final episode = server.episodes[_currentEpisodeIndex];
    _currentVideoUrl = episode.linkM3u8.isNotEmpty
        ? episode.linkM3u8
        : episode.linkEmbed;
  }

  Future<void> _refreshRoom() async {
    final room = await _watchRoomService.getRoom(_room.roomCode);
    if (room != null && mounted) {
      setState(() => _room = room);
    }
  }

  Future<void> _leaveRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isHost ? 'Đóng phòng?' : 'Rời phòng?'),
        content: Text(
          widget.isHost
              ? 'Đóng phòng sẽ kết thúc phiên xem cho tất cả mọi người.'
              : 'Bạn có chắc muốn rời phòng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.isHost ? 'Đóng phòng' : 'Rời phòng'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (widget.isHost) {
        _socketService.closeRoom(_room.roomCode);
        await _watchRoomService.closeRoom(_room.roomCode);
      } else {
        _socketService.leaveRoom(_room.roomCode);
        await _watchRoomService.leaveRoom(_room.roomCode);
      }
      Navigator.pop(context);
    }
  }

  void _onEpisodeTap(int index) {
    if (!widget.isHost) {
      AppSnackBar.showWarning(context, 'Chỉ host mới có thể đổi tập');
      return;
    }

    _isSyncing = true;
    setState(() {
      _currentEpisodeIndex = index;
      _updateVideoUrl();
      _playerKey = UniqueKey();
    });
    _socketService.emitEpisodeChange(_currentServerIndex, index);
    Future.delayed(const Duration(milliseconds: 500), () => _isSyncing = false);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _socketService.leaveRoom(_room.roomCode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  WatchRoomPlayer(
                    videoUrl: _currentVideoUrl,
                    isHost: widget.isHost,
                    roomCode: _room.roomCode,
                    initialTime: _room.currentTime,
                    socketService: _socketService,
                    showSyncIndicator: _showSyncIndicator,
                    syncIndicatorIcon: _syncIndicatorIcon,
                    onLeave: _leaveRoom,
                    playerKey: _playerKey,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_movieDetail != null &&
                              _movieDetail!.episodes.isNotEmpty)
                            WatchRoomInfo(
                              movieName: _room.movieName,
                              serverName: _movieDetail!
                                  .episodes[_currentServerIndex]
                                  .serverName,
                              episodeName: _movieDetail!
                                  .episodes[_currentServerIndex]
                                  .episodes[_currentEpisodeIndex]
                                  .name,
                            ),

                          const Divider(color: Colors.grey, height: 1),

                          WatchRoomParticipants(
                            participants: _room.participants,
                            hostId: _room.hostId,
                          ),

                          const Divider(color: Colors.grey, height: 1),

                          if (_movieDetail != null &&
                              _movieDetail!.episodes.isNotEmpty)
                            WatchRoomEpisodeList(
                              episodes: _movieDetail!
                                  .episodes[_currentServerIndex]
                                  .episodes,
                              currentEpisodeIndex: _currentEpisodeIndex,
                              isHost: widget.isHost,
                              onEpisodeTap: _onEpisodeTap,
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
