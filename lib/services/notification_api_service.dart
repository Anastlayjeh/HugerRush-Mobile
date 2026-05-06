import '../models/auth_session.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'authenticated_api_client.dart';

class NotificationApiService {
  NotificationApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<List<AppNotification>> fetchNotifications({
    required AuthSession session,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/notifications',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load notifications.',
    );
    return _extractList(
      payload,
    ).map(AppNotification.fromJson).toList(growable: false);
  }

  Future<AppNotification?> markAsRead({
    required AuthSession session,
    required String notificationId,
  }) async {
    final cleanedId = notificationId.trim();
    if (cleanedId.isEmpty) {
      return null;
    }

    final result = await _apiClient.request(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/notifications/$cleanedId/read',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to update notification.',
    );

    final data = payload['data'];
    if (data is Map) {
      return AppNotification.fromJson(_stringMap(data));
    }
    return null;
  }

  Future<void> markAllAsRead({required AuthSession session}) async {
    final result = await _apiClient.request(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/notifications/read-all',
    );
    _throwForFailure(
      result.response.statusCode,
      ApiClient.decodeMap(result.response.body),
      fallback: 'Failed to update notifications.',
    );
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map>().map(_stringMap).toList(growable: false);
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map(_stringMap)
          .toList(growable: false);
    }
    final notifications = payload['notifications'];
    if (notifications is List) {
      return notifications
          .whereType<Map>()
          .map(_stringMap)
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _stringMap(Map value) {
    final result = <String, dynamic>{};
    value.forEach((key, item) {
      if (key is String) {
        result[key] = item;
      }
    });
    return result;
  }

  void _throwForFailure(
    int statusCode,
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    if (statusCode == 401) {
      throw const AuthApiException(
        'Your session expired. Please log in again.',
      );
    }
    throw AuthApiException(
      '${ApiClient.errorMessageForStatus(statusCode, payload, fallback: fallback)} (HTTP $statusCode)',
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = _mapValue(json['data']);
    final readAt = _dateValue(json['read_at'] ?? data['read_at']);
    final isRead =
        readAt != null ||
        _boolValue(json['read']) ||
        _boolValue(json['is_read']) ||
        _boolValue(data['read']) ||
        _boolValue(data['is_read']);

    return AppNotification(
      id:
          _firstNonEmptyString(<Object?>[
            json['id'],
            json['notification_id'],
            data['id'],
          ]) ??
          '',
      title:
          _firstNonEmptyString(<Object?>[
            json['title'],
            json['subject'],
            data['title'],
            data['subject'],
            _titleFromType(json['type']),
          ]) ??
          'Notification',
      body:
          _firstNonEmptyString(<Object?>[
            json['body'],
            json['message'],
            json['description'],
            data['body'],
            data['message'],
            data['text'],
            data['description'],
          ]) ??
          '',
      createdAt: _dateValue(json['created_at'] ?? data['created_at']),
      readAt: readAt,
      isRead: isRead,
    );
  }

  static Map<String, dynamic> _mapValue(Object? value) {
    if (value is! Map) {
      return const <String, dynamic>{};
    }
    final result = <String, dynamic>{};
    value.forEach((key, item) {
      if (key is String) {
        result[key] = item;
      }
    });
    return result;
  }

  static String? _firstNonEmptyString(Iterable<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }
    return null;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim())?.toLocal();
    }
    return null;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'read';
    }
    return false;
  }

  static String? _titleFromType(Object? value) {
    final raw = value is String ? value.trim() : '';
    if (raw.isEmpty) {
      return null;
    }
    final className = raw.split('\\').last;
    final words = className
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    return words.isEmpty ? null : words;
  }
}
