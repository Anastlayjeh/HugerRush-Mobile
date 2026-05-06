import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const Duration defaultTimeout = Duration(seconds: 20);

  final http.Client _client;

  void close() => _client.close();

  Future<http.Response> request({
    required String method,
    required String endpoint,
    String? token,
    Map<String, String>? headers,
    Object? body,
    Duration timeout = defaultTimeout,
  }) async {
    final normalizedMethod = method.trim().toUpperCase();
    final normalizedBody = normalizeBody(body);
    final requestHeaders = jsonHeaders(token: token, extraHeaders: headers);
    final uri = ApiConfig.apiUri(endpoint);

    try {
      switch (normalizedMethod) {
        case 'GET':
          return await _client
              .get(uri, headers: requestHeaders)
              .timeout(timeout);
        case 'POST':
          return await _client
              .post(uri, headers: requestHeaders, body: normalizedBody)
              .timeout(timeout);
        case 'PUT':
          return await _client
              .put(uri, headers: requestHeaders, body: normalizedBody)
              .timeout(timeout);
        case 'PATCH':
          return await _client
              .patch(uri, headers: requestHeaders, body: normalizedBody)
              .timeout(timeout);
        case 'DELETE':
          return await _client
              .delete(uri, headers: requestHeaders, body: normalizedBody)
              .timeout(timeout);
      }
    } on TimeoutException {
      throw const ApiClientException(
        'Request timed out. Please check your connection and try again.',
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('API request failed: $error');
        debugPrint('$stackTrace');
      }
      throw const ApiClientException(
        'Unable to connect to server. Please check your internet connection.',
      );
    }

    throw ApiClientException('Unsupported HTTP method "$method".');
  }

  static Map<String, String> jsonHeaders({
    String? token,
    Map<String, String>? extraHeaders,
  }) {
    final cleanedToken = token?.trim();
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (cleanedToken != null && cleanedToken.isNotEmpty)
        'Authorization': 'Bearer $cleanedToken',
      ...?extraHeaders,
    };
  }

  static Object? normalizeBody(Object? body) {
    if (body == null || body is String || body is List<int>) {
      return body;
    }
    return jsonEncode(body);
  }

  static Map<String, dynamic> decodeMap(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  static String? extractLaravelError(Map<String, dynamic> payload) {
    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final errors = payload['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first.trim();
          }
        }
      }
    }

    return null;
  }

  static String errorMessageForStatus(
    int statusCode,
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final backendMessage = extractLaravelError(payload);
    if (backendMessage != null) {
      return backendMessage;
    }

    switch (statusCode) {
      case 401:
        return 'Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 422:
        return 'Please check the submitted information and try again.';
      case >= 500:
        return 'Server is temporarily unavailable. Please try again later.';
    }

    return fallback;
  }
}

class ApiClientException implements Exception {
  const ApiClientException(this.message);

  final String message;

  @override
  String toString() => message;
}
