import 'package:flutter/material.dart';

class CommentSection extends StatefulWidget {
  const CommentSection({super.key});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, String>> _comments = [
    {
      'name': 'Nguyễn Văn A',
      'time': '2 giờ trước',
      'comment': 'Phim rất hay, cảnh chiến đấu đẹp mắt, cốt truyện cuốn hút!',
      'avatar': 'https://i.pravatar.cc/150?img=15',
    },
    {
      'name': 'Trần Thị B',
      'time': '5 giờ trước',
      'comment': 'Kết thúc hoàn hảo cho chuỗi phim Avengers. Đáng xem!',
      'avatar': 'https://i.pravatar.cc/150?img=16',
    },
    {
      'name': 'Phạm Văn C',
      'time': '1 ngày trước',
      'comment': 'Hiệu ứng CGI tuyệt vời, dàn diễn viên đỉnh cao!',
      'avatar': 'https://i.pravatar.cc/150?img=17',
    },
  ];

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _comments.insert(0, {
        'name': 'Tên người dùng',
        'time': 'Vừa xong',
        'comment': _commentController.text.trim(),
        'avatar': 'https://i.pravatar.cc/150?img=12',
      });
      _commentController.clear();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bình luận',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'XEM TẤT CẢ',
                style: TextStyle(
                  color: Color(0xFF5BA3F5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Comments List
        ...(_comments.map((comment) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildComment(
                isDark: isDark,
                name: comment['name']!,
                time: comment['time']!,
                comment: comment['comment']!,
                avatar: comment['avatar']!,
              ),
            ))),

        // Add Comment Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2332) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Viết bình luận...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey : Colors.black45,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Color(0xFF5BA3F5),
                ),
                onPressed: _addComment,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComment({
    required bool isDark,
    required String name,
    required String time,
    required String comment,
    required String avatar,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.favorite_border,
                  color: isDark ? Colors.grey : Colors.black54,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
