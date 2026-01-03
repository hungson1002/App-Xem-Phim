import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/watch_room_provider.dart';
import '../Components/watchroom_video_player.dart';
import '../Components/watchroom_chat.dart';
import '../Components/watch_room_users.dart';
import '../services/auth_service.dart';

class WatchRoomScreen extends StatefulWidget {
  final String roomId;
  final String? password;

  const WatchRoomScreen({super.key, required this.roomId, this.password});

  @override
  State<WatchRoomScreen> createState() => _WatchRoomScreenState();
}

class _WatchRoomScreenState extends State<WatchRoomScreen> {
  bool _showChat = true;
  bool _showUsers = false;
  WatchRoomProvider? _provider;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WatchRoomProvider>(context, listen: false);
      provider.joinRoom(widget.roomId, password: widget.password);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store provider reference safely for use in dispose()
    _provider = Provider.of<WatchRoomProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // Use stored reference instead of looking up provider
    // Call leaveRoom silently to avoid triggering rebuilds during dispose
    _provider?.leaveRoom(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final provider = Provider.of<WatchRoomProvider>(context, listen: false);
        final user = await _authService.getUser();

        // Check if current user is host
        if (user != null && provider.isHost(user.id)) {
          final shouldPop = await _showHostLeaveDialog(context, provider);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // Regular user - just leave
          provider.leaveRoom();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0B0E13)
            : const Color(0xFFF5F5F5),
        body: Consumer<WatchRoomProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tham gia phòng...'),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              );
            }

            if (provider.currentRoom == null) {
              return const Center(child: Text('Không tìm thấy phòng'));
            }

            return SafeArea(
              child: Column(
                children: [
                  // App bar
                  _buildAppBar(provider),

                  // Video player
                  Expanded(
                    flex: _showChat ? 3 : 4,
                    child: const WatchRoomVideoPlayer(),
                  ),

                  // Bottom section
                  if (_showChat || _showUsers)
                    Expanded(
                      flex: 2,
                      child: _showUsers
                          ? const WatchRoomUsers()
                          : const WatchRoomChat(),
                    ),

                  // Controls
                  _buildControls(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(WatchRoomProvider provider) {
    final room = provider.currentRoom!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${room.userCount} người đang xem',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Connection status
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: provider.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 8),

          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sync':
                  provider.requestSync();
                  break;
                case 'settings':
                  _showRoomSettings(provider);
                  break;
                case 'leave':
                  Navigator.pop(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Đồng bộ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Cài đặt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app),
                    SizedBox(width: 8),
                    Text('Rời phòng'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(WatchRoomProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Chat toggle
          IconButton(
            icon: Icon(
              _showChat ? Icons.chat : Icons.chat_outlined,
              color: _showChat ? Colors.blue : null,
            ),
            onPressed: () {
              setState(() {
                _showChat = !_showChat;
                if (_showChat) _showUsers = false;
              });
            },
          ),

          // Users toggle
          IconButton(
            icon: Icon(
              _showUsers ? Icons.people : Icons.people_outlined,
              color: _showUsers ? Colors.blue : null,
            ),
            onPressed: () {
              setState(() {
                _showUsers = !_showUsers;
                if (_showUsers) _showChat = false;
              });
            },
          ),

          // Sync button
          IconButton(
            icon: provider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: provider.isSyncing ? null : provider.requestSync,
          ),

          // Fullscreen toggle
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              // Toggle fullscreen
              setState(() {
                _showChat = false;
                _showUsers = false;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showRoomSettings(WatchRoomProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cài đặt phòng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Cho phép chat'),
              trailing: Switch(
                value: provider.currentRoom?.settings.allowChat ?? true,
                onChanged: (value) {
                  provider.updateRoomSettings(settings: {'allowChat': value});
                  Navigator.pop(context);
                },
              ),
            ),

            ListTile(
              leading: const Icon(Icons.control_camera),
              title: const Text('Cho phép user điều khiển'),
              trailing: Switch(
                value: provider.currentRoom?.settings.allowUserControl ?? false,
                onChanged: (value) {
                  provider.updateRoomSettings(
                    settings: {'allowUserControl': value},
                  );
                  Navigator.pop(context);
                },
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showHostLeaveDialog(
    BuildContext context,
    WatchRoomProvider provider,
  ) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bạn là Host'),
        content: const Text('Bạn muốn làm gì với phòng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Tiếp tục phát'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa phòng'),
          ),
        ],
      ),
    );

    if (result == 'delete') {
      await provider.deleteRoom();
      return true; // Allow navigation
    } else if (result == 'continue') {
      provider.leaveRoom();
      return true; // Allow navigation
    } else {
      return false; // Cancel navigation
    }
  }
}
