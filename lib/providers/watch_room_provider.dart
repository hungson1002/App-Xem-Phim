import 'dart:async';
import 'package:fe/models/user_model.dart';
import 'package:flutter/material.dart';
import '../models/watch_room_model.dart';
import '../models/chat_message_model.dart';
import '../services/watchroom_service.dart';
import '../services/socket_service.dart';

class WatchRoomProvider with ChangeNotifier {
  final WatchRoomService _watchRoomService = WatchRoomService();
  final SocketService _socketService = SocketService();

  // State
  WatchRoom? _currentRoom;
  List<ChatMessage> _messages = [];
  List<WatchRoom> _publicRooms = [];
  List<WatchRoom> _myRooms = [];
  bool _isLoading = false;
  String? _error;
  bool _isConnected = false;

  // User cache
  final Map<String, User> _userCache = {};
  Map<String, User> get userCache => _userCache;

  // Video state
  double _currentTime = 0;
  bool _isPlaying = false;
  bool _isSyncing = false;

  // Subscriptions
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _roomJoinedSubscription;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _videoStateSubscription;
  StreamSubscription? _videoSeekedSubscription;
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _reactionUpdatedSubscription;
  StreamSubscription? _syncResponseSubscription;
  StreamSubscription? _hostChangedSubscription;
  StreamSubscription? _errorSubscription;

  // Getters
  WatchRoom? get currentRoom => _currentRoom;

  List<ChatMessage> get messages => _messages;
  List<WatchRoom> get publicRooms => _publicRooms;
  List<WatchRoom> get myRooms => _myRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _isConnected;
  double get currentTime => _currentTime;
  bool get isPlaying => _isPlaying;
  bool get isSyncing => _isSyncing;

  WatchRoomProvider() {
    _initializeSocketListeners();
  }

  void _initializeSocketListeners() {
    _connectionSubscription = _socketService.connectionStream.listen((
      connected,
    ) {
      _isConnected = connected;
      notifyListeners();
    });

    _roomJoinedSubscription = _socketService.roomJoinedStream.listen((room) {
      // Preserve episodeInfo from existing room if available
      if (_currentRoom != null &&
          _currentRoom!.episodeInfo != null &&
          room.episodeInfo == null) {
        // Create new room with preserved episodeInfo
        _currentRoom = WatchRoom(
          id: room.id,
          roomId: room.roomId,
          movieId: room.movieId,
          episodeSlug: room.episodeSlug,
          hostId: room.hostId,
          title: room.title,
          description: room.description,
          isPrivate: room.isPrivate,
          password: room.password,
          maxUsers: room.maxUsers,
          currentUsers: room.currentUsers,
          videoState: room.videoState,
          settings: room.settings,
          status: room.status,
          createdAt: room.createdAt,
          updatedAt: room.updatedAt,
          movieInfo: room.movieInfo,
          episodeInfo:
              _currentRoom!.episodeInfo, // Preserve existing episodeInfo
        );
      } else {
        _currentRoom = room;
      }
      _currentTime = room.videoState.currentTime;
      _isPlaying = room.videoState.isPlaying;
      notifyListeners();
    });

    _userJoinedSubscription = _socketService.userJoinedStream.listen((data) {
      if (_currentRoom != null) {
        // Update user count or user list if needed
        notifyListeners();
      }
    });

    _userLeftSubscription = _socketService.userLeftStream.listen((data) {
      if (_currentRoom != null) {
        // Update user count or user list if needed
        notifyListeners();
      }
    });

    _videoStateSubscription = _socketService.videoStateStream.listen((data) {
      _currentTime = (data['currentTime'] ?? 0).toDouble();
      _isPlaying = data['isPlaying'] ?? false;
      notifyListeners();
    });

    _videoSeekedSubscription = _socketService.videoSeekedStream.listen((data) {
      _currentTime = (data['currentTime'] ?? 0).toDouble();
      notifyListeners();
    });

    _newMessageSubscription = _socketService.newMessageStream.listen((
      message,
    ) async {
      _messages.add(message);
      if (!_userCache.containsKey(message.userId)) {
        try {
          final result = await _watchRoomService.getUserById(message.userId);
          if (result != null && result['user'] != null) {
            final user = User.fromJson(result['user']);
            _userCache[message.userId] = user;
          }
        } catch (e) {
          print('Error loading user for message: $e');
        }
      }
      notifyListeners();
    });

    _reactionUpdatedSubscription = _socketService.reactionUpdatedStream.listen((
      data,
    ) {
      final messageId = data['messageId'];
      // final reactions = data['reactions'] as List; // Unused for now

      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        // Update message reactions
        notifyListeners();
      }
    });

