import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../widgets/app_toast.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final ValueChanged<String>? onPasswordReset;

  const ForgotPasswordDialog({
    super.key,
    this.initialEmail = '',
    this.onPasswordReset,
  });

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final ApiService _apiService = ApiService();
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _step = 1; // 1 = Enter Email, 2 = Enter OTP + New Password
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final msg = await _apiService.requestPasswordReset(email);
      if (mounted) {
        setState(() {
          _loading = false;
          _step = 2;
          _success = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _submitNewPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text;

    if (otp.length < 6) {
      setState(() => _error = 'Please enter the 6-digit OTP code.');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await _apiService.resetPasswordWithOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      if (mounted) {
        widget.onPasswordReset?.call(email);
        Navigator.of(context).pop();
        AppToast.show(context, 'Password reset successful');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF18181B);
    final textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final inputBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🐾 ', style: TextStyle(fontSize: 18)),
                    Text(
                      _step == 1 ? 'Forgot Password' : 'Reset Password',
                      style: TextStyle(
                        fontFamily: 'Sniglet',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, size: 20, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _step == 1
                  ? 'Enter your email to receive a 6-digit OTP code and reset link.'
                  : 'Check your email for the 6-digit code and set your new password.',
              style: TextStyle(fontFamily: 'Sniglet', fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontFamily: 'Sniglet', fontSize: 12, color: Color(0xFFEF4444)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _success!,
                  style: const TextStyle(fontFamily: 'Sniglet', fontSize: 12, color: Color(0xFF16A34A)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_step == 1) ...[
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontFamily: 'Sniglet', color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    icon: Icon(Icons.mail_outline, size: 18, color: textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loading ? null : _requestOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF18181B),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Send Reset Code',
                        style: TextStyle(fontFamily: 'Sniglet', fontWeight: FontWeight.bold),
                      ),
              ),
            ] else ...[
              // OTP field
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Sniglet',
                    color: textPrimary,
                    fontSize: 20,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '123456',
                    hintStyle: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 18, letterSpacing: 4),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // New Password
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(fontFamily: 'Sniglet', color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'New password (min 6 chars)',
                    hintStyle: TextStyle(fontFamily: 'Sniglet', color: textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    icon: Icon(Icons.lock_outline, size: 18, color: textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _loading ? null : _submitNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF18181B),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Update Password',
                        style: TextStyle(fontFamily: 'Sniglet', fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: Text(
                  '← Change Email',
                  style: TextStyle(fontFamily: 'Sniglet', fontSize: 12, color: textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
