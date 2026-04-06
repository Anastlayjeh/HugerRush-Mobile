import 'package:flutter/material.dart';

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8DCCF)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    stroke.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.36, 1.30, false, stroke);

    stroke.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -1.06, 1.35, false, stroke);

    stroke.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.30, 1.55, false, stroke);

    stroke.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 1.85, 2.10, false, stroke);

    final bar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF4285F4);
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.90, size.height * 0.50),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
