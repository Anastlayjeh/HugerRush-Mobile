import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_client.dart';

class AuthApiService {
  AuthApiService({http.Client? client})
    : _apiClient = ApiClient(client: client);

  static const String deviceName = 'hunger-rush-mobile';
  static const String forgotPasswordSuccessMessage =
      'A reset password link has been sent.';

  final ApiClient _apiClient;

  Future<AuthResult> login({required String email, required String password}) {
    return _sendAuthRequest(
      endpoint: '/v1/auth/login',
      payload: {
        'email': email.trim(),
        'password': password,
        'device_name': deviceName,
      },
    );
  }

  Future<AuthResult> loginWithGoogleIdToken({required String idToken}) {
    final cleanedIdToken = idToken.trim();
    if (cleanedIdToken.isEmpty) {
      throw const AuthApiException('Google ID token is missing.');
    }

    return _sendAuthRequest(
      endpoint: ApiConfig.googleAuthEndpoint,
      payload: <String, dynamic>{'id_token': cleanedIdToken},
    );
  }

  Future<AuthResult> register({required Map<String, dynamic> payload}) {
    return _sendAuthRequest(endpoint: '/v1/auth/register', payload: payload);
  }

  Future<String> forgotPassword({required String email}) async {
    final cleanedEmail = email.trim();
    if (cleanedEmail.isEmpty) {
      throw const AuthApiException('Email is required.');
    }

    http.Response response;
    try {
      response = await _apiClient.request(
        method: 'POST',
        endpoint: '/v1/auth/forgot-password',
        body: <String, dynamic>{'email': cleanedEmail},
      );
    } on ApiClientException catch (error) {
      throw AuthApiException(error.message);
    }

    final data = ApiClient.decodeMap(response.body);
    if (data.isEmpty &&
        response.body.isNotEmpty &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      throw const AuthApiException(
        'Server returned an unreadable response format.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return forgotPasswordSuccessMessage;
    }

    throw AuthApiException(
      '${ApiClient.errorMessageForStatus(response.statusCode, data, fallback: 'Could not send reset password link. Please try again.')} (HTTP ${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>?> me({required String token}) {
    return _sendProtectedAuthRequest(
      method: 'GET',
      endpoint: '/v1/auth/me',
      token: token,
      fallback: 'Failed to load account details.',
    );
  }

  Future<void> logout({required String token}) async {
    await _sendProtectedAuthRequest(
      method: 'POST',
      endpoint: '/v1/auth/logout',
      token: token,
      fallback: 'Failed to log out.',
    );
  }

  Map<String, String> authorizationHeaders(String token) {
    return ApiClient.jsonHeaders(token: token);
  }

  Future<AuthResult> _sendAuthRequest({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    http.Response response;
    try {
      response = await _apiClient.request(
        method: 'POST',
        endpoint: endpoint,
        body: payload,
      );
    } on ApiClientException catch (error) {
      throw AuthApiException(error.message);
    }

    final data = ApiClient.decodeMap(response.body);
    if (data.isEmpty &&
        response.body.isNotEmpty &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      throw const AuthApiException(
        'Server returned an unreadable response format.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final result = AuthResult.fromJson(data);
      if (result.token == null || result.token!.trim().isEmpty) {
        throw const AuthApiException(
          'Login succeeded but the server did not return an auth token.',
        );
      }
      return result;
    }

    throw AuthApiException(
      '${ApiClient.errorMessageForStatus(response.statusCode, data, fallback: 'Request failed. Please try again.')} (HTTP ${response.statusCode})',
    );
  }

  Future<Map<String, dynamic>?> _sendProtectedAuthRequest({
    required String method,
    required String endpoint,
    required String token,
    required String fallback,
  }) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const AuthApiException('Missing authentication token.');
    }

    http.Response response;
    try {
      response = await _apiClient.request(
        method: method,
        endpoint: endpoint,
        token: cleanedToken,
      );
    } on ApiClientException catch (error) {
      throw AuthApiException(error.message);
    }

    final data = ApiClient.decodeMap(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final payload = data['data'];
      return payload is Map<String, dynamic> ? payload : data;
    }

    throw AuthApiException(
      '${ApiClient.errorMessageForStatus(response.statusCode, data, fallback: fallback)} (HTTP ${response.statusCode})',
    );
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
