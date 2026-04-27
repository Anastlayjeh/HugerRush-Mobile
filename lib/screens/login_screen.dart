import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_service.dart';
import '../widgets/auth_social_buttons.dart';
import 'registration_screen.dart';
import 'restaurant_feed_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({
    super.key,
    AuthApiService? authApiService,
    AuthSessionService? authSessionService,
    this.onAuthenticated,
  }) : authApiService = authApiService ?? AuthApiService(),
       authSessionService = authSessionService ?? AuthSessionService();

  final AuthApiService authApiService;
  final AuthSessionService authSessionService;
  final ValueChanged<AuthSession>? onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _restaurantRoles = <String>{
    'restaurant',
    'restaurant_owner',
    'restaurant_admin',
    'vendor',
    'merchant',
  };

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthApiService _authApiService;
  late final AuthSessionService _authSessionService;

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _authApiService = widget.authApiService;
    _authSessionService = widget.authSessionService;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email';
    }
    if (password.isEmpty) {
      return 'Password is required';
    }

    return null;
  }

  String? _normalizeRole(dynamic value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase().replaceAll(
        RegExp(r'[\s-]+'),
        '_',
      );
      return normalized.isEmpty ? null : normalized;
    }

    return null;
  }

  List<String> _collectRoles(dynamic value) {
    final roles = <String>[];

    void collect(dynamic entry) {
      final normalized = _normalizeRole(entry);
      if (normalized != null) {
        roles.add(normalized);
        return;
      }

      if (entry is Map) {
        collect(
          entry['name'] ?? entry['slug'] ?? entry['role'] ?? entry['type'],
        );
      } else if (entry is Iterable) {
        for (final item in entry) {
          collect(item);
        }
      }
    }

    collect(value);
    final seen = <String>{};
    return [
      for (final role in roles)
        if (seen.add(role)) role,
    ];
  }

  List<String> _extractRoles(Map<String, dynamic>? user) {
    if (user == null) {
      return const [];
    }

    final merged = <String>[
      ..._collectRoles(user['role']),
      ..._collectRoles(user['user_role']),
      ..._collectRoles(user['user_type']),
      ..._collectRoles(user['account_type']),
      ..._collectRoles(user['type']),
      ..._collectRoles(user['roles']),
    ];

    final seen = <String>{};
    return [
      for (final role in merged)
        if (seen.add(role)) role,
    ];
  }

  bool _isRestaurantRole(String role) {
    return _restaurantRoles.contains(role);
  }

  String? _findRestaurantRole(Map<String, dynamic>? user) {
    final roles = _extractRoles(user);
    for (final role in roles) {
      if (_isRestaurantRole(role)) {
        return role;
      }
    }
    return null;
  }

  String _extractRestaurantName(Map<String, dynamic>? user) {
    if (user == null) {
      return 'Restaurant';
    }

    final possibleKeys = [
      'restaurant_name',
      'business_name',
      'store_name',
      'name',
      'full_name',
    ];
    for (final key in possibleKeys) {
      final value = user[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Restaurant';
  }

  Future<void> _submit() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: const Color(0xFFB7372B),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _authApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final token = result.token?.trim();
      if (token == null || token.isEmpty) {
        throw const AuthApiException(
          'Login response did not include an access token.',
        );
      }

      if (!mounted) {
        return;
      }

      final restaurantRole = _findRestaurantRole(result.user);
      if (restaurantRole == null) {
        await _authSessionService.clearSession();
        if (!mounted) {
          return;
        }
        final roles = _extractRoles(result.user);
        final displayRole = roles.isEmpty
            ? 'unknown role'
            : roles.join(', ').replaceAll('_', ' ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This account is not authorized for the restaurant app ($displayRole).',
            ),
            backgroundColor: const Color(0xFFB7372B),
          ),
        );
        return;
      }

      final session = AuthSession(
        token: token,
        role: restaurantRole,
        restaurantName: _extractRestaurantName(result.user),
        refreshToken: result.refreshToken?.trim(),
        user: result.user,
      );
      await _authSessionService.saveSession(session);
      if (!mounted) {
        return;
      }

      final onAuthenticated = widget.onAuthenticated;
      if (onAuthenticated != null) {
        onAuthenticated(session);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              RestaurantFeedScreen(restaurantName: session.restaurantName),
        ),
      );
    } on AuthApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFB7372B),
        ),
      );
    } on AuthSessionException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFB7372B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _RoundedField(
                        hint: 'Password',
                        icon: Icons.lock_rounded,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
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
                          onPressed: _isSubmitting ? null : _submit,
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
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Log In'),
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
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

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
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              onSubmitted: onFieldSubmitted,
              textInputAction: textInputAction,
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
