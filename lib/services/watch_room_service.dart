// Service xử lý API cho WatchRoom (Tạo, Lấy danh sách, Tham gia phòng).
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watch_room_model.dart';
import 'api_config.dart';

class WatchRoomService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<WatchRoom?> createRoom({
    required String movieSlug,
    required String movieName,
    String? moviePoster,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(ApiConfig.createWatchRoomUrl),
            headers: headers,
            body: jsonEncode({
              'movieSlug': movieSlug,
              'movieName': movieName,
              'moviePoster': moviePoster ?? '',
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return WatchRoom.fromJson(data['data']);
        }
      }

      print('Create room failed: ${response.body}');
      return null;
    } catch (e) {
      print('Create room error: $e');
      return null;
    }
  }

  Future<List<WatchRoom>> getRooms() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.getWatchRoomsUrl), headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((room) => WatchRoom.fromJson(room))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Get rooms error: $e');
      return [];
    }
  }

  Future<WatchRoom?> getRoom(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(ApiConfig.getWatchRoomUrl(code)), headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return WatchRoom.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('Get room error: $e');
      return null;
    }
  }

  Future<WatchRoom?> joinRoom(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse(ApiConfig.joinWatchRoomUrl(code)), headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return WatchRoom.fromJson(data['data']);
        }
      }

      return null;
    } catch (e) {
      print('Join room error: $e');
      return null;
    }
  }

  Future<bool> leaveRoom(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse(ApiConfig.leaveWatchRoomUrl(code)), headers: headers)
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Leave room error: $e');
      return false;
    }
  }

  Future<bool> closeRoom(String code) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse(ApiConfig.closeWatchRoomUrl(code)),
            headers: headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Close room error: $e');
      return false;
    }
  }
}
