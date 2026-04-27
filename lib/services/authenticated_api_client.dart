import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/auth_session.dart';
import 'auth_api_service.dart';
import 'auth_session_service.dart';

class AuthenticatedApiClient {
  AuthenticatedApiClient({
    required AuthApiService authApiService,
    required AuthSessionService authSessionService,
    Future<void> Function(AuthSession session)? onSessionUpdated,
    Future<void> Function()? onSessionExpired,
    http.Client? client,
  }) : _authApiService = authApiService,
       _authSessionService = authSessionService,
       _onSessionUpdated = onSessionUpdated,
       _onSessionExpired = onSessionExpired,
       _client = client ?? http.Client();

  final AuthApiService _authApiService;
  final AuthSessionService _authSessionService;
  final Future<void> Function(AuthSession session)? _onSessionUpdated;
  final Future<void> Function()? _onSessionExpired;
  final http.Client _client;

  Future<AuthSession>? _refreshingSessionFuture;

  Future<AuthenticatedApiResult> request({
    required AuthSession session,
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final normalizedMethod = method.trim().toUpperCase();
    final normalizedBody = _normalizeBody(body);

    final initialResponse = await _sendWithAuth(
      method: normalizedMethod,
      endpoint: endpoint,
      token: session.token,
      headers: headers,
      body: normalizedBody,
      timeout: timeout,
    );

    if (initialResponse.statusCode != 401) {
      return AuthenticatedApiResult(
        response: initialResponse,
        session: session,
        usedRefreshFlow: false,
      );
    }

    final refreshedSession = await _refreshSession(session);
    final retriedResponse = await _sendWithAuth(
      method: normalizedMethod,
      endpoint: endpoint,
      token: refreshedSession.token,
      headers: headers,
      body: normalizedBody,
      timeout: timeout,
    );

    if (retriedResponse.statusCode == 401) {
      await _expireSession();
      throw const AuthSessionExpiredException(
        'Session expired. Please log in again.',
      );
    }

    return AuthenticatedApiResult(
      response: retriedResponse,
      session: refreshedSession,
      usedRefreshFlow: true,
    );
  }

  Object? _normalizeBody(Object? body) {
    if (body == null || body is String || body is List<int>) {
      return body;
    }
    return jsonEncode(body);
  }

  Future<AuthSession> _refreshSession(AuthSession session) async {
    final activeRefresh = _refreshingSessionFuture;
    if (activeRefresh != null) {
      return activeRefresh;
    }

    final refreshFuture = _performRefresh(session);
    _refreshingSessionFuture = refreshFuture;

    try {
      return await refreshFuture;
    } finally {
      if (identical(_refreshingSessionFuture, refreshFuture)) {
        _refreshingSessionFuture = null;
      }
    }
  }

  Future<AuthSession> _performRefresh(AuthSession session) async {
    final refreshToken = session.refreshToken?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      throw const AuthSessionExpiredException(
        'Session expired. Please log in again.',
      );
    }

    AuthResult refreshed;
    try {
      refreshed = await _authApiService.refresh(refreshToken: refreshToken);
    } on AuthApiException {
      await _expireSession();
      throw const AuthSessionExpiredException(
        'Session expired. Please log in again.',
      );
    }

    final newAccessToken = refreshed.token?.trim();
    if (newAccessToken == null || newAccessToken.isEmpty) {
      await _expireSession();
      throw const AuthSessionExpiredException(
        'Session expired. Please log in again.',
      );
    }

    final rotatedRefreshToken = refreshed.refreshToken?.trim();
    final updatedSession = session.copyWith(
      token: newAccessToken,
      refreshToken:
          (rotatedRefreshToken != null && rotatedRefreshToken.isNotEmpty)
          ? rotatedRefreshToken
          : refreshToken,
      user: refreshed.user,
    );

    await _authSessionService.saveSession(updatedSession);
    final onSessionUpdated = _onSessionUpdated;
    if (onSessionUpdated != null) {
      await onSessionUpdated(updatedSession);
    }

    return updatedSession;
  }

  Future<void> _expireSession() async {
    await _authSessionService.clearSession();
    final onSessionExpired = _onSessionExpired;
    if (onSessionExpired != null) {
      await onSessionExpired();
    }
  }

  Future<http.Response> _sendWithAuth({
    required String method,
    required String endpoint,
    required String token,
    required Duration timeout,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = AppConfig.apiUri(endpoint);
    final hasBody = body != null;
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      if (hasBody) 'Content-Type': 'application/json',
      ...?headers,
      'Authorization': 'Bearer $token',
    };

    try {
      switch (method) {
        case 'GET':
          return await _client
              .get(uri, headers: requestHeaders)
              .timeout(timeout);
        case 'POST':
          return await _client
              .post(uri, headers: requestHeaders, body: body)
              .timeout(timeout);
        case 'PUT':
          return await _client
              .put(uri, headers: requestHeaders, body: body)
              .timeout(timeout);
        case 'PATCH':
          return await _client
              .patch(uri, headers: requestHeaders, body: body)
              .timeout(timeout);
        case 'DELETE':
          return await _client
              .delete(uri, headers: requestHeaders, body: body)
              .timeout(timeout);
      }
    } on TimeoutException {
      throw const AuthApiException(
        'Request timed out. Please check your connection and try again.',
      );
    } catch (_) {
      throw const AuthApiException(
        'Unable to reach the server. Check your API URL and internet connection.',
      );
    }

    throw AuthApiException('Unsupported HTTP method "$method".');
  }
}

class AuthenticatedApiResult {
  const AuthenticatedApiResult({
    required this.response,
    required this.session,
    required this.usedRefreshFlow,
  });

  final http.Response response;
  final AuthSession session;
  final bool usedRefreshFlow;
}

class AuthSessionExpiredException implements Exception {
  const AuthSessionExpiredException(this.message);

  final String message;

  @override
  String toString() => message;
}
