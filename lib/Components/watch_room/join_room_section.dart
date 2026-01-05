// Component nhập mã phòng (6 ký tự) để tham gia phòng xem.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JoinRoomSection extends StatefulWidget {
  final Function(String) onJoin;
  final bool isLoading;

  const JoinRoomSection({
    super.key,
    required this.onJoin,
    this.isLoading = false,
  });

  @override
  State<JoinRoomSection> createState() => _JoinRoomSectionState();
}

class _JoinRoomSectionState extends State<JoinRoomSection> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Xây dựng giao diện nhập mã phòng và nút tham gia.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nhập mã phòng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 8),
              counterText: '',
              filled: true,
              fillColor: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              UpperCaseTextFormatter(),
            ],
            onSubmitted: (_) {
              if (_codeController.text.length == 6) {
                widget.onJoin(_codeController.text);
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      final code = _codeController.text.trim();
                      if (code.length == 6) {
                        widget.onJoin(code);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA3F5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'VÀO PHÒNG',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
