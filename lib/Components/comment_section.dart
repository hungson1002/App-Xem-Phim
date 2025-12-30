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
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getUser();
      final comments = await _commentService.getComments(widget.movieId);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print("Lỗi tải dữ liệu: $e");
      }
    }
  }

  // --- HÀM THÊM BÌNH LUẬN ---
  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để bình luận'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    FocusScope.of(context).unfocus();

    try {
      final newComment = await _commentService.addComment(widget.movieId, content);

      if (!mounted) return;
      setState(() => _isSending = false);

      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment);
          _commentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi bình luận!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi thất bại.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- HÀM HIỆN HỘP THOẠI SỬA (MỚI) ---
  void _showEditDialog(Comment comment) {
    final editController = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa bình luận'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Nhập nội dung mới...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;
              Navigator.pop(context); // Đóng dialog

              // Gọi Service
              final success = await _commentService.updateComment(
                  widget.movieId, comment.id!, editController.text.trim());

              if (success && mounted) {
                setState(() {
                  // Cập nhật UI ngay lập tức
                  comment.content = editController.text.trim();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật!')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lỗi khi sửa!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // --- HÀM XÁC NHẬN XÓA (MỚI) ---
  void _confirmDelete(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bình luận này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Đóng dialog

              // Gọi Service
              final success = await _commentService.deleteComment(widget.movieId, comment.id!);

              if (success && mounted) {
                setState(() {
                  _comments.remove(comment); // Xóa khỏi danh sách trên màn hình
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa bình luận!')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lỗi khi xóa!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

        // List Comments
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

        // Input Box
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

  // --- WIDGET HIỂN THỊ 1 DÒNG BÌNH LUẬN (ĐÃ UPDATE) ---
  Widget _buildComment({
    required bool isDark,
    required Comment comment,
  }) {
    // 1. Kiểm tra quyền sở hữu
    // So sánh ID user đang đăng nhập và ID user của comment
    final bool isOwner = _currentUser != null &&
        comment.user != null &&
        _currentUser!.id == comment.user!.id;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
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

              // Nội dung + Tên + Menu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hàng chứa Tên và Nút 3 chấm
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment.user?.name ?? 'Người dùng',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // CHỈ HIỆN NÚT 3 CHẤM NẾU LÀ CHÍNH CHỦ
                        if (isOwner)
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.more_vert, size: 18, color: isDark ? Colors.white54 : Colors.grey),
                              onSelected: (value) {
                                if (value == 'edit') _showEditDialog(comment);
                                if (value == 'delete') _confirmDelete(comment);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Sửa')]),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Xóa', style: TextStyle(color: Colors.red))]),
                                ),
                              ],
                            ),
                          ),
                      ],
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