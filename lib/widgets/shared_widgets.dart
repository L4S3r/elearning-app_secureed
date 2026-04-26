import 'package:flutter/material.dart';
import '../theme.dart';

/// The decorative dark navy wave at the bottom of auth screens
class NavyWaveBottom extends StatelessWidget {
  const NavyWaveBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(
        painter: _WavePainter(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.navyBottom;
    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.1, size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.6, size.width, size.height * 0.3)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Reusable text field with rounded style
class RoundedTextField extends StatefulWidget {
  final String hint;
  final bool isPassword;
  final IconData? suffixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool hasError;
  final bool enabled; // ADDED: To support locking the email during reset

  const RoundedTextField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.suffixIcon,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.hasError = false,
    this.enabled = true, // ADDED
  });

  @override
  State<RoundedTextField> createState() => _RoundedTextFieldState();
}

class _RoundedTextFieldState extends State<RoundedTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscure : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      enabled: widget.enabled, // ADDED: Passes status to the internal field
      style: TextStyle(
        // Visual feedback: Dim text color if disabled
        color: widget.enabled ? AppColors.textDark : AppColors.textGray,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: widget.hasError ? AppColors.error : AppColors.textGray,
          fontSize: 15,
        ),
        // Visual feedback: Change background color if disabled
        fillColor: widget.enabled 
            ? (widget.hasError ? AppColors.error.withOpacity(0.05) : AppColors.inputBg)
            : AppColors.inputBg.withOpacity(0.5),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: widget.hasError
              ? const BorderSide(color: AppColors.error, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: widget.hasError
              ? const BorderSide(color: AppColors.error, width: 1.5)
              : BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder( // ADDED: Style for the locked state
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textGray,
                  size: 20,
                ),
                onPressed: widget.enabled 
                    ? () => setState(() => _obscure = !_obscure)
                    : null, // Disable toggle if field is disabled
              )
            : widget.suffixIcon != null
                ? Icon(widget.suffixIcon, color: AppColors.textGray, size: 20)
                : null,
      ),
    );
  }
}

/// Golden back button (circle)
class GoldenBackButton extends StatelessWidget {
  const GoldenBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
      ),
    );
  }
}

/// Top-right decorative circle
class TopRightCircle extends StatelessWidget {
  const TopRightCircle({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -30,
      right: -30,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.07),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}