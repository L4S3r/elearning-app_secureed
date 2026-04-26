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
  bool _step2 = false; 

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

    // Checking the Hardware-Backed database
    final users = await DatabaseService().getDecryptedUsersForAdmin();
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (users.containsKey(email.toLowerCase())) {
      setState(() => _step2 = true);
    } else {
      setState(() => _errorMessage = 'No account found with that email.');
    }
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

    // Cryptographic update: Decrypt -> Salt -> Hash -> Encrypt
    final error = await DatabaseService().resetPassword(email, newPass);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.primary),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          const TopRightCircle(),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
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
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.07),
                              shape: BoxShape.circle,
                            ),
                            child: _ForgotIllustration(), // Removed 'const'
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 15, bottom: 4),
                          child: Text('FORGOT PASSWORD', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24)),
                        ),
                        Text(
                          _step2 ? 'SECURE NEW PASSWORD' : 'FIND YOUR ACCOUNT',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 2),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                          ),
                        ],

                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              RoundedTextField(
                                hint: 'Email Address',
                                controller: _emailController,
                                suffixIcon: _step2 ? Icons.check_circle : Icons.email_outlined,
                                enabled: !_step2, // This works now!
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
                                  hint: 'Confirm New Password',
                                  controller: _confirmPasswordController,
                                  isPassword: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Spacer(), 
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            const NavyWaveBottom(),
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: AppColors.accent)
                                  : ElevatedButton(
                                      onPressed: _step2 ? _handleResetPassword : _handleFindAccount,
                                      child: Text(_step2 ? 'UPDATE PASSWORD' : 'CONTINUE'),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ForgotIllustration extends StatelessWidget {
  const _ForgotIllustration();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ForgotPainter());
}

class _ForgotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellow = Paint()..color = AppColors.accent;
    final white = Paint()..color = Colors.white;
    final outline = Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawCircle(Offset(cx, cy - 10), 28, white);
    canvas.drawCircle(Offset(cx, cy - 10), 28, outline);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx + 10, cy - 22), Paint()..color = AppColors.primary..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx + 14, cy - 6), Paint()..color = AppColors.accent..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 28), width: 36, height: 28), yellow);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 28), width: 36, height: 28), outline);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 30, cy - 25), width: 24, height: 20), Paint()..color = AppColors.primary);
    const textStyle = TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900);
    final tp = TextPainter(text: const TextSpan(text: '?', style: textStyle), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx + 24, cy - 33));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}