import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../services/auth_session_service.dart';
import 'login_screen.dart';
import 'restaurant_feed_screen.dart';

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
  }

  String _normalizeRole(String role) {
    return role.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  bool _isRestaurantRole(String role) {
    return _restaurantRoles.contains(_normalizeRole(role));
  }

  void _handleAuthenticated(AuthSession session) {
    if (!mounted) {
      return;
    }
    setState(() => _session = session);
  }

  Future<void> _handleLogout() async {
    await _authSessionService.clearSession();
    if (!mounted) {
      return;
    }
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = _session;
    if (session == null) {
      return LoginScreen(
        authSessionService: _authSessionService,
        onAuthenticated: _handleAuthenticated,
      );
    }

    if (!_isRestaurantRole(session.role)) {
      if (!_isClearingInvalidSession) {
        _isClearingInvalidSession = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _handleLogout();
          _isClearingInvalidSession = false;
        });
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return RestaurantFeedScreen(
      restaurantName: session.restaurantName,
      onLogout: _handleLogout,
    );
  }
}
