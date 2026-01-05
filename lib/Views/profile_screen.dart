// Màn hình hiển thị hồ sơ người dùng, cài đặt và tùy chọn tài khoản.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Components/bottom_navbar.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme_provider.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'search_screen.dart';
import 'watch_rooms_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentIndex = 4;
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Widget destination;
      switch (index) {
        case 1:
          destination = const SearchScreen();
          break;
        case 2:
          destination = const BookmarkScreen();
          break;
        case 3:
          destination = const WatchRoomsScreen();
          break;
        default:
          return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      AppSnackBar.showSuccess(context, 'Đã đăng xuất thành công!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_user?.avatar == null || _user!.avatar!.isEmpty) {
      return null;
    }

    final avatar = _user!.avatar!;
    if (avatar.startsWith('data:image')) {
      try {
        final base64Data = avatar.split(',').last;
        return MemoryImage(base64Decode(base64Data));
      } catch (e) {
        return null;
      }
    } else {
      return NetworkImage(avatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E13) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hồ sơ',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: const SizedBox(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF5BA3F5),
                    backgroundImage: _getAvatarImage(),
                    child: _user?.avatar == null || _user!.avatar!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?.name ?? 'Tên người dùng',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user?.email ?? 'user@example.com',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: 'Chỉnh sửa hồ sơ',
                    onTap: () {
                      if (_user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              user: _user!,
                              onProfileUpdated: _loadUser,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.download_outlined,
                    title: 'Tải xuống',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.security_outlined,
                    title: 'Bảo mật',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.language_outlined,
                    title: 'Ngôn ngữ',
                    subtitle: 'Tiếng Việt',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.dark_mode_outlined,
                    title: 'Chế độ tối',
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      activeTrackColor: const Color(0xFF5BA3F5),
                    ),
                  ),
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Trợ giúp',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Chính sách bảo mật',
                    onTap: () {},
                  ),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Đăng xuất',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: _logout,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Phiên bản 1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isDark ? Colors.white : Colors.black),
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey))
          : null,
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}
