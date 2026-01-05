// Component hiển thị player trong phòng xem chung, bao gồm nút copy mã phòng và nút thoát.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/socket_service.dart';
import '../../utils/app_snackbar.dart';
import '../video_player/synced_video_player.dart';

class WatchRoomPlayer extends StatelessWidget {
  final String? videoUrl;
  final bool isHost;
  final String roomCode;
  final double initialTime;
  final SocketService socketService;
  final bool showSyncIndicator;
  final IconData syncIndicatorIcon;
  final VoidCallback onLeave;
  final Key playerKey;

  const WatchRoomPlayer({
    super.key,
    required this.videoUrl,
    required this.isHost,
    required this.roomCode,
    required this.initialTime,
    required this.socketService,
    required this.showSyncIndicator,
    required this.syncIndicatorIcon,
    required this.onLeave,
    required this.playerKey,
  });

  void _copyRoomCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: roomCode));
    AppSnackBar.showSuccess(context, 'Đã sao chép mã phòng: $roomCode');
  }

  // Xây dựng giao diện Player, Header mã phòng và các chỉ báo đồng bộ.
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          if (videoUrl != null)
            SyncedVideoPlayer(
              key: playerKey,
              videoUrl: videoUrl!,
              isHost: isHost,
              roomCode: roomCode,
              initialTime: initialTime,
              socketService: socketService,
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Không thể tải video',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          if (showSyncIndicator && !isHost)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(syncIndicatorIcon, color: Colors.white, size: 50),
              ),
            ),

          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              onPressed: onLeave,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => _copyRoomCode(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF5BA3F5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy, color: Color(0xFF5BA3F5), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      roomCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
