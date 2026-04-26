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

  // --- ADMIN BACKDOOR ---
  void _handleAdminAccess() {
    TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("SecureED Admin Vault"),
        content: TextField(
          controller: pinController,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter Master PIN"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (pinController.text == "2026") {
                Navigator.pop(context);
                _showAdminPanel(context);
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Access Denied"), 
                    backgroundColor: AppColors.error
                  ),
                );
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _showAdminPanel(BuildContext context) async {
    final users = await DatabaseService().getDecryptedUsersForAdmin();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Text(
              "INTERNAL DATA REGISTRY", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)
            ),
            const Text(
              "Visualization of Salt + Hash Protection", 
              style: TextStyle(fontSize: 12, color: Colors.grey)
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  String email = users.keys.elementAt(index);
                  String storedData = users.values.elementAt(index);
                  
                  // Splits data at the colon: [Salt]:[Hash]
                  List<String> parts = storedData.split(':');
                  String salt = parts.isNotEmpty ? parts[0] : "Missing";
                  String hash = parts.length > 1 ? parts[1] : "Missing";

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          const Text("CRYPTOGRAPHIC SALT:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          Text(salt, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.teal)),
                          const SizedBox(height: 8),
                          const Text("SHA-256 PASSWORD HASH:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          Text(hash, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.error)),
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

  // --- STANDARD LOGIN ---
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
      // Moves user to the home screen
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
                        // --- TOP NAVIGATION ---
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, top: 12), 
                            child: Align(alignment: Alignment.centerLeft, child: const GoldenBackButton())
                          )
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // --- SECRET GESTURE ILLUSTRATION ---
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
                          child: Text('WELCOME BACK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 26))
                        ),
                        const Text('SIGN IN', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 2)),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                          ),
                        ],

                        const SizedBox(height: 25),
                        
                        // --- INPUT FIELDS ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              RoundedTextField(hint: 'Email or Username', controller: _emailController, suffixIcon: Icons.person_outline),
                              const SizedBox(height: 14),
                              RoundedTextField(hint: 'Password', controller: _passwordController, isPassword: true),
                              
                              // FORGOT PASSWORD LINK
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

                        // Dynamically fills the space between the form and the wave
                        const Spacer(), 

                        // --- BOTTOM BUTTONS & WAVE ---
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
                                        child: const Text('SIGN IN')
                                      ),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Don't have an account? ", style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, '/signup'),
                                        child: const Text('Create one Now!', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13)),
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

// --- HELPER CLASSES (PAINTER & ILLUSTRATION) ---

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

    // Draw the yellow card/button shape
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

    // Draw the arrow icon inside the card
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

    // Draw the person's body
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy + 20), width: 40, height: 55),
        white);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy + 20), width: 40, height: 55),
        outline);

    // Draw the head
    canvas.drawCircle(Offset(cx - 15, cy - 15), 16, white);
    canvas.drawCircle(Offset(cx - 15, cy - 15), 16, outline);

    // Draw the hat
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 15, cy - 25), width: 32, height: 14),
        navy);

    // Draw the legs
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

    // Draw the arm
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