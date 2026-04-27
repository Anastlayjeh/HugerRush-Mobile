import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String deviceName = 'hunger-rush-mobile';

  final http.Client _client;

  Future<AuthResult> login({required String email, required String password}) {
    return _sendAuthRequest(
      endpoint: '/api/v1/auth/login',
      payload: {
        'email': email.trim(),
        'password': password,
        'device_name': deviceName,
      },
    );
  }

  Future<AuthResult> register({required Map<String, dynamic> payload}) {
    return _sendAuthRequest(
      endpoint: '/api/v1/auth/register',
      payload: payload,
    );
  }

  Future<AuthResult> refresh({required String refreshToken}) {
    return _sendAuthRequest(
      endpoint: '/api/v1/auth/refresh',
      payload: <String, dynamic>{
        'refresh_token': refreshToken,
        'device_name': deviceName,
      },
    );
  }

  Map<String, String> authorizationHeaders(String token) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<AuthResult> _sendAuthRequest({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    http.Response response;
    try {
      response = await _client
          .post(
            AppConfig.apiUri(endpoint),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AuthApiException(
        'Request timed out. Please check your connection and try again.',
      );
    } catch (error) {
      throw AuthApiException(
        'Unable to reach ${AppConfig.apiBaseUrl}. '
        'Check your API URL and network access. '
        'Details: $error',
      );
    }

    Map<String, dynamic> data = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw const AuthApiException(
            'Server returned an unreadable response format.',
          );
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthResult.fromJson(data);
    }

    throw AuthApiException(
      '${_extractError(data)} (HTTP ${response.statusCode})',
    );
  }

  String _extractError(Map<String, dynamic> data) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final errors = data['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        final firstMessage = firstError.first;
        if (firstMessage is String && firstMessage.trim().isNotEmpty) {
          return firstMessage;
        }
      }
    }

    return 'Request failed. Please try again.';
  }
}

class AuthResult {
  const AuthResult({
    this.token,
    this.refreshToken,
    this.user,
    this.role,
    this.message = 'Success',
  });

  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final dynamic role;
  final String message;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final mappedData = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{};
    final token =
        (mappedData['token'] as String?) ??
        (mappedData['access_token'] as String?) ??
        (json['token'] as String?) ??
        (json['access_token'] as String?);
    final refreshToken =
        (mappedData['refresh_token'] as String?) ??
        (mappedData['refreshToken'] as String?) ??
        (json['refresh_token'] as String?) ??
        (json['refreshToken'] as String?);
    final user = mappedData['user'] ?? json['user'];
    final role =
        mappedData['role'] ??
        mappedData['user_role'] ??
        mappedData['user_type'] ??
        mappedData['account_type'] ??
        mappedData['type'] ??
        json['role'] ??
        json['user_role'] ??
        json['user_type'] ??
        json['account_type'] ??
        json['type'];

    return AuthResult(
      token: token,
      refreshToken: refreshToken,
      user: user is Map<String, dynamic> ? user : null,
      role: role,
      message: (json['message'] as String?) ?? 'Success',
    );
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
