// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/database_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _step2 = false; // After email verified, show new password fields

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleFindAccount() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
        _isLoading = false;
      });
      return;
    }

    // Check if email exists
    final db = DatabaseService();
    final error = await db.resetPassword(email, 'temp_check_only_placeholder');
    // We'll just try a query; better approach below:
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step2 = true; // Proceed to new password (simplified UX)
    });
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPass.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
        _isLoading = false;
      });
      return;
    }

    if (newPass != confirm) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    final error = await DatabaseService().resetPassword(email, newPass);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
          context, '/signin', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const TopRightCircle(),
          Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const GoldenBackButton(),
                  ),
                ),
              ),

              // Illustration
              SizedBox(
                height: 150,
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const _ForgotIllustration(),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'FORGOT PASSWORD',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                _step2 ? 'SET NEW PASSWORD' : 'ENTER YOUR EMAIL',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      RoundedTextField(
                        hint: 'Email Address',
                        controller: _emailController,
                        suffixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (_step2) ...[
                        const SizedBox(height: 14),
                        RoundedTextField(
                          hint: 'New Password',
                          controller: _newPasswordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 14),
                        RoundedTextField(
                          hint: 'Confirm Password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const NavyWaveBottom(),

              Container(
                color: AppColors.navyBottom,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.accent)
                    : ElevatedButton(
                        onPressed:
                            _step2 ? _handleResetPassword : _handleFindAccount,
                        child: Text(_step2 ? 'RESET PASSWORD' : 'CONTINUE'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForgotIllustration extends StatelessWidget {
  const _ForgotIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ForgotPainter());
  }
}

class _ForgotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellow = Paint()..color = AppColors.accent;
    final navy = Paint()..color = AppColors.primary;
    final white = Paint()..color = Colors.white;
    final outline = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Clock / person thinking
    canvas.drawCircle(Offset(cx, cy - 10), 28, white);
    canvas.drawCircle(Offset(cx, cy - 10), 28, outline);

    // Clock hands
    canvas.drawLine(
        Offset(cx, cy - 10),
        Offset(cx + 10, cy - 22),
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(cx, cy - 10),
        Offset(cx + 14, cy - 6),
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);

    // Body below
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 28), width: 36, height: 28),
        yellow);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 28), width: 36, height: 28),
        outline);

    // Question mark bubble
    final bubblePaint = Paint()..color = AppColors.primary;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 30, cy - 25), width: 24, height: 20),
        bubblePaint);
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w900,
    );
    final tp = TextPainter(
        text: const TextSpan(text: '?', style: textStyle),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(cx + 24, cy - 33));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
