// Service Singleton quản lý kết nối Socket.IO cho tính năng WatchAlong.
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/watch_room_model.dart';
import 'api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  String? _currentRoomCode;
  String? _userId;

  final _onVideoPlayController = StreamController<VideoSyncState>.broadcast();
  final _onVideoPauseController = StreamController<VideoSyncState>.broadcast();
  final _onVideoSeekController = StreamController<VideoSyncState>.broadcast();
  final _onSyncStateController = StreamController<VideoSyncState>.broadcast();
  final _onEpisodeChangeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onUserJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onUserLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onRoomClosedController = StreamController<String>.broadcast();
  final _onConnectedController = StreamController<bool>.broadcast();

  Stream<VideoSyncState> get onVideoPlay => _onVideoPlayController.stream;
  Stream<VideoSyncState> get onVideoPause => _onVideoPauseController.stream;
  Stream<VideoSyncState> get onVideoSeek => _onVideoSeekController.stream;
  Stream<VideoSyncState> get onSyncState => _onSyncStateController.stream;
  Stream<Map<String, dynamic>> get onEpisodeChange =>
      _onEpisodeChangeController.stream;
  Stream<Map<String, dynamic>> get onUserJoined =>
      _onUserJoinedController.stream;
  Stream<Map<String, dynamic>> get onUserLeft => _onUserLeftController.stream;
  Stream<String> get onRoomClosed => _onRoomClosedController.stream;
  Stream<bool> get onConnected => _onConnectedController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? get currentRoomCode => _currentRoomCode;

  void connect({String? token}) {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders(
            token != null ? {'Authorization': 'Bearer $token'} : {},
          )
          .build(),
    );

    _socket!.onConnect((_) {
      _onConnectedController.add(true);
    });

    _socket!.onDisconnect((_) {
      _onConnectedController.add(false);
    });

    _socket!.onError((error) {
      print('Socket error: $error');
    });

    _socket!.on('video-play', (data) {
      _onVideoPlayController.add(VideoSyncState.fromJson(data));
    });

    _socket!.on('video-pause', (data) {
      _onVideoPauseController.add(VideoSyncState.fromJson(data));
    });

    _socket!.on('video-seek', (data) {
      _onVideoSeekController.add(VideoSyncState.fromJson(data));
    });

    _socket!.on('sync-state', (data) {
      _onSyncStateController.add(VideoSyncState.fromJson(data));
    });

    _socket!.on('episode-change', (data) {
      _onEpisodeChangeController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user-joined', (data) {
      _onUserJoinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user-left', (data) {
      _onUserLeftController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('room-closed', (data) {
      _onRoomClosedController.add(data['message'] ?? 'Room closed');
      _currentRoomCode = null;
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_currentRoomCode != null) {
      leaveRoom(_currentRoomCode!);
    }
    _socket?.disconnect();
    _socket = null;
  }

  void joinRoom(String roomCode, String userId, String userName) {
    if (_socket == null || !_socket!.connected) {
      connect();
    }

    _currentRoomCode = roomCode;
    _userId = userId;

    _socket?.emit('join-room', {
      'roomCode': roomCode,
      'userId': userId,
      'userName': userName,
    });
  }

  void leaveRoom(String roomCode) {
    _socket?.emit('leave-room', {'roomCode': roomCode});
    _currentRoomCode = null;
  }

  void emitPlay(double currentTime) {
    if (_currentRoomCode == null) return;
    _socket?.emit('video-play', {
      'roomCode': _currentRoomCode,
      'currentTime': currentTime,
      'userId': _userId,
    });
  }

  void emitPause(double currentTime) {
    if (_currentRoomCode == null) return;
    _socket?.emit('video-pause', {
      'roomCode': _currentRoomCode,
      'currentTime': currentTime,
      'userId': _userId,
    });
  }

  void emitSeek(double currentTime) {
    if (_currentRoomCode == null) return;
    _socket?.emit('video-seek', {
      'roomCode': _currentRoomCode,
      'currentTime': currentTime,
      'userId': _userId,
    });
  }

  void emitEpisodeChange(int serverIndex, int episodeIndex) {
    if (_currentRoomCode == null) return;
    _socket?.emit('episode-change', {
      'roomCode': _currentRoomCode,
      'serverIndex': serverIndex,
      'episodeIndex': episodeIndex,
      'userId': _userId,
    });
  }

  void requestSync() {
    if (_currentRoomCode == null) return;
    _socket?.emit('sync-request', {'roomCode': _currentRoomCode});
  }

  void closeRoom(String roomCode) {
    _socket?.emit('close-room', {'roomCode': roomCode});
    _currentRoomCode = null;
  }

  void dispose() {
    disconnect();
    _onVideoPlayController.close();
    _onVideoPauseController.close();
    _onVideoSeekController.close();
    _onSyncStateController.close();
    _onEpisodeChangeController.close();
    _onUserJoinedController.close();
    _onUserLeftController.close();
    _onRoomClosedController.close();
    _onConnectedController.close();
  }
}
