import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/database_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid password or email, try again';
        _isLoading = false;
      });
      return;
    }

    final error = await DatabaseService().loginUser(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const TopRightCircle(),
          Column(
            children: [
              // Back + illustration
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
                height: 160,
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const _SignInIllustration(),
                  ),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Text(
                'SIGN IN',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),

              // Error message
              if (hasError) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        RoundedTextField(
                          hint: 'Email or Username',
                          controller: _emailController,
                          suffixIcon: Icons.person_outline,
                          keyboardType: TextInputType.emailAddress,
                          hasError: hasError,
                        ),
                        const SizedBox(height: 14),
                        RoundedTextField(
                          hint: 'Password',
                          controller: _passwordController,
                          isPassword: true,
                          hasError: hasError,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/forgot-password'),
                            child: const Text(
                              'Forget Password',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Wave + button
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const NavyWaveBottom(),
                ],
              ),

              Container(
                color: AppColors.navyBottom,
                padding:
                    const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    _isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.accent,
                          )
                        : ElevatedButton(
                            onPressed: _handleSignIn,
                            child: const Text('SIGN IN'),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            'Create one Now!',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignInIllustration extends StatelessWidget {
  const _SignInIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SignInPainter());
  }
}

class _SignInPainter extends CustomPainter {
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

    // Screen/monitor
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 15, cy - 10), width: 50, height: 40),
            const Radius.circular(4)),
        yellow);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 15, cy - 10), width: 50, height: 40),
            const Radius.circular(4)),
        outline);

    // Arrow on screen
    final arrowPath = Path()
      ..moveTo(cx + 5, cy - 10)
      ..lineTo(cx + 25, cy - 10)
      ..moveTo(cx + 18, cy - 18)
      ..lineTo(cx + 25, cy - 10)
      ..lineTo(cx + 18, cy - 2);
    canvas.drawPath(arrowPath, Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round);

    // Person body
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy + 20), width: 40, height: 55),
        white);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy + 20), width: 40, height: 55),
        outline);

    // Head
    canvas.drawCircle(Offset(cx - 15, cy - 15), 16, white);
    canvas.drawCircle(Offset(cx - 15, cy - 15), 16, outline);

    // Hair
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy - 25), width: 32, height: 14),
        navy);

    // Leg kick back
    final legPath = Path()
      ..moveTo(cx - 15, cy + 40)
      ..lineTo(cx - 30, cy + 65)
      ..moveTo(cx - 15, cy + 40)
      ..lineTo(cx + 5, cy + 60);
    canvas.drawPath(legPath, Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);

    // Arm reaching
    final armPath = Path()
      ..moveTo(cx - 15, cy + 5)
      ..lineTo(cx + 12, cy - 8);
    canvas.drawPath(armPath, Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
