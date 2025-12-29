import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/comment_service.dart';

class CommentSection extends StatefulWidget {
  final String movieId;

  const CommentSection({super.key, required this.movieId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();

  List<Comment> _comments = [];
  bool _isLoading = true;
  User? _currentUser;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getUser();
    final comments = await _commentService.getComments(widget.movieId);

    if (mounted) {
      setState(() {
        _currentUser = user;
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    // 1. Kiểm tra nội dung rỗng
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    // 2. Kiểm tra đăng nhập
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để bình luận'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Bắt đầu gửi -> Hiện loading
    setState(() => _isSending = true);
    FocusScope.of(context).unfocus(); // Ẩn bàn phím ngay lập tức cho mượt

    try {
      // Gọi Service
      final newComment = await _commentService.addComment(widget.movieId, content);

      if (!mounted) return; // Kiểm tra nếu màn hình đã đóng thì dừng lại

      setState(() => _isSending = false);

      if (newComment != null) {
        // --- THÀNH CÔNG ---
        setState(() {
          _comments.insert(0, newComment); // Thêm bình luận mới vào đầu danh sách
          _commentController.clear();      // Xóa ô nhập liệu
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi bình luận!'), backgroundColor: Colors.green),
        );
      } else {
        // --- THẤT BẠI (Do Server trả về null) ---
        // Đây là chỗ bạn đang bị dính lỗi màu đỏ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không gửi được. Hãy kiểm tra lại Đăng Nhập hoặc Kết Nối.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // --- LỖI KẾT NỐI (Mất mạng, Server sập) ---
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print("🔴 LỖI CHI TIẾT: $e");
      }
    }
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
              'Bình luận (${_comments.length})',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Comments List
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Chưa có bình luận nào. Hãy là người đầu tiên!',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildComment(
                  isDark: isDark,
                  comment: comment,
                ),
              );
            },
          ),

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
                backgroundImage: _currentUser?.avatar != null
                    ? NetworkImage(_currentUser!.avatar!)
                    : null,
                child: _currentUser?.avatar == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: _currentUser != null
                        ? 'Viết bình luận...'
                        : 'Đăng nhập để bình luận',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey : Colors.black45,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  enabled: _currentUser != null,
                ),
              ),
              const SizedBox(width: 8),
              if (_isSending)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFF5BA3F5),
                  ),
                  onPressed: _currentUser != null ? _addComment : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComment({
    required bool isDark,
    required Comment comment,
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
                backgroundImage: comment.user?.avatar != null
                    ? NetworkImage(comment.user!.avatar!)
                    : null,
                child: comment.user?.avatar == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user?.name ?? 'Người dùng',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.displayTime,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.content,
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
