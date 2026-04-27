import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

class AuthSessionService {
  AuthSessionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'auth_session_v1';
  static const _androidOptions = AndroidOptions(encryptedSharedPreferences: true);
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    try {
      await _storage.write(
        key: _sessionKey,
        value: jsonEncode(session.toJson()),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } on MissingPluginException {
      // Storage plugin is unavailable (e.g. some test environments).
    } on PlatformException {
      throw const AuthSessionException(
        'Unable to securely store your session on this device.',
      );
    }
  }

  Future<AuthSession?> readSession() async {
    try {
      final raw = await _storage.read(
        key: _sessionKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      if (raw == null || raw.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clearSession();
        return null;
      }

      final session = AuthSession.fromJson(decoded);
      if (session.token.trim().isEmpty || session.role.trim().isEmpty) {
        await clearSession();
        return null;
      }

      return session;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } on FormatException {
      await clearSession();
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(
        key: _sessionKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
    } on MissingPluginException {
      // Storage plugin is unavailable (e.g. some test environments).
    } on PlatformException {
      // Keep logout resilient even if secure storage is temporarily unavailable.
    }
  }
}

class AuthSessionException implements Exception {
  const AuthSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}
