class WatchRoom {
  final String id;
  final String roomCode;
  final String movieSlug;
  final String movieName;
  final String moviePoster;
  final String hostId;
  final String hostName;
  final List<Participant> participants;
  final int maxParticipants;
  final bool isActive;
  final double currentTime;
  final bool isPlaying;
  final int currentServer;
  final int currentEpisode;
  final DateTime createdAt;

  WatchRoom({
    required this.id,
    required this.roomCode,
    required this.movieSlug,
    required this.movieName,
    required this.moviePoster,
    required this.hostId,
    required this.hostName,
    required this.participants,
    required this.maxParticipants,
    required this.isActive,
    required this.currentTime,
    required this.isPlaying,
    required this.currentServer,
    required this.currentEpisode,
    required this.createdAt,
  });

  factory WatchRoom.fromJson(Map<String, dynamic> json) {
    return WatchRoom(
      id: json['_id'] ?? '',
      roomCode: json['roomCode'] ?? '',
      movieSlug: json['movieSlug'] ?? '',
      movieName: json['movieName'] ?? '',
      moviePoster: json['moviePoster'] ?? '',
      hostId: json['host'] ?? '',
      hostName: json['hostName'] ?? '',
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map((p) => Participant.fromJson(p))
              .toList() ??
          [],
      maxParticipants: json['maxParticipants'] ?? 10,
      isActive: json['isActive'] ?? true,
      currentTime: (json['currentTime'] ?? 0).toDouble(),
      isPlaying: json['isPlaying'] ?? false,
      currentServer: json['currentServer'] ?? 0,
      currentEpisode: json['currentEpisode'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomCode': roomCode,
      'movieSlug': movieSlug,
      'movieName': movieName,
      'moviePoster': moviePoster,
      'host': hostId,
      'hostName': hostName,
      'participants': participants.map((p) => p.toJson()).toList(),
      'maxParticipants': maxParticipants,
      'isActive': isActive,
      'currentTime': currentTime,
      'isPlaying': isPlaying,
      'currentServer': currentServer,
      'currentEpisode': currentEpisode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get participantCount => participants.length;
  bool get isFull => participants.length >= maxParticipants;
}

class Participant {
  final String id;
  final String name;
  final String? avatar;
  final DateTime joinedAt;

  Participant({
    required this.id,
    required this.name,
    this.avatar,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['user'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': id,
      'name': name,
      'avatar': avatar,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

// Video sync state model
class VideoSyncState {
  final double currentTime;
  final bool isPlaying;
  final int currentServer;
  final int currentEpisode;
  final String? triggeredBy;

  VideoSyncState({
    required this.currentTime,
    required this.isPlaying,
    required this.currentServer,
    required this.currentEpisode,
    this.triggeredBy,
  });

  factory VideoSyncState.fromJson(Map<String, dynamic> json) {
    return VideoSyncState(
      currentTime: (json['currentTime'] ?? 0).toDouble(),
      isPlaying: json['isPlaying'] ?? false,
      currentServer: json['currentServer'] ?? 0,
      currentEpisode: json['currentEpisode'] ?? 0,
      triggeredBy: json['triggeredBy'],
    );
  }
}
