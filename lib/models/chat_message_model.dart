class ChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String avatar;
  final String message;
  final String type;
  final double videoTimestamp;
  final List<MessageReaction> reactions;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.message,
    required this.type,
    required this.videoTimestamp,
    required this.reactions,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.replyTo,
  });

  final ChatReply? replyTo;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Safe userId extraction
    String userId = '';
    String username = '';
    String avatar = '';

    if (json['userId'] != null) {
      if (json['userId'] is String) {
        userId = json['userId'];
      } else if (json['userId'] is Map) {
        // userId is populated with user data
        final userMap = json['userId'] as Map<String, dynamic>;
        userId = userMap['_id'] ?? userMap['id'] ?? '';
        // Extract username and avatar from populated user data
        username = userMap['name'] ?? '';
        avatar = userMap['avatar'] ?? '';
      }
    }

    // Fallback to root level username and avatar if not found in populated userId
    if (username.isEmpty) {
      username = json['username'] ?? '';
    }
    if (avatar.isEmpty) {
      avatar = json['avatar'] ?? '';
    }

    return ChatMessage(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      userId: userId,
      username: username,
      avatar: avatar,
      message: json['message'] ?? '',
      type: json['type'] ?? 'message',
      videoTimestamp: (json['videoTimestamp'] ?? 0).toDouble(),
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((reaction) => MessageReaction.fromJson(reaction))
              .toList() ??
          [],
      replyTo: json['replyTo'] != null
          ? ChatReply.fromJson(json['replyTo'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'avatar': avatar,
      'message': message,
      'type': type,
      'videoTimestamp': videoTimestamp,
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
      'replyTo': replyTo?.toJson(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isSystemMessage => type == 'system';
  bool get isEmojiMessage => type == 'emoji';
  bool get isStickerMessage => type == 'sticker';

  int getReactionCount(String emoji) {
    return reactions.where((r) => r.emoji == emoji).length;
  }

  bool hasUserReacted(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }
}

class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime createdAt;

  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['userId'] is String
          ? json['userId']
          : json['userId']['_id'] ?? '',
      emoji: json['emoji'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ChatReply {
  final String messageId;
  final String username;
  final String message;

  ChatReply({
    required this.messageId,
    required this.username,
    required this.message,
  });

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    // Safe messageId extraction
    String messageId = '';
    if (json['messageId'] != null) {
      if (json['messageId'] is String) {
        messageId = json['messageId'];
      } else if (json['messageId'] is Map) {
        messageId = json['messageId']['_id'] ?? '';
      }
    }

    return ChatReply(
      messageId: messageId,
      username: json['username'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'messageId': messageId, 'username': username, 'message': message};
  }
}
