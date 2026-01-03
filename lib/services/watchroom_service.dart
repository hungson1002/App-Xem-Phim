import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/watch_room_model.dart';
import '../models/chat_message_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class WatchRoomService {
  static final WatchRoomService _instance = WatchRoomService._internal();
  factory WatchRoomService() => _instance;
  WatchRoomService._internal();

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Tạo phòng xem mới
  Future<Map<String, dynamic>> createWatchRoom({
    required String movieId,
    required String episodeSlug,
    required String title,
    String? description,
    bool isPrivate = false,
    String? password,
    int maxUsers = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'movieId': movieId,
        'episodeSlug': episodeSlug,
        'title': title,
        'description': description ?? '',
        'isPrivate': isPrivate,
        'password': password,
        'maxUsers': maxUsers,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/watch-rooms'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'room': WatchRoom.fromJson(data['data']['room']),
          'episode': data['data']['episode'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi tạo phòng xem',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Lấy danh sách phòng xem
  Future<Map<String, dynamic>> getWatchRooms({
    int page = 1,
    int limit = 20,
    String? movieId,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (movieId != null) queryParams['movieId'] = movieId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/watch-rooms',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final rooms = (data['data']['rooms'] as List)
            .map((room) => WatchRoom.fromJson(room))
            .toList();

        return {
          'success': true,
          'rooms': rooms,
          'pagination': data['data']['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi lấy danh sách phòng xem',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Lấy thông tin chi tiết phòng xem
  Future<Map<String, dynamic>> getWatchRoom(String roomId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/watch-rooms/$roomId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final roomData = data['data']['room'];
        final episodeData = data['data']['episode'];

        if (episodeData != null) {
          roomData['episode'] = episodeData;
        }

        return {
          'success': true,
          'room': WatchRoom.fromJson(roomData),
          'episode': episodeData,
          'userCount': data['data']['userCount'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi lấy thông tin phòng xem',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Cập nhật cài đặt phòng xem
  Future<Map<String, dynamic>> updateWatchRoom(
    String roomId, {
    String? title,
    String? description,
    int? maxUsers,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (maxUsers != null) body['maxUsers'] = maxUsers;
      if (settings != null) body['settings'] = settings;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/watch-rooms/$roomId'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'room': WatchRoom.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi cập nhật phòng xem',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Xóa phòng xem
  Future<Map<String, dynamic>> deleteWatchRoom(String roomId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/watch-rooms/$roomId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi xóa phòng xem',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Lấy lịch sử chat
  Future<Map<String, dynamic>> getChatHistory(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/watch-rooms/$roomId/chat',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final messages = (data['data']['messages'] as List)
            .map((message) {
              try {
                return ChatMessage.fromJson(message);
              } catch (e) {
                print('Error parsing message: $e');
                return null;
              }
            })
            .whereType<ChatMessage>()
            .toList();

        return {
          'success': true,
          'messages': messages,
          'pagination': data['data']['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi lấy lịch sử chat',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Lấy phòng xem của user hiện tại
  Future<Map<String, dynamic>> getMyRooms({
    String type = 'hosting', // hosting | joined
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {'type': type};

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/watch-rooms/my-rooms',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final rooms = (data['data']['rooms'] as List)
            .map((room) => WatchRoom.fromJson(room))
            .toList();

        return {'success': true, 'rooms': rooms};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi lấy phòng xem của bạn',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Lấy thông tin user theo ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['data'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Lấy danh sách users trong phòng
  Future<Map<String, dynamic>> getRoomUsers(String roomId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/watch-rooms/$roomId/users'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'users': data['data']['users'] ?? []};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi khi lấy danh sách users',
        };
      }
    } catch (e) {
      print('Error fetching room users: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
