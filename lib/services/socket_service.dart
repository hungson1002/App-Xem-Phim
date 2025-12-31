import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/watch_room_model.dart';
import '../models/chat_message_model.dart';
import 'auth_service.dart';
import 'api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;

  // Stream controllers
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<WatchRoom> _roomJoinedController = StreamController<WatchRoom>.broadcast();
  final StreamController<Map<String, dynamic>> _userJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _videoStateController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _videoSeekedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<ChatMessage> _newMessageController = StreamController<ChatMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _reactionUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _syncResponseController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _hostChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<WatchRoom> get roomJoinedStream => _roomJoinedController.stream;
  Stream<Map<String, dynamic>> get userJoinedStream => _userJoinedController.stream;
  Stream<Map<String, dynamic>> get userLeftStream => _userLeftController.stream;
  Stream<Map<String, dynamic>> get videoStateStream => _videoStateController.stream;
  Stream<Map<String, dynamic>> get videoSeekedStream => _videoSeekedController.stream;
  Stream<ChatMessage> get newMessageStream => _newMessageController.stream;
  Stream<Map<String, dynamic>> get reactionUpdatedStream => _reactionUpdatedController.stream;
  Stream<Map<String, dynamic>> get syncResponseStream => _syncResponseController.stream;
  Stream<Map<String, dynamic>> get hostChangedStream => _hostChangedController.stream;
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

      // For demo purposes, we'll simulate socket connection
      // In real implementation, you would use actual WebSocket
      await Future.delayed(const Duration(seconds: 1));
      
      _isConnected = true;
      _connectionController.add(true);
      
    } catch (e) {
      print('Socket connection error: $e');
      _errorController.add('Lỗi kết nối: $e');
    }
  }

  // Room methods
  void joinRoom(String roomId, {String? password}) {
    if (!_isConnected) {
      _errorController.add('Chưa kết nối đến server');
      return;
    }

    _currentRoomId = roomId;
    
    // Simulate joining room
    Future.delayed(const Duration(milliseconds: 500), () {
      // Mock room data
      final mockRoom = WatchRoom(
        id: 'mock_id',
        roomId: roomId,
        movieId: 'mock_movie_id',
        episodeSlug: 'tap-1',
        hostId: 'mock_host_id',
        title: 'Phòng xem demo',
        description: 'Đây là phòng demo',
        isPrivate: false,
        maxUsers: 50,
        currentUsers: [],
        videoState: VideoState(
          currentTime: 0,
          isPlaying: false,
          lastUpdated: DateTime.now(),
        ),
        settings: RoomSettings(
          allowChat: true,
          allowUserControl: false,
          syncTolerance: 2,
        ),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _roomJoinedController.add(mockRoom);
    });
  }

  void leaveRoom(String roomId) {
    if (!_isConnected) return;
    _currentRoomId = null;
  }

  // Video control methods
  void playVideo(String roomId, double currentTime) {
    if (!_isConnected) return;
    
    // Simulate video state change
    Future.delayed(const Duration(milliseconds: 100), () {
      _videoStateController.add({
        'action': 'play',
        'currentTime': currentTime,
        'isPlaying': true,
        'updatedBy': 'You',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void pauseVideo(String roomId, double currentTime) {
    if (!_isConnected) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _videoStateController.add({
        'action': 'pause',
        'currentTime': currentTime,
        'isPlaying': false,
        'updatedBy': 'You',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void seekVideo(String roomId, double currentTime) {
    if (!_isConnected) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _videoSeekedController.add({
        'currentTime': currentTime,
        'updatedBy': 'You',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void requestSync(String roomId) {
    if (!_isConnected) return;
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _syncResponseController.add({
        'videoState': {
          'currentTime': 120.0,
          'isPlaying': true,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        'serverTime': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  // Chat methods
  void sendMessage(String roomId, String message, {double videoTimestamp = 0}) {
    if (!_isConnected) return;

    // Simulate message sent
    Future.delayed(const Duration(milliseconds: 100), () {
      final mockMessage = ChatMessage(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        roomId: roomId,
        userId: 'current_user_id',
        username: 'You',
        avatar: '',
        message: message,
        type: 'message',
        videoTimestamp: videoTimestamp,
        reactions: [],
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _newMessageController.add(mockMessage);
    });
  }

  void addReaction(String messageId, String emoji) {
    if (!_isConnected) return;
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _reactionUpdatedController.add({
        'messageId': messageId,
        'reactions': [
          {
            'userId': 'current_user_id',
            'emoji': emoji,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
      });
    });
  }

  // Disconnect
  void disconnect() {
    if (_socket != null) {
      _socket!.close();
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