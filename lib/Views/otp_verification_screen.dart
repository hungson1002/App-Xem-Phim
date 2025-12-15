import 'package:flutter/material.dart';

import '../Components/custom_button.dart';
import '../Components/custom_text_field.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  void _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _authService.verifyEmail(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      // Show success message and navigate to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận email thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage =
            response.message ?? 'Mã OTP không hợp lệ hoặc đã hết hạn';
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
                      minHeight: constraints.maxHeight - 48, // Trừ padding
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
                                Icons.email_outlined,
                                size: 40,
                                color: Color(0xFF5BA3F5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Title
                          const Center(
                            child: Text(
                              'Xác nhận Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle
                          Center(
                            child: Text(
                              'Chúng tôi đã gửi mã OTP đến\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // OTP Field
                          CustomTextField(
                            label: 'Mã OTP',
                            hint: 'Nhập mã 6 số',
                            icon: Icons.lock_outline,
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            errorText: _errorMessage,
                          ),

                          const SizedBox(height: 32),

                          // Verify Button
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF5BA3F5),
                                  ),
                                )
                              : CustomButton(
                                  text: 'Xác nhận',
                                  onPressed: _verifyOtp,
                                  backgroundColor: const Color(0xFF5BA3F5),
                                ),

                          const SizedBox(height: 24),

                          // Resend OTP
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // TODO: Implement resend OTP
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tính năng gửi lại OTP sẽ được cập nhật sau',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Gửi lại mã OTP',
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
    _otpController.dispose();
    super.dispose();
  }
}
