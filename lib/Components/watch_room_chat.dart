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
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getUser();
    setState(() {
      _currentUserId = user?.id;
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final provider = Provider.of<WatchRoomProvider>(context, listen: false);
    provider.sendMessage(message);
    _messageController.clear();
    
    // Scroll to bottom
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<WatchRoomProvider>(
      builder: (context, provider, child) {
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
                Text(
                  'Chat đã bị tắt',
                  style: TextStyle(color: Colors.grey),
                ),
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
                      '${provider.messages.length} tin nhắn',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Messages list
              Expanded(
                child: provider.messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Chưa có tin nhắn nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Hãy bắt đầu cuộc trò chuyện!',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          final message = provider.messages[index];
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
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundImage: message.avatar.isNotEmpty
                ? NetworkImage(message.avatar)
                : null,
            child: message.avatar.isEmpty
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
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
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
                Text(
                  message.message,
                  style: const TextStyle(fontSize: 14),
                ),
                
                // Reactions
                if (message.reactions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: _buildReactions(message, provider),
                    ),
                  ),
              ],
            ),
          ),
          
          // Message actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16),
            onSelected: (value) {
              switch (value) {
                case 'react':
                  _showReactionPicker(message, provider);
                  break;
                case 'copy':
                  // Copy message
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'react',
                child: Row(
                  children: [
                    Icon(Icons.emoji_emotions, size: 16),
                    SizedBox(width: 8),
                    Text('Thả cảm xúc'),
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

  List<Widget> _buildReactions(ChatMessage message, WatchRoomProvider provider) {
    final reactionCounts = <String, int>{};
    final userReactions = <String, bool>{};
    
    for (final reaction in message.reactions) {
      reactionCounts[reaction.emoji] = (reactionCounts[reaction.emoji] ?? 0) + 1;
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
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
                  .map((emoji) => GestureDetector(
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
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ))
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

  String _formatTime(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}