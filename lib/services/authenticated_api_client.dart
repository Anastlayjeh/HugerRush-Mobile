import 'package:http/http.dart' as http;

import '../config/api_config.dart';
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
  }) : _authSessionService = authSessionService,
       _onSessionExpired = onSessionExpired,
       _apiClient = ApiClient(client: client);

  final AuthSessionService _authSessionService;
  final Future<void> Function()? _onSessionExpired;
  final ApiClient _apiClient;

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

    await _expireSession();
    throw const AuthSessionExpiredException(
      'Session expired. Please log in again.',
    );
  }

  Future<AuthenticatedApiResult> multipartRequest({
    required AuthSession session,
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, String> fields = const <String, String>{},
    List<AuthenticatedMultipartFile> files =
        const <AuthenticatedMultipartFile>[],
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final response = await _sendMultipartWithAuth(
      method: method.trim().toUpperCase(),
      endpoint: endpoint,
      token: session.token,
      headers: headers,
      fields: fields,
      files: files,
      timeout: timeout,
    );

    if (response.statusCode == 401) {
      await _expireSession();
      throw const AuthSessionExpiredException(
        'Session expired. Please log in again.',
      );
    }

    return AuthenticatedApiResult(
      response: response,
      session: session,
      usedRefreshFlow: false,
    );
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

  Future<http.Response> _sendMultipartWithAuth({
    required String method,
    required String endpoint,
    required String token,
    required Duration timeout,
    required Map<String, String> fields,
    required List<AuthenticatedMultipartFile> files,
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.MultipartRequest(method, ApiConfig.apiUri(endpoint));
      request.headers.addAll(<String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
        ...?headers,
      });
      request.fields.addAll(fields);

      for (final file in files) {
        if (file.path != null && file.path!.trim().isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(
              file.field,
              file.path!.trim(),
              filename: file.filename,
            ),
          );
        } else if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              file.field,
              file.bytes!,
              filename: file.filename,
            ),
          );
        }
      }

      final streamed = await request.send().timeout(timeout);
      return http.Response.fromStream(streamed);
    } on ApiClientException catch (error) {
      throw AuthApiException(error.message);
    } catch (error) {
      throw const AuthApiException(
        'Unable to connect to server. Please check your internet connection.',
      );
    }
  }
}

class AuthenticatedMultipartFile {
  const AuthenticatedMultipartFile({
    required this.field,
    this.path,
    this.bytes,
    this.filename,
  });

  final String field;
  final String? path;
  final List<int>? bytes;
  final String? filename;
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
