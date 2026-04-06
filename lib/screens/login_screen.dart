import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/auth_social_buttons.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = math.min(constraints.maxWidth, 360.0);
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 88,
                bottom: 28 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.lunch_dining_rounded,
                          color: Color(0xFFFF7E4D),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'HungerRush',
                        style: TextStyle(
                          color: Color(0xFF2E2521),
                          fontSize: 33,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Discover food. Order instantly.',
                        style: TextStyle(
                          color: Color(0xFFA69485),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _RoundedField(
                        hint: 'Email address',
                        icon: Icons.mail_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _RoundedField(
                        hint: 'Password',
                        icon: Icons.lock_rounded,
                        obscureText: _obscurePassword,
                        trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          splashRadius: 20,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: const Color(0xFF9E8B7D),
                            size: 20,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(top: 8, right: 4),
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFA08E80),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7E4D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Log In'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFEADFD5),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(
                                color: Color(0xFFB6A495),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFEADFD5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AuthSocialButton(child: GoogleMark()),
                          SizedBox(width: 16),
                          AuthSocialButton(
                            child: Icon(
                              Icons.apple,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Color(0xFF2E2521),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegistrationScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFFF7E4D),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
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
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
  });

  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9E8B7D), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              keyboardType: keyboardType,
              obscureText: obscureText,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFB7A79A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF2E2521),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
