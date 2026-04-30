import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../services/database_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // NOTE: Hardcoded PIN for academic demonstration only.
  // In production this would be replaced with server-side authentication.
  static const String _adminPin = '2026';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // STEP 1 — PIN dialog
  // ─────────────────────────────────────────────
  void _handleAdminAccess() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'SecureED Admin Vault',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1 of 2 — Enter Master PIN',
              style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'PIN',
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                counterText: '',
                filled: true,
                fillColor: AppColors.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              minimumSize: const Size(80, 38),
            ),
            onPressed: () {
              if (pinController.text == _adminPin) {
                Navigator.pop(context);
                // PIN passed — now try biometrics
                _handleBiometricAuth();
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Access Denied — Incorrect PIN'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2 — Biometric prompt
  // ─────────────────────────────────────────────
  Future<void> _handleBiometricAuth() async {
    final auth = LocalAuthentication();

    // Check if the device is even capable of biometrics
    final bool canCheckBiometrics = await auth.canCheckBiometrics;
    final bool isDeviceSupported = await auth.isDeviceSupported();

    if (!canCheckBiometrics || !isDeviceSupported) {
      // Device has no biometrics enrolled — skip step 2 and grant access.
      // In production you would DENY here; for academic demo we fall back.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No biometrics enrolled — falling back to PIN only'),
            backgroundColor: Colors.orange,
          ),
        );
        _showAdminPanel();
      }
      return;
    }

    // Show the OS biometric prompt
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Step 2 of 2 — Confirm your identity to open the Admin Vault',
        options: const AuthenticationOptions(
          biometricOnly: false,  // allows device PIN as fallback
          stickyAuth: true,      // keeps prompt alive if user switches apps
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      _showAdminPanel();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric verification failed — Access Denied'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // ADMIN PANEL — shown only after both factors pass
  // ─────────────────────────────────────────────
  void _showAdminPanel() async {
    final users = await DatabaseService().getDecryptedUsersForAdmin();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INTERNAL DATA REGISTRY',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                    ),
                    Text(
                      'Visualization of Salt + Hash Protection',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            // 2FA badge
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Authenticated via PIN + Biometrics (2FA)',
                    style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // User list
            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Text(
                        'No registered users yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final email = users.keys.elementAt(index);
                        final storedData = users.values.elementAt(index);

                        // Format: salt:hash
                        final parts = storedData.split(':');
                        final salt = parts.isNotEmpty ? parts[0] : 'Missing';
                        final hash = parts.length > 1 ? parts[1] : 'Missing';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      email,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'CRYPTOGRAPHIC SALT:',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  salt,
                                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.teal),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'SHA-256 PASSWORD HASH:',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hash,
                                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STANDARD LOGIN
  // ─────────────────────────────────────────────
  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final error = await DatabaseService().loginUser(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
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
                        // TOP NAVIGATION
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, top: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: const GoldenBackButton(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // SECRET GESTURE — long press triggers admin flow
                        Center(
                          child: GestureDetector(
                            onLongPress: _handleAdminAccess,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.07),
                                shape: BoxShape.circle,
                              ),
                              child: const _SignInIllustration(),
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.only(top: 15, bottom: 4),
                          child: Text(
                            'WELCOME BACK',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 26),
                          ),
                        ),
                        const Text(
                          'SIGN IN',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 2),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],

                        const SizedBox(height: 25),

                        // INPUT FIELDS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              RoundedTextField(
                                hint: 'Email or Username',
                                controller: _emailController,
                                suffixIcon: Icons.person_outline,
                              ),
                              const SizedBox(height: 14),
                              RoundedTextField(
                                hint: 'Password',
                                controller: _passwordController,
                                isPassword: true,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/forgot'),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // BOTTOM WAVE + BUTTONS
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            const NavyWaveBottom(),
                            Container(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _isLoading
                                      ? const CircularProgressIndicator(color: AppColors.accent)
                                      : ElevatedButton(
                                          onPressed: _handleSignIn,
                                          child: const Text('SIGN IN'),
                                        ),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Don't have an account? ",
                                        style: TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, '/signup'),
                                        child: const Text(
                                          'Create one Now!',
                                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

// ─────────────────────────────────────────────
// PAINTER & ILLUSTRATION
// ─────────────────────────────────────────────

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

    final arrowPath = Path()
      ..moveTo(cx + 5, cy - 10)
      ..lineTo(cx + 25, cy - 10)
      ..moveTo(cx + 18, cy - 18)
      ..lineTo(cx + 25, cy - 10)
      ..lineTo(cx + 18, cy - 2);
    canvas.drawPath(
        arrowPath,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy + 20), width: 40, height: 55), white);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy + 20), width: 40, height: 55), outline);

    canvas.drawCircle(Offset(cx - 15, cy - 15), 16, white);
    canvas.drawCircle(Offset(cx - 15, cy - 15), 16, outline);

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy - 25), width: 32, height: 14), navy);

    final legPath = Path()
      ..moveTo(cx - 15, cy + 40)
      ..lineTo(cx - 30, cy + 65)
      ..moveTo(cx - 15, cy + 40)
      ..lineTo(cx + 5, cy + 60);
    canvas.drawPath(
        legPath,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);

    final armPath = Path()
      ..moveTo(cx - 15, cy + 5)
      ..lineTo(cx + 12, cy - 8);
    canvas.drawPath(
        armPath,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}