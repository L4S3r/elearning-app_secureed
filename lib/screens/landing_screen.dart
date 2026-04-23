// ignore_for_file: unused_element, unused_local_variable

import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const TopRightCircle(),
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const _LandingIllustration(),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Text(
                  'EDUCATION IS FREE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Online education has never been this easy.\nGet your Account now and let\'s get started already.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textDark.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const NavyWaveBottom(),

          Container(
            color: AppColors.navyBottom,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              children: [

                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signin'),
                  child: const Text('SIGN IN'),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: const BorderSide(color: Colors.white54, width: 1.5),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                    child: const Text('SIGN UP'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingIllustration extends StatelessWidget {
  const _LandingIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StudentPainter(),
    );
  }
}

class _StudentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final yellowPaint = Paint()..color = AppColors.accent;
    final navyPaint = Paint()..color = AppColors.primary;
    final whitePaint = Paint()..color = Colors.white;
    final outlinePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;


    final triPath = Path()
      ..moveTo(cx - 30, cy + 20)
      ..lineTo(cx + 50, cy - 40)
      ..lineTo(cx + 60, cy + 50)
      ..close();
    canvas.drawPath(triPath, yellowPaint);

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 30), width: 60, height: 80),
        whitePaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 30), width: 60, height: 80),
        outlinePaint);


    canvas.drawCircle(Offset(cx, cy - 15), 22, whitePaint);
    canvas.drawCircle(Offset(cx, cy - 15), 22, outlinePaint);


    final hairPaint = Paint()..color = AppColors.primary;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 30), width: 44, height: 18),
        hairPaint);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 5, cy + 40), width: 50, height: 30),
            const Radius.circular(4)),
        yellowPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + 5, cy + 40), width: 50, height: 30),
            const Radius.circular(4)),
        outlinePaint);


    for (int i = 0; i < 3; i++) {
      final sparkX = cx - 10.0 + i * 12;
      canvas.drawCircle(Offset(sparkX, cy + 15), 3, yellowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmallFigure extends StatelessWidget {
  const _SmallFigure();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(40, 50),
      painter: _SmallFigurePainter(),
    );
  }
}

class _SmallFigurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, 8), 7, paint);
    final bodyPaint = Paint()..color = Colors.white;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(size.width / 2, 28), width: 12, height: 16),
        bodyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}