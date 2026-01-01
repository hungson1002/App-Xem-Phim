class WatchRoom {
  final String id;
  final String roomId;
  final String movieId;
  final String episodeSlug;
  final String hostId;
  final String title;
  final String description;
  final bool isPrivate;
  final String? password;
  final int maxUsers;
  final List<RoomUser> currentUsers;
  final VideoState videoState;
  final RoomSettings settings;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MovieInfo? movieInfo;
  final EpisodeInfo? episodeInfo;

  WatchRoom({
    required this.id,
    required this.roomId,
    required this.movieId,
    required this.episodeSlug,
    required this.hostId,
    required this.title,
    required this.description,
    required this.isPrivate,
    this.password,
    required this.maxUsers,
    required this.currentUsers,
    required this.videoState,
    required this.settings,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.movieInfo,
    this.episodeInfo,
  });

  factory WatchRoom.fromJson(Map<String, dynamic> json) {
    // Helper to extract ID from String or Object or Null
    String getId(dynamic val) {
      if (val == null) return '';
      if (val is String) return val;
      if (val is Map) return val['_id'] ?? '';
      return '';
    }

    return WatchRoom(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      movieId: getId(json['movieId']),
      episodeSlug: json['episodeSlug'] ?? '',
      hostId: getId(json['hostId']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isPrivate: json['isPrivate'] ?? false,
      password: json['password'],
      maxUsers: json['maxUsers'] ?? 50,
      currentUsers: (json['currentUsers'] as List<dynamic>?)
          ?.map((user) => RoomUser.fromJson(user))
          .toList() ?? [],
      videoState: VideoState.fromJson(json['videoState'] ?? {}),
      settings: RoomSettings.fromJson(json['settings'] ?? {}),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      movieInfo: json['movieId'] is Map ? MovieInfo.fromJson(json['movieId']) : null,
      episodeInfo: json['episode'] != null ? EpisodeInfo.fromJson(json['episode']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'movieId': movieId,
      'episodeSlug': episodeSlug,
      'hostId': hostId,
      'title': title,
      'description': description,
      'isPrivate': isPrivate,
      'password': password,
      'maxUsers': maxUsers,
      'currentUsers': currentUsers.map((user) => user.toJson()).toList(),
      'videoState': videoState.toJson(),
      'settings': settings.toJson(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  int get userCount => currentUsers.length;
  
  bool get isFull => currentUsers.length >= maxUsers;
  
  bool isHost(String userId) => hostId == userId;
  
  bool hasUser(String userId) => currentUsers.any((user) => user.userId == userId);
}

class RoomUser {
  final String userId;
  final String username;
  final String avatar;
  final DateTime joinedAt;
  final bool isHost;

  RoomUser({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.joinedAt,
    required this.isHost,
  });

  factory RoomUser.fromJson(Map<String, dynamic> json) {
    // Handle userId which can be String, Object with _id, or null
    String userId = '';
    if (json['userId'] != null) {
      if (json['userId'] is String) {
        userId = json['userId'];
      } else if (json['userId'] is Map && json['userId']['_id'] != null) {
        userId = json['userId']['_id'];
      }
    }
    
    return RoomUser(
      userId: userId,
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      isHost: json['isHost'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'joinedAt': joinedAt.toIso8601String(),
      'isHost': isHost,
    };
  }
}

class VideoState {
  final double currentTime;
  final bool isPlaying;
  final DateTime lastUpdated;
  final String? updatedBy;

  VideoState({
    required this.currentTime,
    required this.isPlaying,
    required this.lastUpdated,
    this.updatedBy,
  });

  factory VideoState.fromJson(Map<String, dynamic> json) {
    return VideoState(
      currentTime: (json['currentTime'] ?? 0).toDouble(),
      isPlaying: json['isPlaying'] ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      updatedBy: json['updatedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTime': currentTime,
      'isPlaying': isPlaying,
      'lastUpdated': lastUpdated.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }
}

class RoomSettings {
  final bool allowChat;
  final bool allowUserControl;
  final int syncTolerance;

  RoomSettings({
    required this.allowChat,
    required this.allowUserControl,
    required this.syncTolerance,
  });

  factory RoomSettings.fromJson(Map<String, dynamic> json) {
    return RoomSettings(
      allowChat: json['allowChat'] ?? true,
      allowUserControl: json['allowUserControl'] ?? false,
      syncTolerance: json['syncTolerance'] ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowChat': allowChat,
      'allowUserControl': allowUserControl,
      'syncTolerance': syncTolerance,
    };
  }
}

class MovieInfo {
  final String id;
  final String name;
  final String posterUrl;
  final String? originName;

  MovieInfo({
    required this.id,
    required this.name,
    required this.posterUrl,
    this.originName,
  });

  factory MovieInfo.fromJson(Map<String, dynamic> json) {
    return MovieInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      posterUrl: json['poster_url'] ?? '',
      originName: json['origin_name'],
    );
  }
}

class EpisodeInfo {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;
  final String linkM3u8;

  EpisodeInfo({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
    required this.linkM3u8,
  });

  factory EpisodeInfo.fromJson(Map<String, dynamic> json) {
    return EpisodeInfo(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      filename: json['filename'] ?? '',
      linkEmbed: json['link_embed'] ?? '',
      linkM3u8: json['link_m3u8'] ?? '',
    );
  }
}