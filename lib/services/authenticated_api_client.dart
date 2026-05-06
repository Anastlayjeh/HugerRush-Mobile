import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import 'api_client.dart';
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
       _apiClient = ApiClient(client: client);

  final AuthApiService _authApiService;
  final AuthSessionService _authSessionService;
  final Future<void> Function(AuthSession session)? _onSessionUpdated;
  final Future<void> Function()? _onSessionExpired;
  final ApiClient _apiClient;

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
    final initialResponse = await _sendWithAuth(
      method: normalizedMethod,
      endpoint: endpoint,
      token: session.token,
      headers: headers,
      body: body,
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
      body: body,
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
    try {
      return await _apiClient.request(
        method: method,
        endpoint: endpoint,
        token: token,
        headers: headers,
        body: body,
        timeout: timeout,
      );
    } on ApiClientException catch (error) {
      throw AuthApiException(error.message);
    }
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
