import 'package:flutter/material.dart';

import '../Components/bottom_navbar.dart';
import '../models/user_model.dart';
// import '../models/watch_room_model.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/watch_room_service.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'watch_room_screen.dart';

// New Components
import '../Components/watch_room/join_room_section.dart';
import '../Components/watch_room/create_room_modal.dart';

class WatchRoomsScreen extends StatefulWidget {
  const WatchRoomsScreen({super.key});

  @override
  State<WatchRoomsScreen> createState() => _WatchRoomsScreenState();
}

class _WatchRoomsScreenState extends State<WatchRoomsScreen> {
  final WatchRoomService _watchRoomService = WatchRoomService();
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  bool _isLoading = false;
  User? _user;
  final int _currentNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _checkUser();
    _connectSocket();
  }

  Future<void> _checkUser() async {
    final user = await _authService.getUser();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  Future<void> _connectSocket() async {
    final token = await _authService.getToken();
    _socketService.connect(token: token);
  }

  void _onJoinRoom(String roomCode) async {
    if (_user == null) {
      AppSnackBar.showWarning(context, 'Vui lòng đăng nhập để tham gia');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final room = await _watchRoomService.joinRoom(roomCode);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (room != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WatchRoomScreen(room: room, isHost: room.hostId == _user!.id),
          ),
        );
      } else {
        AppSnackBar.showError(
          context,
          'Không tìm thấy phòng hoặc phòng đã đầy',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'Lỗi kết nối: $e');
      }
    }
  }

  void _showCreateRoomDialog() {
    if (_user == null) {
      AppSnackBar.showWarning(context, 'Vui lòng đăng nhập để tạo phòng');
      return;
    }

    CreateRoomModal.show(
      context,
      onCreate: (slug, name, poster) async {
        Navigator.pop(context); // Close modal
        await _createRoom(slug, name, poster);
      },
    );
  }

  Future<void> _createRoom(
    String movieSlug,
    String movieName,
    String? moviePoster,
  ) async {
    setState(() => _isLoading = true);

    final room = await _watchRoomService.createRoom(
      movieSlug: movieSlug,
      movieName: movieName,
      moviePoster: moviePoster,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (room != null) {
        AppSnackBar.showSuccess(context, 'Đã tạo phòng: ${room.roomCode}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WatchRoomScreen(room: room, isHost: true),
          ),
        );
      } else {
        AppSnackBar.showError(context, 'Không thể tạo phòng');
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentNavIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const SearchScreen();
        break;
      case 2:
        destination = const BookmarkScreen();
        break;
      case 3:
        return;
      case 4:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Xem chung',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF5BA3F5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.screen_share_rounded,
                  size: 64,
                  color: Color(0xFF5BA3F5),
                ),
              ),
              const SizedBox(height: 32),

              // Title & Subtitle
              Text(
                'Xem phim cùng bạn bè',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo phòng hoặc nhập mã để bắt đầu',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Join Room Section
              JoinRoomSection(onJoin: _onJoinRoom, isLoading: _isLoading),

              const SizedBox(height: 32),

              // Create Room Button
              TextButton.icon(
                onPressed: _showCreateRoomDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tạo phòng mới'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5BA3F5),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentNavIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
