import 'dart:async';

import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_service.dart';
import '../services/push_notification_service.dart';
import 'login_screen.dart';
import 'restaurant_feed_screen.dart';
import 'user_home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _restaurantRoles = <String>{
    'restaurant',
    'restaurant_owner',
    'restaurant_admin',
    'vendor',
    'merchant',
  };

  final _authSessionService = AuthSessionService();
  final _authApiService = AuthApiService();
  AuthSession? _session;
  bool _isBootstrapping = true;
  bool _isClearingInvalidSession = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await _authSessionService.readSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _session = session;
      _isBootstrapping = false;
    });
    if (session != null) {
      unawaited(
        PushNotificationService.instance.registerCurrentDeviceToken(
          session: session,
        ),
      );
    }
  }

  String _normalizeRole(String role) {
    return role.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  bool _isRestaurantRole(String role) {
    return _restaurantRoles.contains(_normalizeRole(role));
  }

  bool _isNormalUserRole(String role) {
    final normalized = _normalizeRole(role);
    return normalized.contains('customer') ||
        normalized.contains('user') ||
        normalized.contains('client') ||
        normalized.contains('diner') ||
        normalized.contains('consumer') ||
        normalized.contains('hungry');
  }

  String _extractFirstNonEmptyString(
    Map<String, dynamic>? user,
    List<String> keys,
  ) {
    if (user == null) {
      return '';
    }
    for (final key in keys) {
      final value = user[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String _extractUserName(Map<String, dynamic>? user) {
    final value = _extractFirstNonEmptyString(user, const [
      'name',
      'full_name',
      'username',
      'display_name',
      'first_name',
    ]);
    if (value.isNotEmpty) {
      return value;
    }

    final email = _extractFirstNonEmptyString(user, const [
      'email',
      'mail',
      'user_email',
      'contact_email',
    ]);
    if (email.contains('@')) {
      final prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) {
        return prefix;
      }
    }

    return 'FoodExplorer';
  }

  String? _extractUserEmail(Map<String, dynamic>? user) {
    final value = _extractFirstNonEmptyString(user, const [
      'email',
      'mail',
      'user_email',
      'contact_email',
    ]);
    return value.isEmpty ? null : value;
  }

  String? _extractUserAvatarUrl(Map<String, dynamic>? user) {
    final value = _extractFirstNonEmptyString(user, const [
      'avatar_url',
      'avatar',
      'photo_url',
      'photo',
      'profile_photo_url',
      'profile_image',
      'image_url',
      'image',
      'picture',
    ]);
    return value.isEmpty ? null : value;
  }

  String? _extractUserAccountLabel(AuthSession session) {
    final fromUser = _extractFirstNonEmptyString(session.user, const [
      'account_type',
      'user_type',
      'role',
      'membership_tier',
      'membership',
      'plan',
    ]);
    if (fromUser.isNotEmpty) {
      return fromUser;
    }
    return null;
  }

  void _handleAuthenticated(AuthSession session) {
    if (!mounted) {
      return;
    }
    setState(() => _session = session);
  }

  Future<void> _handleLogout() async {
    final session = _session;
    if (session != null) {
      unawaited(
        PushNotificationService.instance.deactivateCurrentDeviceToken(
          session: session,
        ),
      );
    }
    final token = _session?.token.trim();
    if (token != null && token.isNotEmpty) {
      try {
        await _authApiService.logout(token: token);
      } on AuthApiException {
        // Local logout must still complete if the token is already invalid.
      }
    }
    await _authSessionService.clearSession();
    if (!mounted) {
      return;
    }
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = _session;
    if (session == null) {
      return LoginScreen(
        authSessionService: _authSessionService,
        onAuthenticated: _handleAuthenticated,
      );
    }

    if (_isRestaurantRole(session.role)) {
      return RestaurantFeedScreen(
        restaurantName: session.restaurantName,
        authToken: session.token,
        initialUserData: session.user,
        onLogout: _handleLogout,
      );
    }

    if (_isNormalUserRole(session.role)) {
      return UserHomeScreen(
        userName: _extractUserName(session.user),
        userEmail: _extractUserEmail(session.user),
        userAvatarUrl: _extractUserAvatarUrl(session.user),
        accountLabel: _extractUserAccountLabel(session),
        authSession: session,
        onSessionUpdated: (updatedSession) async =>
            _handleAuthenticated(updatedSession),
        onSessionExpired: _handleLogout,
      );
    }

    if (!_isClearingInvalidSession) {
      _isClearingInvalidSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _handleLogout();
        _isClearingInvalidSession = false;
      });
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
