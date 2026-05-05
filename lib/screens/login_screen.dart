import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../models/auth_session.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_service.dart';
import '../widgets/auth_social_buttons.dart';
import 'frontend_placeholder_screen.dart';
import 'registration_screen.dart';
import 'restaurant_feed_screen.dart';
import 'user_home_screen.dart';

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
  static bool _googleSignInInitialized = false;
  static Future<void>? _googleSignInInitialization;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthApiService _authApiService;
  late final AuthSessionService _authSessionService;

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

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

  String? _extractRoleFromMessage(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    if (_isRestaurantRole(normalized)) {
      return 'restaurant';
    }
    if (_isNormalUserRole(normalized)) {
      return 'customer';
    }

    return null;
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

  bool _isNormalUserRole(String role) {
    return role.contains('customer') ||
        role.contains('user') ||
        role.contains('client') ||
        role.contains('diner') ||
        role.contains('consumer') ||
        role.contains('hungry');
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

  String _extractUserName(
    Map<String, dynamic>? user, {
    String? fallbackEmail,
    String? fallbackDisplayName,
  }) {
    final fallbackName = fallbackDisplayName?.trim();
    if (fallbackName != null && fallbackName.isNotEmpty) {
      return fallbackName;
    }

    if (user == null) {
      if (fallbackEmail != null && fallbackEmail.contains('@')) {
        final prefix = fallbackEmail.split('@').first.trim();
        if (prefix.isNotEmpty) {
          return prefix;
        }
      }
      return 'FoodExplorer';
    }

    final possibleKeys = [
      'name',
      'full_name',
      'username',
      'display_name',
      'first_name',
    ];
    for (final key in possibleKeys) {
      final value = user[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final email = user['email'];
    if (email is String && email.contains('@')) {
      final prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) {
        return prefix;
      }
    }

    if (fallbackEmail != null && fallbackEmail.contains('@')) {
      final prefix = fallbackEmail.split('@').first.trim();
      if (prefix.isNotEmpty) {
        return prefix;
      }
    }

    return 'FoodExplorer';
  }

  String? _extractUserEmail(
    Map<String, dynamic>? user, {
    String? fallbackEmail,
  }) {
    if (user != null) {
      final possibleKeys = ['email', 'mail', 'user_email', 'contact_email'];
      for (final key in possibleKeys) {
        final value = user[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    final cleanedFallback = fallbackEmail?.trim();
    if (cleanedFallback != null && cleanedFallback.isNotEmpty) {
      return cleanedFallback;
    }

    return null;
  }

  String? _extractUserAvatarUrl(
    Map<String, dynamic>? user, {
    String? fallbackAvatarUrl,
  }) {
    if (user != null) {
      final possibleKeys = [
        'avatar_url',
        'avatar',
        'photo_url',
        'photo',
        'profile_photo_url',
        'profile_image',
        'image_url',
        'image',
        'picture',
      ];
      for (final key in possibleKeys) {
        final value = user[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    final cleanedFallback = fallbackAvatarUrl?.trim();
    if (cleanedFallback != null && cleanedFallback.isNotEmpty) {
      return cleanedFallback;
    }

    return null;
  }

  String? _extractUserAccountLabel(
    Map<String, dynamic>? user, {
    String? fallbackLabel,
  }) {
    final cleanedFallback = fallbackLabel?.trim();
    if (cleanedFallback != null && cleanedFallback.isNotEmpty) {
      return cleanedFallback;
    }

    if (user == null) {
      return null;
    }

    final possibleKeys = [
      'account_type',
      'user_type',
      'role',
      'membership_tier',
      'membership',
      'plan',
    ];
    for (final key in possibleKeys) {
      final value = user[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  bool get _isBusy => _isSubmitting || _isGoogleSubmitting;

  void _showErrorSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB7372B),
      ),
    );
  }

  void _openPlaceholderPage({required String title, required String message}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FrontendPlaceholderScreen(title: title, message: message),
      ),
    );
  }

  Future<void> _handleSuccessfulAuth(
    AuthResult result, {
    String? fallbackEmail,
    String? fallbackDisplayName,
    String? fallbackAvatarUrl,
    String? fallbackAccountLabel,
  }) async {
    final token = result.token?.trim();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Login response did not include an access token.',
      );
    }

    if (!mounted) {
      return;
    }

    final detectedRole =
        _findRestaurantRole(result.user) ??
        _normalizeRole(result.role) ??
        _extractRoleFromMessage(result.message);

    if (detectedRole != null && _isRestaurantRole(detectedRole)) {
      final session = AuthSession(
        token: token,
        role: detectedRole,
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
          builder: (_) => RestaurantFeedScreen(
            restaurantName: session.restaurantName,
            authToken: session.token,
            initialUserData: session.user,
          ),
        ),
      );
      return;
    }

    if (detectedRole == null || _isNormalUserRole(detectedRole)) {
      final customerName = _extractUserName(
        result.user,
        fallbackEmail: fallbackEmail,
        fallbackDisplayName: fallbackDisplayName,
      );
      final customerEmail = _extractUserEmail(
        result.user,
        fallbackEmail: fallbackEmail,
      );
      final customerAvatarUrl = _extractUserAvatarUrl(
        result.user,
        fallbackAvatarUrl: fallbackAvatarUrl,
      );
      final customerAccountLabel = _extractUserAccountLabel(
        result.user,
        fallbackLabel: fallbackAccountLabel,
      );
      final customerSession = AuthSession(
        token: token,
        role: detectedRole ?? 'customer',
        // `restaurantName` is required by AuthSession and reused as a generic
        // persisted display label for non-restaurant users.
        restaurantName: customerName,
        refreshToken: result.refreshToken?.trim(),
        user: result.user,
      );
      await _authSessionService.saveSession(customerSession);
      if (!mounted) {
        return;
      }

      final onAuthenticated = widget.onAuthenticated;
      if (onAuthenticated != null) {
        onAuthenticated(customerSession);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => UserHomeScreen(
            userName: customerName,
            userEmail: customerEmail,
            userAvatarUrl: customerAvatarUrl,
            accountLabel: customerAccountLabel,
            authSession: customerSession,
          ),
        ),
      );
      return;
    }

    final displayRole = detectedRole.replaceAll('_', ' ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.message} ($displayRole). Role is not mapped to a screen yet.',
        ),
      ),
    );
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) {
      return;
    }

    _googleSignInInitialization ??= GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId.trim().isEmpty
          ? null
          : AppConfig.googleServerClientId.trim(),
    );

    try {
      await _googleSignInInitialization;
      _googleSignInInitialized = true;
    } catch (_) {
      _googleSignInInitialization = null;
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    if (_isBusy) {
      return;
    }

    setState(() => _isGoogleSubmitting = true);
    try {
      await _ensureGoogleSignInInitialized();
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const AuthApiException(
          'Google ID token is missing. Verify Google OAuth setup and server client ID.',
        );
      }

      final result = await _authApiService.loginWithGoogleIdToken(
        idToken: idToken,
      );
      await _handleSuccessfulAuth(
        result,
        fallbackEmail: googleAccount.email,
        fallbackDisplayName: googleAccount.displayName,
        fallbackAvatarUrl: googleAccount.photoUrl,
        fallbackAccountLabel: 'Google Account',
      );
    } on GoogleSignInException catch (e) {
      debugPrint(
        'Google sign-in error: code=${e.code.name}, description=${e.description}, details=${e.details}',
      );
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        _showErrorSnackBar(
          'Google sign-in was canceled or blocked by configuration. '
          'If this happens right after choosing an account, verify OAuth package name and SHA fingerprints.',
        );
      } else if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        _showErrorSnackBar(
          'Google sign-in configuration is invalid. Check package/bundle ID and OAuth client setup.',
        );
      } else {
        _showErrorSnackBar('Google sign-in failed. Please try again.');
      }
    } on AuthApiException catch (e) {
      _showErrorSnackBar(e.message);
    } on AuthSessionException catch (e) {
      _showErrorSnackBar(e.message);
    } finally {
      if (mounted) {
        setState(() => _isGoogleSubmitting = false);
      }
    }
  }

  Future<void> _submit() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    if (_isBusy) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _authApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _handleSuccessfulAuth(
        result,
        fallbackEmail: _emailController.text.trim(),
        fallbackAccountLabel: 'Customer Account',
      );
    } on AuthApiException catch (e) {
      _showErrorSnackBar(e.message);
    } on AuthSessionException catch (e) {
      _showErrorSnackBar(e.message);
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
                          onPressed: () => _openPlaceholderPage(
                            title: 'Forgot Password',
                            message:
                                'Password reset is not connected yet. Please contact support from your profile after login.',
                          ),
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
                          onPressed: _isBusy ? null : _submit,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AuthSocialButton(
                            onPressed: _isBusy ? null : signInWithGoogle,
                            child: _isGoogleSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2E2521),
                                    ),
                                  )
                                : const GoogleMark(),
                          ),
                          const SizedBox(width: 16),
                          AuthSocialButton(
                            onPressed: _isBusy
                                ? null
                                : () => _openPlaceholderPage(
                                    title: 'Apple Sign In',
                                    message:
                                        'Apple sign-in is not connected yet. Use email/password or Google sign-in for now.',
                                  ),
                            child: const Icon(
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