    _syncResponseSubscription = _socketService.syncResponseStream.listen((
      data,
    ) {
      final videoState = data['videoState'];
      _currentTime = (videoState['currentTime'] ?? 0).toDouble();
      _isPlaying = videoState['isPlaying'] ?? false;
      _isSyncing = false;
      notifyListeners();
    });

    _hostChangedSubscription = _socketService.hostChangedStream.listen((data) {
      if (_currentRoom != null) {
        // Update host information
        notifyListeners();
      }
    });

    _errorSubscription = _socketService.errorStream.listen((error) {
      _error = error;
      notifyListeners();
    });
  }

  // Socket connection
  Future<void> connectSocket() async {
    await _socketService.connect();
  }

  void disconnectSocket() {
    _socketService.disconnect();
  }

  // Room management
  Future<bool> createRoom({
    required String movieId,
    required String episodeSlug,
    required String title,
    String? description,
    bool isPrivate = false,
    String? password,
    int maxUsers = 50,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _watchRoomService.createWatchRoom(
        movieId: movieId,
        episodeSlug: episodeSlug,
        title: title,
        description: description,
        isPrivate: isPrivate,
        password: password,
        maxUsers: maxUsers,
      );

      if (result['success']) {
        _currentRoom = result['room'];
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi tạo phòng: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinRoom(String roomId, {String? password}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _watchRoomService.getWatchRoom(roomId);

      if (result['success']) {
        _currentRoom = result['room'];
        notifyListeners();

        //load user + avt
        final userResult = await _watchRoomService.getRoomUsers(roomId);

        if (userResult['success'] == true) {
          for (final u in userResult['users']) {
            final user = User.fromJson(u);
            _userCache[user.id] = user;
          }
        }
        // connect socket
        if (!_socketService.isConnected) {
          await connectSocket();
        }

        // Listen for room-joined event before loading chat
        final subscription = _socketService.roomJoinedStream.listen((
          room,
        ) async {
          await loadChatHistory(roomId);
        });

        // Join room via socket
        _socketService.joinRoom(roomId, password: password);

        // Clean up subscription after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          subscription.cancel();
        });
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Lỗi khi tham gia phòng: $e');
    } finally {
      _setLoading(false);
    }
  }

  void leaveRoom({bool notify = true}) {
    if (_currentRoom != null) {
      _socketService.leaveRoom(_currentRoom!.roomId);
      _currentRoom = null;
      _messages.clear();
      _currentTime = 0;
      _isPlaying = false;
      if (notify) {
        notifyListeners();
      }
    }
    _userCache.clear();
  }

  // Video control
  void playVideo() {
    if (_currentRoom != null && _isConnected) {
      _socketService.playVideo(_currentRoom!.roomId, _currentTime);
    }
  }

  void pauseVideo() {
    if (_currentRoom != null && _isConnected) {
      _socketService.pauseVideo(_currentRoom!.roomId, _currentTime);
    }
  }

  void seekVideo(double time) {
    if (_currentRoom != null && _isConnected) {
      _currentTime = time;
      _socketService.seekVideo(_currentRoom!.roomId, time);
      notifyListeners();
    }
  }

  void requestSync() {
    if (_currentRoom != null && _isConnected) {
      _isSyncing = true;
      _socketService.requestSync(_currentRoom!.roomId);
      notifyListeners();
    }
  }

  void updateCurrentTime(double time) {
    _currentTime = time;
    notifyListeners();
  }

  // Chat
  void sendMessage(String message, {ChatReply? replyTo}) {
    if (_currentRoom != null && _isConnected && message.trim().isNotEmpty) {
      _socketService.sendMessage(
        _currentRoom!.roomId,
        message.trim(),
        videoTimestamp: _currentTime,
        replyTo: replyTo,
      );
    }
  }

  void addReaction(String messageId, String emoji) {
    if (_isConnected) {
      _socketService.addReaction(messageId, emoji);
    }
  }

  int _chatPage = 1;
  int _chatTotalPages = 1;
  bool _isLoadingMoreChat = false;

  bool get hasMoreChatHistory => _chatPage < _chatTotalPages;
  bool get isLoadingMoreChat => _isLoadingMoreChat;
  int get chatPage => _chatPage;

  Future<void> loadChatHistory(String roomId, {int page = 1}) async {
    if (page > 1) _isLoadingMoreChat = true;
    notifyListeners();

    try {
      final result = await _watchRoomService.getChatHistory(roomId, page: page);

      if (result['success']) {
        final pagination = result['pagination'];
        if (pagination != null) {
          _chatPage = pagination['current'];
          _chatTotalPages = pagination['total'];
        }

        final List<ChatMessage> messages = result['messages'];

        // Cache users from messages
        for (final message in messages) {
          if (!_userCache.containsKey(message.userId)) {
            try {
              final userResult = await _watchRoomService.getUserById(
                message.userId,
              );
              if (userResult != null && userResult['user'] != null) {
                final user = User.fromJson(userResult['user']);
                _userCache[message.userId] = user;
              }
            } catch (e) {
              print('Error loading user ${message.userId}: $e');
            }
          }
        }

        if (page == 1) {
          _messages = messages;
        } else {
          _messages.insertAll(0, messages);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading chat history: $e');
    } finally {
      if (page > 1) {
        _isLoadingMoreChat = false;
        notifyListeners();
      }
    }
  }

  // Public rooms
  Future<void> loadPublicRooms({
    int page = 1,
    String? movieId,
    String? search,
  }) async {
    print(
      'Loading public rooms - page: $page, movieId: $movieId, search: $search',
    );
    _setLoading(true);
    _clearError();

    try {
      print('Calling watch room service...');
      final result = await _watchRoomService.getWatchRooms(
        page: page,
        movieId: movieId,
        search: search,
      );

      print('Result received: ${result['success']}');
      print('Rooms count: ${result['rooms']?.length ?? 0}');

      if (result['success']) {
        if (page == 1) {
          _publicRooms = result['rooms'];
        } else {
          _publicRooms.addAll(result['rooms']);
        }
        print('Public rooms loaded: ${_publicRooms.length} rooms');
        notifyListeners();
      } else {
        print('Failed to load rooms: ${result['message']}');
        _setError(result['message']);
      }
    } catch (e) {
      print(' Exception loading public rooms: $e');
      _setError('Lỗi khi tải danh sách phòng: $e');
    } finally {
      _setLoading(false);
    }
  }

  // My rooms
  Future<void> loadMyRooms({String type = 'hosting'}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _watchRoomService.getMyRooms(type: type);

      if (result['success']) {
        _myRooms = result['rooms'];
        notifyListeners();
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Lỗi khi tải phòng của bạn: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Room settings
  Future<bool> updateRoomSettings({
    String? title,
    String? description,
    int? maxUsers,
    Map<String, dynamic>? settings,
  }) async {
    if (_currentRoom == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _watchRoomService.updateWatchRoom(
        _currentRoom!.roomId,
        title: title,
        description: description,
        maxUsers: maxUsers,
        settings: settings,
      );

      if (result['success']) {
        _currentRoom = result['room'];
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi cập nhật cài đặt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRoom() async {
    if (_currentRoom == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _watchRoomService.deleteWatchRoom(
        _currentRoom!.roomId,
      );

      if (result['success']) {
        leaveRoom();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi xóa phòng: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  bool isHost(String userId) {
    return _currentRoom?.isHost(userId) ?? false;
  }

  bool canControlVideo(String userId) {
    if (_currentRoom == null) return false;
    return isHost(userId) || _currentRoom!.settings.allowUserControl;
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _roomJoinedSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _videoStateSubscription?.cancel();
    _videoSeekedSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _reactionUpdatedSubscription?.cancel();
    _syncResponseSubscription?.cancel();
    _hostChangedSubscription?.cancel();
    _errorSubscription?.cancel();

    _socketService.dispose();
    super.dispose();
  }
}
