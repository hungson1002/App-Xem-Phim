import 'package:flutter/material.dart';

import '../Components/custom_button.dart';
import '../Components/custom_text_field.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  void _sendOtp() async {
    // Validate input
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
        _successMessage = null;
      });
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Email không hợp lệ';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final response = await _authService.forgotPassword(
      email: _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      // Navigate to reset password screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordScreen(email: _emailController.text.trim()),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Không thể gửi mã OTP';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1419) : Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1598899134739-24c46f58b8c0?w=800',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(isDark ? 0.7 : 0.5),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Back Button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),

                          const SizedBox(height: 40),

                          // Icon
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5BA3F5).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                size: 40,
                                color: Color(0xFF5BA3F5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Title
                          const Center(
                            child: Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle
                          const Center(
                            child: Text(
                              'Nhập email của bạn để nhận\nmã OTP đặt lại mật khẩu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Error Message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Success Message
                          if (_successMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _successMessage!,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Email Field
                          CustomTextField(
                            label: 'Email',
                            hint: 'Nhập email của bạn',
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 32),

                          // Send OTP Button
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF5BA3F5),
                                  ),
                                )
                              : CustomButton(
                                  text: 'Gửi mã OTP',
                                  onPressed: _sendOtp,
                                  backgroundColor: const Color(0xFF5BA3F5),
                                ),

                          const Spacer(),

                          // Back to Login
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Quay lại đăng nhập',
                                style: TextStyle(
                                  color: Color(0xFF5BA3F5),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
