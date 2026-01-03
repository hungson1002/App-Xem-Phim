import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_room_provider.dart';
import '../models/chat_message_model.dart';
import '../services/auth_service.dart';

class WatchRoomChat extends StatefulWidget {
  const WatchRoomChat({super.key});

  @override
  State<WatchRoomChat> createState() => _WatchRoomChatState();
}

class _WatchRoomChatState extends State<WatchRoomChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();
  String? _currentUserId;

  String? _lastMessageId;
  ChatMessage? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= 100 && // Near top threshold
        !_scrollController.position.outOfRange) {
      final provider = Provider.of<WatchRoomProvider>(context, listen: false);
      if (provider.hasMoreChatHistory && !provider.isLoadingMoreChat) {
        _loadMoreMessages(provider);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getUser();
    setState(() {
      _currentUserId = user?.id;
    });
  }

  Future<void> _loadMoreMessages(WatchRoomProvider provider) async {
    final oldMaxScroll = _scrollController.position.maxScrollExtent;

    await provider.loadChatHistory(
      provider.currentRoom!.roomId,
      page: provider.chatPage + 1,
    );

    // Maintain scroll position is tricky with ListView normal order (top is 0).
    // When items inserted at top (index 0), current items shift down.
    // The scroll offset 0 stays 0, showing new items.
    // We want to jump to (new items height).
    // newItemsHeight approx = newMaxScroll - oldMaxScroll.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final newMaxScroll = _scrollController.position.maxScrollExtent;
        final diff = newMaxScroll - oldMaxScroll;
        if (diff > 0) {
          // Jump to offset = diff to keep viewing the same item as before
          _scrollController.jumpTo(_scrollController.offset + diff);
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final provider = Provider.of<WatchRoomProvider>(context, listen: false);

    ChatReply? replyTo;
    if (_replyToMessage != null) {
      replyTo = ChatReply(
        messageId: _replyToMessage!.id,
        username: _replyToMessage!.username,
        message: _replyToMessage!.message,
      );
    }

    provider.sendMessage(message, replyTo: replyTo);
    _messageController.clear();

    if (_replyToMessage != null) {
      setState(() {
        _replyToMessage = null;
      });
    }
    // Scroll triggers automatically via listener
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<WatchRoomProvider>(
      builder: (context, provider, child) {
        // Filter out system messages for UI
        final visibleMessages = provider.messages
            .where((m) => !m.isSystemMessage)
            .toList();

        // Auto scroll on new message (monitor raw messages for updates)
        if (provider.messages.isNotEmpty) {
          final lastMsg = provider.messages.last;
          if (lastMsg.id != _lastMessageId) {
            _lastMessageId = lastMsg.id;
            _scrollToBottom();
          }
        }

        final room = provider.currentRoom;
        if (room == null) {
          return const Center(child: Text('Không có phòng'));
        }

        if (!room.settings.allowChat) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Chat đã bị tắt', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
          ),
          child: Column(
            children: [
              // Chat header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Chat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${visibleMessages.length} tin nhắn',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Messages list
              Expanded(
                child: visibleMessages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có tin nhắn nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hãy bắt đầu cuộc trò chuyện!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: visibleMessages.length,
                        itemBuilder: (context, index) {
                          final message = visibleMessages[index];
                          return _buildMessageItem(message, provider);
                        },
                      ),
              ),

              // Message input
              _buildMessageInput(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message, WatchRoomProvider provider) {
    final isCurrentUser = message.userId == _currentUserId;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundImage: _getAvatarImage(message, provider),
            child: _getAvatarImage(message, provider) == null
                ? Text(
                    message.username.isNotEmpty
                        ? message.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),

          const SizedBox(width: 8),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply Context (if any)
                if (message.replyTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[400]!, width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.replyTo!.username,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          message.replyTo!.message,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                // Username and timestamp
                Row(
                  children: [
                    Text(
                      message.username,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? Colors.blue : null,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      _formatMessageTime(message.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),

                    if (message.videoTimestamp > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatTime(message.videoTimestamp),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 2),

                // Message text
                Text(message.message, style: const TextStyle(fontSize: 14)),

                // Reactions
                if (message.reactions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: _buildReactions(message, provider),
                    ),
                  ),

                // Like Icon Button (Quick Reaction)
                GestureDetector(
                  onTap: () => _showReactionPicker(message, provider),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message actions (Menu)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16),
            onSelected: (value) {
              switch (value) {
                case 'reply':
                  setState(() {
                    _replyToMessage = message;
                  });
                  _focusNode.requestFocus();
                  break;
                case 'copy':
                  // TODO: Implement copy
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reply',
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 16),
                    SizedBox(width: 8),
                    Text('Trả lời'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 8),
                    Text('Sao chép'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReactions(
    ChatMessage message,
    WatchRoomProvider provider,
  ) {
    final reactionCounts = <String, int>{};
    final userReactions = <String, bool>{};

    for (final reaction in message.reactions) {
      reactionCounts[reaction.emoji] =
          (reactionCounts[reaction.emoji] ?? 0) + 1;
      if (reaction.userId == _currentUserId) {
        userReactions[reaction.emoji] = true;
      }
    }

    return reactionCounts.entries.map((entry) {
      final emoji = entry.key;
      final count = entry.value;
      final isUserReacted = userReactions[emoji] ?? false;

      return GestureDetector(
        onTap: () {
          provider.addReaction(message.id, emoji);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isUserReacted
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: isUserReacted
                ? Border.all(color: Colors.blue, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              if (count > 1) ...[
                const SizedBox(width: 2),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUserReacted ? Colors.blue : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Column(
        children: [
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang trả lời ${_replyToMessage!.username}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          _replyToMessage!.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _replyToMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    //enableIMEPersonalizedLearning: false,
                    //autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[700] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(ChatMessage message, WatchRoomProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn cảm xúc',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: ['😀', '😂', '😍', '😢', '😡', '👍', '👎', '❤️']
                  .map(
                    (emoji) => GestureDetector(
                      onTap: () {
                        provider.addReaction(message.id, emoji);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}p';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  ImageProvider? _getAvatarImage(
    ChatMessage message,
    WatchRoomProvider provider,
  ) {
    // Try to get avatar from user cache first
    final cachedUser = provider.userCache[message.userId];
    if (cachedUser != null &&
        cachedUser.avatar != null &&
        cachedUser.avatar!.isNotEmpty) {
      return NetworkImage(cachedUser.avatar!);
    }

    // Fall back to avatar from message
    if (message.avatar.isNotEmpty) {
      return NetworkImage(message.avatar);
    }

    return null;
  }

  String _formatTime(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
