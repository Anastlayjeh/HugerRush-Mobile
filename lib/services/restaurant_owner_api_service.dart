import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/demo_app_models.dart';

class RestaurantOwnerApiService {
  RestaurantOwnerApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<OwnerOrder>> fetchOrders({required String token}) async {
    final payload = await _request(
      'GET',
      '/api/v1/restaurant/orders',
      token: token,
    );
    return _extractList(
      _unwrapData(payload),
    ).map(OwnerOrder.fromJson).toList(growable: false);
  }

  Future<RestaurantAnalyticsSnapshot> fetchAnalytics({
    required String token,
  }) async {
    final payload = await _request(
      'GET',
      '/api/v1/restaurant/analytics',
      token: token,
    );
    return RestaurantAnalyticsSnapshot.fromJson(
      _asMap(_unwrapData(payload)) ?? payload,
    );
  }

  Future<List<OwnerReview>> fetchReviews({required String token}) async {
    final payload = await _request(
      'GET',
      '/api/v1/restaurant/reviews',
      token: token,
    );
    return _extractList(
      _unwrapData(payload),
    ).map(OwnerReview.fromJson).toList(growable: false);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    required String token,
  }) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const RestaurantOwnerApiException(
        'Missing authentication token. Please log in again.',
      );
    }
    try {
      final response = await _client.get(
        AppConfig.apiUri(endpoint),
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $cleanedToken',
        },
      );
      final payload = _decodeMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return payload;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const RestaurantOwnerApiException(
          'Your session expired. Please log in again.',
        );
      }
      throw RestaurantOwnerApiException(
        _extractError(payload) ?? 'Restaurant request failed.',
      );
    } on RestaurantOwnerApiException {
      rethrow;
    } catch (_) {
      throw const RestaurantOwnerApiException(
        'Unable to reach the server. Check your connection and try again.',
      );
    }
  }
}

class OwnerOrder {
  const OwnerOrder({
    required this.id,
    required this.customerName,
    required this.itemSummary,
    required this.status,
    required this.total,
    required this.channelLabel,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final String itemSummary;
  final String status;
  final double total;
  final String channelLabel;
  final DateTime? createdAt;

  bool get completed {
    final normalized = status.toLowerCase();
    return normalized == 'delivered' ||
        normalized == 'completed' ||
        normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'rejected';
  }

  DemoOrder toDemoOrder() {
    return DemoOrder(
      id: '#$id',
      customerName: customerName,
      itemSummary: itemSummary,
      etaLabel: completed ? 'Done' : 'Live',
      statusLabel: _titleCase(status.replaceAll('_', ' ')),
      channelLabel: channelLabel,
      highlighted: !completed,
      totalLabel: '\$${total.toStringAsFixed(2)}',
      completed: completed,
    );
  }

  factory OwnerOrder.fromJson(Map<String, dynamic> json) {
    final customer = _asMap(json['customer']);
    final items = _extractList(json['items']);
    final itemSummary = items.isEmpty
        ? 'Order #${_firstString(json, const ['id', 'order_id']) ?? ''}'
        : items
                  .take(2)
                  .map((item) {
                    final menu = _asMap(item['menu_item']);
                    final qty = _firstInt(item, const ['quantity', 'qty']) ?? 1;
                    final name =
                        _firstString(menu, const ['name', 'title']) ??
                        _firstString(item, const ['name', 'title']) ??
                        'Item';
                    return '${qty}x $name';
                  })
                  .join(', ') +
              (items.length > 2 ? ' +${items.length - 2} more' : '');
    return OwnerOrder(
      id: _firstString(json, const ['id', 'order_id']) ?? '',
      customerName:
          _firstString(customer, const ['name', 'full_name']) ?? 'Customer',
      itemSummary: itemSummary,
      status: _firstString(json, const ['status']) ?? 'pending',
      total: _firstDouble(json, const ['total']) ?? 0,
      channelLabel:
          _firstString(json, const ['channel', 'source']) ?? 'App order',
      createdAt: _firstDateTime(json, const ['created_at', 'placed_at']),
    );
  }
}

class RestaurantAnalyticsSnapshot {
  const RestaurantAnalyticsSnapshot({
    required this.ordersToday,
    required this.revenueToday,
    required this.ordersInProgress,
    required this.averageOrderValue,
  });

  final int ordersToday;
  final double revenueToday;
  final int ordersInProgress;
  final double averageOrderValue;

  factory RestaurantAnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    final overview = _asMap(json['overview']) ?? _asMap(json['stats']) ?? json;
    return RestaurantAnalyticsSnapshot(
      ordersToday:
          _firstInt(overview, const [
            'orders_today',
            'completed_orders_today',
            'orders',
          ]) ??
          0,
      revenueToday:
          _firstDouble(overview, const [
            'revenue_today',
            'today_revenue',
            'revenue',
          ]) ??
          0,
      ordersInProgress:
          _firstInt(overview, const [
            'orders_in_progress',
            'active_orders',
            'pending_orders',
          ]) ??
          0,
      averageOrderValue:
          _firstDouble(overview, const [
            'average_order_value',
            'avg_order_value',
          ]) ??
          0,
    );
  }
}

class OwnerReview {
  const OwnerReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.orderLabel,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final double rating;
  final String comment;
  final String orderLabel;
  final DateTime? createdAt;

  factory OwnerReview.fromJson(Map<String, dynamic> json) {
    final customer = _asMap(json['customer']);
    final orderId = _firstString(json, const ['order_id']);
    return OwnerReview(
      id: _firstString(json, const ['id', 'review_id']) ?? '',
      customerName:
          _firstString(customer, const ['name', 'full_name']) ?? 'Customer',
      rating: _firstDouble(json, const ['rating']) ?? 0,
      comment: _firstString(json, const ['comment', 'body', 'message']) ?? '',
      orderLabel: orderId == null || orderId.isEmpty ? 'Order' : '#$orderId',
      createdAt: _firstDateTime(json, const ['created_at']),
    );
  }
}

class RestaurantOwnerApiException implements Exception {
  const RestaurantOwnerApiException(this.message);

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
    return _asMap(decoded) ?? <String, dynamic>{};
  } catch (_) {
    return <String, dynamic>{};
  }
}

dynamic _unwrapData(Map<String, dynamic> payload) =>
    payload['data'] ?? payload['result'] ?? payload;

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    final mapped = <String, dynamic>{};
    value.forEach((key, dynamic item) {
      if (key is String) {
        mapped[key] = item;
      }
    });
    return mapped;
  }
  return null;
}

List<Map<String, dynamic>> _extractList(dynamic value) {
  if (value is List) {
    return [
      for (final item in value)
        if (_asMap(item) != null) _asMap(item)!,
    ];
  }
  final map = _asMap(value);
  if (map != null) {
    for (final key in const ['data', 'items', 'orders', 'reviews']) {
      final list = _extractList(map[key]);
      if (list.isNotEmpty) {
        return list;
      }
    }
  }
  return const <Map<String, dynamic>>[];
}

String? _extractError(Map<String, dynamic> payload) {
  final message = payload['message'];
  return message is String && message.trim().isNotEmpty ? message.trim() : null;
}

String? _firstString(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) {
    return null;
  }
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

double? _firstDouble(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) {
    return null;
  }
  for (final key in keys) {
    final value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

int? _firstInt(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) {
    return null;
  }
  for (final key in keys) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

DateTime? _firstDateTime(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
  }
  return null;
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
