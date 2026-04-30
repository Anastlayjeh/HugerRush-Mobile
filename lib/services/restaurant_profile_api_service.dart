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
  static const List<String> _candidateFollowersEndpoints = [
    '/api/v1/restaurant/followers',
    '/api/v1/restaurants/me/followers',
    '/api/v1/profile/followers',
    '/api/v1/followers',
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

  Future<List<RestaurantFollower>> fetchFollowers({
    required String token,
    String? restaurantId,
  }) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const RestaurantProfileApiException(
        'Missing authentication token for followers request.',
      );
    }

    final cleanedRestaurantId = restaurantId?.trim();
    final endpoints = <String>[
      ..._candidateFollowersEndpoints,
      if (cleanedRestaurantId != null && cleanedRestaurantId.isNotEmpty)
        '/api/v1/restaurants/$cleanedRestaurantId/followers',
      if (cleanedRestaurantId != null && cleanedRestaurantId.isNotEmpty)
        '/api/v1/restaurant/$cleanedRestaurantId/followers',
    ];

    String? lastError;
    for (final endpoint in endpoints) {
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
        return _extractFollowers(payload);
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const RestaurantProfileApiException(
          'Your session expired. Please log in again.',
        );
      }

      if (response.statusCode == 404) {
        continue;
      }

      lastError =
          _extractError(payload) ?? 'Failed to load followers for this page.';
    }

    if (lastError == null) {
      return const <RestaurantFollower>[];
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

  List<RestaurantFollower> _extractFollowers(Map<String, dynamic> payload) {
    final directCandidates = <dynamic>[
      payload['followers'],
      payload['users'],
      payload['results'],
      payload['data'],
      payload['data'] is Map ? payload['data']['followers'] : null,
      payload['data'] is Map ? payload['data']['users'] : null,
      payload['data'] is Map ? payload['data']['items'] : null,
      payload['data'] is Map ? payload['data']['results'] : null,
    ];

    for (final candidate in directCandidates) {
      final parsed = _extractFollowersFromNode(candidate);
      if (parsed.isNotEmpty) {
        return _dedupeFollowers(parsed);
      }
    }

    final deepResult = <RestaurantFollower>[];

    void visit(dynamic node, int depth) {
      if (depth > 4 || deepResult.isNotEmpty) {
        return;
      }

      final parsed = _extractFollowersFromNode(node);
      if (parsed.isNotEmpty) {
        deepResult.addAll(parsed);
        return;
      }

      if (node is Map) {
        for (final value in node.values) {
          if (value is Map || value is List) {
            visit(value, depth + 1);
            if (deepResult.isNotEmpty) {
              return;
            }
          }
        }
        return;
      }

      if (node is List) {
        for (final item in node) {
          if (item is Map || item is List) {
            visit(item, depth + 1);
            if (deepResult.isNotEmpty) {
              return;
            }
          }
        }
      }
    }

    visit(payload, 0);
    return _dedupeFollowers(deepResult);
  }

  List<RestaurantFollower> _extractFollowersFromNode(dynamic node) {
    if (node is List) {
      final parsed = <RestaurantFollower>[];
      for (final item in node) {
        if (item is Map) {
          final candidate = _mapWithStringKeys(item);
          final follower = RestaurantFollower.fromJson(
            _normalizeFollowerCandidate(candidate),
          );
          if (follower != null) {
            parsed.add(follower);
          }
        }
      }
      return parsed;
    }

    if (node is Map) {
      final candidate = _mapWithStringKeys(node);
      final nestedKeys = const [
        'followers',
        'users',
        'items',
        'list',
        'data',
        'results',
      ];
      for (final key in nestedKeys) {
        final nested = _extractFollowersFromNode(candidate[key]);
        if (nested.isNotEmpty) {
          return nested;
        }
      }

      if (_looksLikeFollower(candidate)) {
        final follower = RestaurantFollower.fromJson(
          _normalizeFollowerCandidate(candidate),
        );
        if (follower != null) {
          return <RestaurantFollower>[follower];
        }
      }
    }

    return const <RestaurantFollower>[];
  }

  Map<String, dynamic> _mapWithStringKeys(Map node) {
    final mapped = <String, dynamic>{};
    node.forEach((key, value) {
      if (key is String) {
        mapped[key] = value;
      }
    });
    return mapped;
  }

  Map<String, dynamic> _normalizeFollowerCandidate(Map<String, dynamic> map) {
    final nestedUserKeys = const [
      'user',
      'follower',
      'account',
      'customer',
      'owner',
      'profile',
    ];
    for (final key in nestedUserKeys) {
      final nested = map[key];
      if (nested is Map) {
        return <String, dynamic>{...map, ..._mapWithStringKeys(nested)};
      }
    }
    return map;
  }

  bool _looksLikeFollower(Map<String, dynamic> map) {
    return map.containsKey('name') ||
        map.containsKey('username') ||
        map.containsKey('handle') ||
        map.containsKey('email') ||
        map.containsKey('user');
  }

  List<RestaurantFollower> _dedupeFollowers(List<RestaurantFollower> input) {
    final unique = <String, RestaurantFollower>{};
    for (final follower in input) {
      unique[follower.id] = follower;
    }
    return unique.values.toList();
  }
}

class RestaurantProfileApiException implements Exception {
  const RestaurantProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RestaurantFollower {
  const RestaurantFollower({
    required this.id,
    required this.name,
    this.handle,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? handle;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  String? get secondaryLabel {
    final cleanedHandle = handle?.trim();
    if (cleanedHandle != null && cleanedHandle.isNotEmpty) {
      return cleanedHandle.startsWith('@')
          ? cleanedHandle
          : '@$cleanedHandle';
    }
    final cleanedEmail = email?.trim();
    if (cleanedEmail != null && cleanedEmail.isNotEmpty) {
      return cleanedEmail;
    }
    final cleanedPhone = phone?.trim();
    if (cleanedPhone != null && cleanedPhone.isNotEmpty) {
      return cleanedPhone;
    }
    return null;
  }

  static RestaurantFollower? fromJson(Map<String, dynamic> json) {
    final id =
        _firstString(json, const [
          'id',
          'user_id',
          'follower_id',
          'uuid',
          'slug',
          'username',
        ]) ??
        _firstString(json, const ['email', 'phone', 'mobile']);

    final name =
        _firstString(json, const [
          'name',
          'full_name',
          'display_name',
          'customer_name',
        ]) ??
        _firstString(json, const ['username', 'handle']) ??
        'Follower';

    if (id == null) {
      if (name == 'Follower') {
        return null;
      }
      return RestaurantFollower(id: name, name: name);
    }

    return RestaurantFollower(
      id: id,
      name: name,
      handle: _firstString(json, const [
        'username',
        'handle',
        'user_name',
        'slug',
      ]),
      email: _firstString(json, const ['email']),
      phone: _firstString(json, const ['phone', 'mobile', 'phone_number']),
      avatarUrl: _firstString(json, const [
        'avatar_url',
        'avatar',
        'photo_url',
        'image_url',
        'image',
        'profile_image',
      ]),
    );
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String) {
        final cleaned = value.trim();
        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      } else if (value is num) {
        return value.toString();
      }
    }
    return null;
  }
}
