// Màn hình chỉnh sửa thông tin cá nhân (Tên, Ảnh đại diện, Mật khẩu).
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_snackbar.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _selectedImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);

        setState(() {
          _selectedImage = file;
          _base64Image = 'data:image/jpeg;base64,$base64';
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi chọn ảnh: ${e.toString()}');
      }
    }
  }

  void _showImagePickerOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1F2A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chọn ảnh đại diện',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA3F5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF5BA3F5),
                  ),
                ),
                title: Text(
                  'Chọn từ thư viện',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA3F5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF5BA3F5)),
                ),
                title: Text(
                  'Chụp ảnh mới',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null || widget.user.avatar != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text(
                    'Xóa ảnh đại diện',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _base64Image = '';
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      AppSnackBar.showError(context, 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    final response = await _authService.updateProfile(
      userId: widget.user.id,
      name: _nameController.text.trim() != widget.user.name
          ? _nameController.text.trim()
          : null,
      avatar: _base64Image,
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
    );

    setState(() => _isLoading = false);

    if (response.success) {
      widget.onProfileUpdated();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Cập nhật hồ sơ thành công!');
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        AppSnackBar.showError(context, response.message ?? 'Có lỗi xảy ra');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E13) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatarSection(isDark),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Tên hiển thị',
                icon: Icons.person_outline,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[600])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Đổi mật khẩu',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _passwordController,
                label: 'Mật khẩu mới',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                obscure: _obscureConfirmPassword,
                onToggle: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BA3F5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(bool isDark) {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (widget.user.avatar != null && widget.user.avatar!.isNotEmpty) {
      if (widget.user.avatar!.startsWith('data:image')) {
        final base64Data = widget.user.avatar!.split(',').last;
        imageProvider = MemoryImage(base64Decode(base64Data));
      } else {
        imageProvider = NetworkImage(widget.user.avatar!);
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF5BA3F5),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA3F5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0B0E13) : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nhấn để đổi ảnh đại diện',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[500]),
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFF5BA3F5)),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1F2A) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF5BA3F5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5BA3F5)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1F2A) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF5BA3F5), width: 2),
        ),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && value.length < 6) {
          return 'Mật khẩu phải có ít nhất 6 ký tự';
        }
        return null;
      },
    );
  }
}
