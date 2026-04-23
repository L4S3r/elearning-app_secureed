import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/database_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final repeat = _repeatPasswordController.text;

    if (email.isEmpty || password.isEmpty || repeat.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
        _isLoading = false;
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
        _isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
        _isLoading = false;
      });
      return;
    }

    if (password != repeat) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    final error = await DatabaseService().registerUser(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please sign in.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushReplacementNamed(context, '/signin');
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
                    child: const _SignUpIllustration(),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  "LET'S GET STARTED",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Text(
                'SIGN UP',
                style: TextStyle(
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

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        RoundedTextField(
                          hint: 'Email',
                          controller: _emailController,
                          suffixIcon: Icons.person_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        RoundedTextField(
                          hint: 'Password',
                          controller: _passwordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 14),
                        RoundedTextField(
                          hint: 'Repeat Password',
                          controller: _repeatPasswordController,
                          isPassword: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const NavyWaveBottom(),

              Container(
                color: AppColors.navyBottom,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    _isLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.accent)
                        : ElevatedButton(
                            onPressed: _handleSignUp,
                            child: const Text('SIGN UP'),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/signin'),
                          child: const Text(
                            'Log in',
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

class _SignUpIllustration extends StatelessWidget {
  const _SignUpIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SignUpPainter());
  }
}

class _SignUpPainter extends CustomPainter {
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

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 20, cy - 20), width: 35, height: 45),
            const Radius.circular(3)),
        yellow);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 20, cy - 20), width: 35, height: 45),
            const Radius.circular(3)),
        outline);

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
          Offset(cx + 8, cy - 30.0 + i * 10),
          Offset(cx + 32, cy - 30.0 + i * 10),
          Paint()
            ..color = AppColors.primary
            ..strokeWidth = 1.5);
    }

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 10, cy + 20), width: 40, height: 55),
        white);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 10, cy + 20), width: 40, height: 55),
        outline);

    canvas.drawCircle(Offset(cx - 10, cy - 12), 16, white);
    canvas.drawCircle(Offset(cx - 10, cy - 12), 16, outline);

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 10, cy - 22), width: 32, height: 14),
        navy);

    final legs = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 10, cy + 42), Offset(cx - 25, cy + 65), legs);
    canvas.drawLine(Offset(cx - 10, cy + 42), Offset(cx + 5, cy + 58), legs);

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 28, cy + 68), width: 8, height: 5),
        Paint()..color = AppColors.primary.withOpacity(0.3));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 8, cy + 62), width: 6, height: 4),
        Paint()..color = AppColors.primary.withOpacity(0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
