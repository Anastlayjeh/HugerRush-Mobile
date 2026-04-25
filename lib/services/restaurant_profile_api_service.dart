import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class RestaurantProfileApiService {
  RestaurantProfileApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const List<String> _candidateEndpoints = [
    '/api/v1/restaurant/profile',
    '/api/v1/restaurants/profile',
    '/api/v1/restaurants/me',
    '/api/v1/profile',
    '/api/v1/auth/me',
    '/api/user',
  ];

  Future<Map<String, dynamic>> fetchProfile({required String token}) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const RestaurantProfileApiException(
        'Missing authentication token for profile request.',
      );
    }

    String? lastError;
    for (final endpoint in _candidateEndpoints) {
      http.Response response;
      try {
        response = await _client.get(
          AppConfig.apiUri(endpoint),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $cleanedToken',
          },
        );
      } catch (_) {
        lastError =
            'Unable to reach the server. Check your API URL and internet connection.';
        continue;
      }

      final payload = _decodeMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _extractProfileMap(payload);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const RestaurantProfileApiException(
          'Your session expired. Please log in again.',
        );
      }

      if (response.statusCode == 404) {
        continue;
      }

      lastError = _extractError(payload) ?? 'Failed to load restaurant profile.';
    }

    if (lastError == null) {
      return <String, dynamic>{};
    }

    throw RestaurantProfileApiException(lastError);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Map<String, dynamic> _decodeMap(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractProfileMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final restaurant = data['restaurant'];
      final user = data['user'];
      if (restaurant is Map<String, dynamic> && user is Map<String, dynamic>) {
        return <String, dynamic>{...user, ...restaurant};
      }
      if (restaurant is Map<String, dynamic>) {
        return restaurant;
      }
      if (user is Map<String, dynamic>) {
        return user;
      }
      return data;
    }

    final restaurant = payload['restaurant'];
    if (restaurant is Map<String, dynamic>) {
      return restaurant;
    }

    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }

    return payload;
  }

  String? _extractError(Map<String, dynamic> payload) {
    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final errors = payload['errors'];
    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first;
          }
        }
      }
    }

    return null;
  }
}

class RestaurantProfileApiException implements Exception {
  const RestaurantProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
