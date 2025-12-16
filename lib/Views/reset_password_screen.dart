import 'dart:async';

import 'package:flutter/material.dart';

import '../Components/custom_button.dart';
import '../Components/custom_text_field.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  // Countdown timer for resend OTP
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final response = await _authService.forgotPassword(email: widget.email);

    setState(() {
      _isResending = false;
    });

    if (response.success) {
      _startResendCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã OTP!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Không thể gửi lại mã OTP';
      });
    }
  }

  void _resetPassword() async {
    // Validate OTP
    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã OTP';
      });
      return;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu mới';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      });
      return;
    }

    // Validate confirm password
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không khớp';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _authService.resetPassword(
      email: widget.email,
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt lại mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Đặt lại mật khẩu thất bại';
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),

                  const SizedBox(height: 32),

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
                        Icons.password,
                        size: 40,
                        color: Color(0xFF5BA3F5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Center(
                    child: Text(
                      'Đặt lại mật khẩu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Center(
                    child: Text(
                      'Nhập mã OTP đã gửi đến\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
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

                  // OTP Field
                  CustomTextField(
                    label: 'Mã OTP',
                    hint: 'Nhập mã 6 số',
                    icon: Icons.pin_outlined,
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 8),

                  // Resend OTP Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF5BA3F5),
                            ),
                          )
                        : TextButton(
                            onPressed: _resendCountdown > 0 ? null : _resendOtp,
                            child: Text(
                              _resendCountdown > 0
                                  ? 'Gửi lại sau ${_resendCountdown}s'
                                  : 'Gửi lại mã OTP',
                              style: TextStyle(
                                color: _resendCountdown > 0
                                    ? Colors.grey
                                    : const Color(0xFF5BA3F5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // New Password Field
                  CustomTextField(
                    label: 'Mật khẩu mới',
                    hint: 'Tối thiểu 6 ký tự',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password Field
                  CustomTextField(
                    label: 'Xác nhận mật khẩu',
                    hint: 'Nhập lại mật khẩu mới',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _confirmPasswordController,
                  ),

                  const SizedBox(height: 32),

                  // Reset Password Button
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF5BA3F5),
                          ),
                        )
                      : CustomButton(
                          text: 'Đặt lại mật khẩu',
                          onPressed: _resetPassword,
                          backgroundColor: const Color(0xFF5BA3F5),
                        ),

                  const SizedBox(height: 24),

                  // Back to Login
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
