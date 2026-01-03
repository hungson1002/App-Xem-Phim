import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_room_provider.dart';
import '../models/watch_room_model.dart';
import '../services/auth_service.dart';

class WatchRoomUsers extends StatefulWidget {
  const WatchRoomUsers({super.key});

  @override
  State<WatchRoomUsers> createState() => _WatchRoomUsersState();
}

class _WatchRoomUsersState extends State<WatchRoomUsers> {
  final AuthService _authService = AuthService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getUser();
    setState(() {
      _currentUserId = user?.id;
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

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Users section
                Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 2,
                  child: Column(
                    children: [
                      // Users header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people, size: 12),
                            const SizedBox(width: 8),
                            const Text(
                              'Người xem',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '${room.currentUsers.length}/${room.maxUsers}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Users list
                      room.currentUsers.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Chưa có ai trong phòng',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8),
                              itemCount: room.currentUsers.length,
                              itemBuilder: (context, index) {
                                final user = room.currentUsers[index];
                                return _buildUserItem(user, room, provider);
                              },
                            ),
                    ],
                  ),
                ),

                // Room info section
                Card(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  elevation: 2,
                  child: _buildRoomInfo(room, isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserItem(
    RoomUser user,
    WatchRoom room,
    WatchRoomProvider provider,
  ) {
    final isCurrentUser = user.userId == _currentUserId;
    final isHost = user.isHost;
    final canManage =
        _currentUserId != null &&
        room.isHost(_currentUserId!) &&
        !isCurrentUser;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: user.avatar.isNotEmpty
                  ? NetworkImage(user.avatar)
                  : null,
              child: user.avatar.isEmpty
                  ? Text(
                      _getDisplayName(user).isNotEmpty
                          ? _getDisplayName(user)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 10),
                    )
                  : null,
            ),

            // Online indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                _getDisplayName(user),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrentUser
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCurrentUser ? Colors.blue : null,
                ),
              ),
            ),

            if (isHost)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Host',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (isCurrentUser)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bạn',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        subtitle: Text(
          'Tham gia ${_formatJoinTime(user.joinedAt)}',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),

        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'kick':
                      _showKickUserDialog(user, provider);
                      break;
                    case 'make_host':
                      _showMakeHostDialog(user, provider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'kick',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Kick khỏi phòng'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'make_host',
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text('Chuyển host'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildRoomInfo(WatchRoom room, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Thông tin phòng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 4),

          _buildInfoRow('Tên phòng', room.title),
          _buildInfoRow('Phim', room.movieInfo?.name ?? 'Unknown'),
          _buildInfoRow(
            'Trạng thái',
            room.status == 'active' ? 'Đang hoạt động' : 'Đã kết thúc',
          ),
          _buildInfoRow(
            'Loại phòng',
            room.isPrivate ? 'Riêng tư' : 'Công khai',
          ),

          if (room.description.isNotEmpty)
            _buildInfoRow('Mô tả', room.description),

          const SizedBox(height: 4),

          // Room settings
          Row(
            children: [
              _buildSettingChip('Chat', room.settings.allowChat, Colors.blue),

              const SizedBox(width: 8),

              _buildSettingChip(
                'User control',
                room.settings.allowUserControl,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingChip(String label, bool enabled, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? color.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: enabled ? color : Colors.grey,
          ),

          const SizedBox(width: 4),

          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: enabled ? color : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showKickUserDialog(RoomUser user, WatchRoomProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick người dùng'),
        content: Text('Bạn có chắc muốn kick ${user.username} khỏi phòng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),

          TextButton(
            onPressed: () {
              // TODO: Implement kick user
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã kick ${user.username}')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kick'),
          ),
        ],
      ),
    );
  }

  void _showMakeHostDialog(RoomUser user, WatchRoomProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuyển host'),
        content: Text(
          'Bạn có chắc muốn chuyển quyền host cho ${user.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),

          TextButton(
            onPressed: () {
              // TODO: Implement transfer host
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã chuyển host cho ${user.username}')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Chuyển'),
          ),
        ],
      ),
    );
  }

  String _formatJoinTime(DateTime joinTime) {
    final now = DateTime.now();
    final difference = now.difference(joinTime);

    if (difference.inMinutes < 1) {
      return 'vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  String _getDisplayName(RoomUser user) {
    if (user.username.isNotEmpty) {
      return user.username;
    }
    // Fallback to userId if username is empty
    if (user.userId.isNotEmpty) {
      return 'User ${user.userId.substring(0, user.userId.length > 8 ? 8 : user.userId.length)}';
    }
    return 'Unknown User';
  }
}
