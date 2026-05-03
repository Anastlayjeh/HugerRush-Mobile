import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/demo_app_models.dart';

class NotificationApiService {
  NotificationApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<DemoNotificationItem>> fetchNotifications({
    required String token,
  }) async {
    final payload = await _request(
      'GET',
      '/api/v1/notifications',
      token: token,
    );
    return _extractList(
      _unwrapData(payload),
    ).map(_notificationFromJson).toList(growable: false);
  }

  Future<List<DemoNotificationItem>> markAllRead({
    required String token,
  }) async {
    await _request('PATCH', '/api/v1/notifications/read-all', token: token);
    return fetchNotifications(token: token);
  }

  Future<DemoNotificationItem> markRead({
    required String token,
    required String notificationId,
  }) async {
    final payload = await _request(
      'PATCH',
      '/api/v1/notifications/$notificationId/read',
      token: token,
    );
    return _notificationFromJson(_asMap(_unwrapData(payload)) ?? payload);
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
      throw const NotificationApiException(
        'Missing authentication token. Please log in again.',
      );
    }
    try {
      final uri = AppConfig.apiUri(endpoint);
      final headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $cleanedToken',
      };
      final response = method == 'PATCH'
          ? await _client.patch(uri, headers: headers)
          : await _client.get(uri, headers: headers);
      final payload = _decodeMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return payload;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const NotificationApiException(
          'Your session expired. Please log in again.',
        );
      }
      throw NotificationApiException(
        _extractError(payload) ?? 'Notification request failed.',
      );
    } on NotificationApiException {
      rethrow;
    } catch (_) {
      throw const NotificationApiException(
        'Unable to reach the server. Check your connection and try again.',
      );
    }
  }
}

class NotificationApiException implements Exception {
  const NotificationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

DemoNotificationItem _notificationFromJson(Map<String, dynamic> json) {
  return DemoNotificationItem(
    id: _firstString(json, const ['id', 'notification_id']) ?? '',
    title: _firstString(json, const ['title', 'subject']) ?? 'Notification',
    body: _firstString(json, const ['body', 'message']) ?? '',
    timeLabel: _relativeLabel(_firstDateTime(json, const ['created_at'])),
    isRead: _firstBool(json, const ['is_read', 'read']) ?? false,
  );
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
    for (final key in const ['data', 'items', 'notifications']) {
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

bool? _firstBool(Map<String, dynamic> map, List<String> keys) {
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
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
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

String _relativeLabel(DateTime? value) {
  if (value == null) {
    return 'Now';
  }
  final delta = DateTime.now().difference(value);
  if (delta.inMinutes < 1) {
    return 'Now';
  }
  if (delta.inHours < 1) {
    return '${delta.inMinutes}m';
  }
  if (delta.inDays < 1) {
    return '${delta.inHours}h';
  }
  return '${delta.inDays}d';
}
