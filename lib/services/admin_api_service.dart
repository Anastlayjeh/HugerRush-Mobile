import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AdminApiService {
  AdminApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<AdminDashboardSnapshot> fetchDashboard({required String token}) async {
    final payload = await _get('/api/v1/admin/dashboard', token: token);
    return AdminDashboardSnapshot.fromJson(_asMap(payload['data']) ?? payload);
  }

  Future<List<Map<String, dynamic>>> fetchUsers({required String token}) async {
    final payload = await _get('/api/v1/admin/users', token: token);
    return _extractList(payload['data']);
  }

  Future<List<Map<String, dynamic>>> fetchRestaurants({
    required String token,
  }) async {
    final payload = await _get('/api/v1/admin/restaurants', token: token);
    return _extractList(payload['data']);
  }

  Future<List<Map<String, dynamic>>> fetchOrders({
    required String token,
  }) async {
    final payload = await _get('/api/v1/admin/orders', token: token);
    return _extractList(payload['data']);
  }

  Future<List<Map<String, dynamic>>> fetchReports({
    required String token,
  }) async {
    final payload = await _get('/api/v1/admin/reports', token: token);
    return _extractList(payload['data']);
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    required String token,
  }) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const AdminApiException(
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
        throw const AdminApiException(
          'Admin access denied or session expired.',
        );
      }
      throw AdminApiException(
        _extractError(payload) ?? 'Admin request failed.',
      );
    } on AdminApiException {
      rethrow;
    } catch (_) {
      throw const AdminApiException(
        'Unable to reach the server. Check your connection and try again.',
      );
    }
  }
}

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.stats,
    required this.recentOrders,
    required this.recentReports,
  });

  final Map<String, num> stats;
  final List<Map<String, dynamic>> recentOrders;
  final List<Map<String, dynamic>> recentReports;

  factory AdminDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final rawStats = _asMap(json['stats']) ?? const <String, dynamic>{};
    return AdminDashboardSnapshot(
      stats: <String, num>{
        for (final entry in rawStats.entries)
          if (entry.value is num) entry.key: entry.value as num,
      },
      recentOrders: _extractList(json['recent_orders']),
      recentReports: _extractList(json['recent_reports']),
    );
  }
}

class AdminApiException implements Exception {
  const AdminApiException(this.message);

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
    for (final key in const ['data', 'items']) {
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
