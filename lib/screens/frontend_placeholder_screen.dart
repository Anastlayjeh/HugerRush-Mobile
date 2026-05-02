import 'package:flutter/material.dart';

class FrontendPlaceholderScreen extends StatelessWidget {
  const FrontendPlaceholderScreen({
    super.key,
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF7),
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF231A16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 42,
                color: Color(0xFFFF7E4D),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF231A16),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'This frontend page is not available yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7D6C60),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
