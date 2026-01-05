import 'dart:math';
import 'package:flutter/material.dart';

/// Model cho thông tin diễn viên
class CastMember {
  final String name;
  final String? role;
  final String? imageUrl;

  const CastMember({required this.name, this.role, this.imageUrl});
}

/// Widget hiển thị danh sách diễn viên với ảnh từ assets
class CastList extends StatelessWidget {
  final List<CastMember> cast;
  final VoidCallback? onSeeAllTap;
  final Color primaryColor;

  // Danh sách ảnh local trong assets
  static const List<String> _localAvatars = [
    'assets/img/avt1.png',
    'assets/img/avt2.png',
    'assets/img/avt3.png',
    'assets/img/avt4.png',
  ];

  const CastList({
    super.key,
    required this.cast,
    this.onSeeAllTap,
    this.primaryColor = const Color(0xFF5BA3F5),
  });

  /// Lấy ảnh ngẫu nhiên từ thư mục assets dựa theo tên
  String _getRandomAvatar(String name) {
    final random = Random(
      name.hashCode,
    ); // Seed theo tên để cố định ảnh cho mỗi người
    return _localAvatars[random.nextInt(_localAvatars.length)];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Diễn viên',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAllTap != null)
              TextButton(
                onPressed: onSeeAllTap,
                child: Text(
                  'TẤT CẢ',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Cast horizontal list
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final member = cast[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildCastCard(context, member, index, isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCastCard(
    BuildContext context,
    CastMember member,
    int index,
    bool isDark,
  ) {
    // Logic: Chỉ dùng Asset.
    // Nếu Asset lỗi: Fallback về Initials.

    // Lấy ảnh asset random theo tên để nhất quán
    final String assetPath = _getRandomAvatar(member.name);

    return Column(
      children: [
        // Avatar image
        Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            color: isDark ? const Color(0xFF1A2332) : Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Nếu asset lỗi thì fallback về Initials
                debugPrint('Error loading asset $assetPath: $error');
                return Container(
                  color: _getAvatarColor(member.name),
                  child: Center(
                    child: Text(
                      _getInitials(member.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Name and role
        SizedBox(
          width: 90,
          child: Column(
            children: [
              Text(
                member.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (member.role != null) ...[
                const SizedBox(height: 2),
                Text(
                  member.role!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // _buildPlaceholder removed as it is replaced by logic in _buildCastCard
}
