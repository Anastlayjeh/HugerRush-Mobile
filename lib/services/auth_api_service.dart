import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) {
    return _sendAuthRequest(
      endpoint: '/api/v1/auth/login',
      payload: {
        'email': email.trim(),
        'password': password,
        'device_name': 'hunger-rush-mobile',
      },
    );
  }

  Future<AuthResult> register({
    required Map<String, dynamic> payload,
  }) {
    return _sendAuthRequest(
      endpoint: '/api/v1/auth/register',
      payload: payload,
    );
  }

  Future<AuthResult> _sendAuthRequest({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    http.Response response;
    try {
      response = await _client.post(
        AppConfig.apiUri(endpoint),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
    } catch (_) {
      throw const AuthApiException(
        'Unable to reach the server. Check your API URL and internet connection.',
      );
    }

    Map<String, dynamic> data = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthResult.fromJson(data);
    }

    throw AuthApiException(_extractError(data));
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
    this.user,
    this.message = 'Success',
  });

  final String? token;
  final Map<String, dynamic>? user;
  final String message;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final mappedData = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final token = (mappedData['token'] as String?) ??
        (mappedData['access_token'] as String?) ??
        (json['token'] as String?) ??
        (json['access_token'] as String?);
    final user = mappedData['user'] ?? json['user'];

    return AuthResult(
      token: token,
      user: user is Map<String, dynamic> ? user : null,
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
