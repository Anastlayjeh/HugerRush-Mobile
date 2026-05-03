import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class RestaurantMenuApiService {
  RestaurantMenuApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const List<String> _candidateEndpoints = [
    '/api/v1/restaurant/menu/items',
    '/api/v1/restaurant/menu-items',
    '/api/v1/restaurants/me/menu-items',
    '/api/v1/restaurant/menu',
    '/api/v1/restaurants/me/menu',
    '/api/v1/menu-items',
    '/api/v1/menu',
  ];

  Future<List<RestaurantMenuItem>> fetchMenu({required String token}) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const RestaurantMenuApiException(
        'Missing authentication token for menu request.',
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
        return _extractRawItems(payload)
            .map(RestaurantMenuItem.fromJson)
            .toList();
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const RestaurantMenuApiException(
          'Your session expired. Please log in again.',
        );
      }

      if (response.statusCode == 404) {
        continue;
      }

      lastError = _extractError(payload) ?? 'Failed to load restaurant menu.';
    }

    if (lastError == null) {
      return const <RestaurantMenuItem>[];
    }
    throw RestaurantMenuApiException(lastError);
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
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractRawItems(Map<String, dynamic> payload) {
    final directCandidates = <dynamic>[
      payload['items'],
      payload['menu_items'],
      payload['menu'],
      payload['data'],
      payload['data'] is Map ? payload['data']['items'] : null,
      payload['data'] is Map ? payload['data']['menu_items'] : null,
      payload['data'] is Map ? payload['data']['menu'] : null,
      payload['data'] is Map ? payload['data']['list'] : null,
    ];

    for (final candidate in directCandidates) {
      final parsed = _extractListOfMaps(candidate);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    final deepResult = <Map<String, dynamic>>[];

    void visit(dynamic node, int depth) {
      if (depth > 4) {
        return;
      }

      if (node is Map) {
        final list = _extractListOfMaps(node['items']) +
            _extractListOfMaps(node['menu_items']) +
            _extractListOfMaps(node['menu']) +
            _extractListOfMaps(node['data']);
        if (list.isNotEmpty) {
          deepResult.addAll(list);
          return;
        }
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
        final list = _extractListOfMaps(node);
        if (list.isNotEmpty) {
          deepResult.addAll(list);
          return;
        }
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
    return deepResult;
  }

  List<Map<String, dynamic>> _extractListOfMaps(dynamic node) {
    if (node is! List) {
      return const <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];
    for (final item in node) {
      if (item is Map) {
        final mapped = <String, dynamic>{};
        item.forEach((key, value) {
          if (key is String) {
            mapped[key] = value;
          }
        });
        if (_looksLikeMenuItem(mapped)) {
          result.add(mapped);
        }
      }
    }
    return result;
  }

  bool _looksLikeMenuItem(Map<String, dynamic> map) {
    return map.containsKey('name') ||
        map.containsKey('title') ||
        map.containsKey('item_name') ||
        map.containsKey('dish_name') ||
        map.containsKey('price');
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

class RestaurantMenuItem {
  const RestaurantMenuItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.isPopular,
    this.rating,
    this.ordersCount,
  });

  final String id;
  final String title;
  final String description;
  final double? price;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final bool isPopular;
  final double? rating;
  final int? ordersCount;

  factory RestaurantMenuItem.fromJson(Map<String, dynamic> json) {
    final title = _firstString(json, const [
          'title',
          'name',
          'item_name',
          'dish_name',
        ]) ??
        'Unnamed Item';
    final id =
        _firstString(json, const ['id', 'uuid', 'item_id', 'menu_item_id']) ??
        title;

    final statusValue = json['status'];
    final availabilityFromStatus = statusValue is String
        ? <String>['active', 'enabled', 'available', 'published']
            .contains(statusValue.trim().toLowerCase())
        : null;

    return RestaurantMenuItem(
      id: id,
      title: title,
      description: _firstString(json, const [
            'description',
            'details',
            'subtitle',
            'short_description',
          ]) ??
          'No description provided.',
      price: _firstDouble(json, const ['price', 'amount', 'cost']),
      imageUrl: _firstString(json, const [
            'image_url',
            'image',
            'photo_url',
            'thumbnail',
            'cover_image',
          ]) ??
          _firstImageUrl(json['image_urls']) ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
      category: _firstString(json, const [
            'category_name',
            'category',
            'section',
            'type',
            'cuisine',
          ]) ??
          'General',
      isAvailable:
          _firstBool(json, const ['is_available', 'available', 'in_stock']) ??
          availabilityFromStatus ??
          true,
      isPopular:
          _firstBool(json, const ['is_popular', 'popular', 'featured']) ?? false,
      rating: _firstDouble(json, const ['rating', 'avg_rating', 'average_rating']),
      ordersCount: _firstInt(json, const [
        'orders_count',
        'total_orders',
        'sold_count',
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
      }
      if (value is num) {
        return value.toString();
      }
    }
    return null;
  }

  static double? _firstDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final cleaned = value.trim();
        if (cleaned.isEmpty) {
          continue;
        }
        final parsed = double.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
        final match = RegExp(r'[-+]?\d*\.?\d+').firstMatch(cleaned);
        if (match != null) {
          final fallback = double.tryParse(match.group(0)!);
          if (fallback != null) {
            return fallback;
          }
        }
      }
    }
    return null;
  }

  static int? _firstInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final cleaned = value.trim();
        if (cleaned.isEmpty) {
          continue;
        }
        final parsed = int.tryParse(cleaned);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static bool? _firstBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == 'no' || normalized == '0') {
          return false;
        }
      }
    }
    return null;
  }

  static String? _firstImageUrl(dynamic value) {
    if (value is List) {
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) {
          return item.trim();
        }
      }
    }
    if (value is String && value.trim().isNotEmpty) {
      final trimmed = value.trim();
      try {
        final decoded = jsonDecode(trimmed);
        final fromDecoded = _firstImageUrl(decoded);
        if (fromDecoded != null) {
          return fromDecoded;
        }
      } catch (_) {
        return trimmed;
      }
      return trimmed;
    }
    return null;
  }
}

class RestaurantMenuApiException implements Exception {
  const RestaurantMenuApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
