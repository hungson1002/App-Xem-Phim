import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/watch_room_model.dart';
import '../models/chat_message_model.dart';
import 'auth_service.dart';
import 'api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;

  // Stream controllers
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<WatchRoom> _roomJoinedController =
      StreamController<WatchRoom>.broadcast();
  final StreamController<Map<String, dynamic>> _userJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _videoStateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _videoSeekedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<ChatMessage> _newMessageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _reactionUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _syncResponseController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _hostChangedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<WatchRoom> get roomJoinedStream => _roomJoinedController.stream;
  Stream<Map<String, dynamic>> get userJoinedStream =>
      _userJoinedController.stream;
  Stream<Map<String, dynamic>> get userLeftStream => _userLeftController.stream;
  Stream<Map<String, dynamic>> get videoStateStream =>
      _videoStateController.stream;
  Stream<Map<String, dynamic>> get videoSeekedStream =>
      _videoSeekedController.stream;
  Stream<ChatMessage> get newMessageStream => _newMessageController.stream;
  Stream<Map<String, dynamic>> get reactionUpdatedStream =>
      _reactionUpdatedController.stream;
  Stream<Map<String, dynamic>> get syncResponseStream =>
      _syncResponseController.stream;
  Stream<Map<String, dynamic>> get hostChangedStream =>
      _hostChangedController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _setupEventListeners();
      
      // Connect and wait for connection with timeout
      final completer = Completer<void>();
      Timer? timeoutTimer;
      
      _socket!.onConnect((_) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      
      _socket!.onConnectError((error) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });
      
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Connection timeout'));
        }
      });
      
      _socket!.connect();
      await completer.future;

      _isConnected = true;
      _connectionController.add(true);
    } catch (e) {
      _errorController.add('Lỗi kết nối: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('Socket connected');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((data) {
      print('Connection error: $data');
      _errorController.add('Lỗi kết nối: $data');
    });

    // Room events
    _socket!.on('room-joined', (data) {
      try {
        // Backend sends: {room: {...}, videoState: {...}, userCount: N}
        if (data is Map) {
          final roomData = data['room'];
          if (roomData != null) {
            final room = WatchRoom.fromJson(roomData);
            _roomJoinedController.add(room);
          }
        }
      } catch (e) {
        print('Error parsing room-joined: $e');
      }
    });

    _socket!.on('user-joined', (data) {
      _userJoinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('user-left', (data) {
      _userLeftController.add(Map<String, dynamic>.from(data));
    });

    // Video events
    _socket!.on('video-state-changed', (data) {
      _videoStateController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('video-seeked', (data) {
      _videoSeekedController.add({
        'currentTime': data['currentTime'],
        'updatedBy': data['updatedBy'],
        'timestamp': data['timestamp'],
      });
    });

    // Chat events
    _socket!.on('new-message', (data) {
      try {
        final message = ChatMessage.fromJson(data);
        _newMessageController.add(message);
      } catch (e) {
        print('Error parsing new-message: $e');
      }
    });

    _socket!.on('reaction-updated', (data) {
      _reactionUpdatedController.add(Map<String, dynamic>.from(data));
    });

    // Sync events
    _socket!.on('sync-response', (data) {
      _syncResponseController.add(Map<String, dynamic>.from(data));
    });

    // Host events
    _socket!.on('host-changed', (data) {
      _hostChangedController.add(Map<String, dynamic>.from(data));
    });

    // Error events
    _socket!.on('error', (data) {
      _errorController.add(data['message'] ?? 'Unknown error');
    });
  }

  // Room methods
  void joinRoom(String roomId, {String? password}) {
    if (!_isConnected || _socket == null) {
      _errorController.add('Chưa kết nối đến server');
      return;
    }

    _currentRoomId = roomId;
    _socket!.emit('join-room', {
      'roomId': roomId,
      if (password != null) 'password': password,
    });
  }

  void leaveRoom(String roomId) {
    if (!_isConnected || _socket == null) return;
    
    _socket!.emit('leave-room', {'roomId': roomId});
    _currentRoomId = null;
  }

  // Video control methods
  void playVideo(String roomId, double currentTime) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('video-play', {
      'roomId': roomId,
      'currentTime': currentTime,
    });
  }

  void pauseVideo(String roomId, double currentTime) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('video-pause', {
      'roomId': roomId,
      'currentTime': currentTime,
    });
  }

  void seekVideo(String roomId, double currentTime) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('video-seek', {
      'roomId': roomId,
      'currentTime': currentTime,
    });
  }

  void requestSync(String roomId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('request-sync', {'roomId': roomId});
  }

  // Chat methods
  void sendMessage(String roomId, String message, {double videoTimestamp = 0}) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('send-message', {
      'roomId': roomId,
      'message': message,
      'videoTimestamp': videoTimestamp,
    });
  }

  void addReaction(String messageId, String emoji) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('add-reaction', {
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  // Disconnect
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _currentRoomId = null;
    _connectionController.add(false);
  }

  // Dispose
  void dispose() {
    disconnect();
    _connectionController.close();
    _roomJoinedController.close();
    _userJoinedController.close();
    _userLeftController.close();
    _videoStateController.close();
    _videoSeekedController.close();
    _newMessageController.close();
    _reactionUpdatedController.close();
    _syncResponseController.close();
    _hostChangedController.close();
    _errorController.close();
  }
}
