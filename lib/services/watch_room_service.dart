import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/watch_room_model.dart';
import 'api_config.dart';

/// Service for WatchRoom HTTP API calls
class WatchRoomService {
  /// Get auth token from storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  /// Get auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Create a new watch room
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

  /// Get all active watch rooms
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

      print('Get rooms failed: ${response.body}');
      return [];
    } catch (e) {
      print('Get rooms error: $e');
      return [];
    }
  }

  /// Get room by code
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

      print('Get room failed: ${response.body}');
      return null;
    } catch (e) {
      print('Get room error: $e');
      return null;
    }
  }

  /// Join a room
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

      print('Join room failed: ${response.body}');
      return null;
    } catch (e) {
      print('Join room error: $e');
      return null;
    }
  }

  /// Leave a room
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

      print('Leave room failed: ${response.body}');
      return false;
    } catch (e) {
      print('Leave room error: $e');
      return false;
    }
  }

  /// Close a room (host only)
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

      print('Close room failed: ${response.body}');
      return false;
    } catch (e) {
      print('Close room error: $e');
      return false;
    }
  }
}
