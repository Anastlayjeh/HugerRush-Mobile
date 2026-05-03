import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class SupportReportApiService {
  SupportReportApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<void> submitSupportRequest({
    required String token,
    required String channel,
    required String subject,
    required String message,
  }) async {
    await _post(
      '/api/v1/support-requests',
      token: token,
      body: <String, dynamic>{
        'channel': channel,
        'subject': subject,
        'message': message,
      },
    );
  }

  Future<void> submitReport({
    required String token,
    required String subject,
    required String message,
    String? restaurantId,
    String? orderId,
  }) async {
    await _post(
      '/api/v1/reports',
      token: token,
      body: <String, dynamic>{
        'subject': subject,
        'message': message,
        if (restaurantId != null && restaurantId.trim().isNotEmpty)
          'restaurant_id': restaurantId,
        if (orderId != null && orderId.trim().isNotEmpty) 'order_id': orderId,
      },
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<void> _post(
    String endpoint, {
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const SupportReportApiException(
        'Missing authentication token. Please log in again.',
      );
    }
    try {
      final response = await _client.post(
        AppConfig.apiUri(endpoint),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanedToken',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      final payload = _decodeMap(response.body);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const SupportReportApiException(
          'Your session expired. Please log in again.',
        );
      }
      throw SupportReportApiException(
        _extractError(payload) ?? 'Request could not be submitted.',
      );
    } on SupportReportApiException {
      rethrow;
    } catch (_) {
      throw const SupportReportApiException(
        'Unable to reach the server. Check your connection and try again.',
      );
    }
  }
}

class SupportReportApiException implements Exception {
  const SupportReportApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _decodeMap(String body) {
  if (body.trim().isEmpty) {
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    return <String, dynamic>{};
  }
  return <String, dynamic>{};
}

String? _extractError(Map<String, dynamic> payload) {
  final message = payload['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }
  final errors = payload['errors'];
  if (errors is Map) {
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty && value.first is String) {
        return (value.first as String).trim();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  }
  return null;
}
