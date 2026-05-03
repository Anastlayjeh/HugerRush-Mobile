import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/demo_app_models.dart';

class ConversationApiService {
  ConversationApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<List<DemoConversationThread>> fetchThreads({
    required String token,
  }) async {
    final payload = await _request(
      'GET',
      '/api/v1/conversations',
      token: token,
    );
    return _extractList(
      _unwrapData(payload),
    ).map(_threadFromJson).toList(growable: false);
  }

  Future<DemoConversationThread> fetchThread({
    required String token,
    required String threadId,
  }) async {
    final payload = await _request(
      'GET',
      '/api/v1/conversations/$threadId',
      token: token,
    );
    return _threadFromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<DemoConversationThread> markRead({
    required String token,
    required String threadId,
  }) async {
    await _request(
      'PATCH',
      '/api/v1/conversations/$threadId/read',
      token: token,
    );
    return fetchThread(token: token, threadId: threadId);
  }

  Future<DemoConversationThread> sendMessage({
    required String token,
    required String threadId,
    required String body,
  }) async {
    await _request(
      'POST',
      '/api/v1/conversations/$threadId/messages',
      token: token,
      body: <String, dynamic>{'body': body},
    );
    return fetchThread(token: token, threadId: threadId);
  }

  Future<DemoConversationThread> startConversation({
    required String token,
    required String restaurantId,
    required String subject,
    required String message,
    String? orderId,
  }) async {
    final payload = await _request(
      'POST',
      '/api/v1/conversations',
      token: token,
      body: <String, dynamic>{
        'restaurant_id': restaurantId,
        'subject': subject,
        'message': message,
        if (orderId != null && orderId.trim().isNotEmpty) 'order_id': orderId,
      },
    );
    return _threadFromJson(_asMap(_unwrapData(payload)) ?? payload);
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
    Map<String, dynamic>? body,
  }) async {
    final cleanedToken = token.trim();
    if (cleanedToken.isEmpty) {
      throw const ConversationApiException(
        'Missing authentication token. Please log in again.',
      );
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $cleanedToken',
      if (body != null) 'Content-Type': 'application/json',
    };
    try {
      final uri = AppConfig.apiUri(endpoint);
      final response = switch (method) {
        'GET' => await _client.get(uri, headers: headers),
        'POST' => await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        ),
        'PATCH' => await _client.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}),
        ),
        _ => throw ConversationApiException('Unsupported API method $method.'),
      };
      final payload = _decodeMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return payload;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const ConversationApiException(
          'Your session expired. Please log in again.',
        );
      }
      throw ConversationApiException(
        _extractError(payload) ?? 'Conversation request failed.',
      );
    } on ConversationApiException {
      rethrow;
    } catch (_) {
      throw const ConversationApiException(
        'Unable to reach the server. Check your connection and try again.',
      );
    }
  }
}

class ConversationApiException implements Exception {
  const ConversationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

DemoConversationThread _threadFromJson(Map<String, dynamic> json) {
  final customer = _asMap(json['customer']);
  final restaurant = _asMap(json['restaurant']);
  final latest = _asMap(json['latest_message']);
  final messages = _extractList(
    json['messages'],
  ).map(_messageFromJson).toList(growable: false);
  final lastBody =
      _firstString(latest, const ['body']) ??
      (messages.isEmpty ? 'No messages yet' : messages.last.body);
  final lastTime = _firstDateTime(latest ?? json, const [
    'created_at',
    'last_message_at',
    'updated_at',
  ]);
  final subject = _firstString(json, const ['subject']);
  return DemoConversationThread(
    id: _firstString(json, const ['id', 'conversation_id']) ?? '',
    customerName:
        _firstString(customer, const ['name', 'full_name']) ??
        _firstString(restaurant, const ['name', 'restaurant_name']) ??
        subject ??
        'Conversation',
    lastMessage: lastBody,
    timeLabel: _relativeLabel(lastTime),
    orderLabel: _firstString(json, const ['order_id']) == null
        ? (subject ?? 'General')
        : '#${_firstString(json, const ['order_id'])}',
    channelLabel: 'App chat',
    unreadCount: _firstInt(json, const ['unread_count']) ?? 0,
    priority: (_firstInt(json, const ['unread_count']) ?? 0) > 0,
    needsReply: _needsReply(messages),
    online: false,
    type: MessageThreadType.order,
    messages: messages,
  );
}

DemoConversationMessage _messageFromJson(Map<String, dynamic> json) {
  final sender = _asMap(json['sender']);
  final role = (_firstString(sender, const ['role']) ?? '').toLowerCase();
  final fromRestaurant =
      role.contains('restaurant') ||
      role.contains('owner') ||
      role.contains('staff');
  return DemoConversationMessage(
    id: _firstString(json, const ['id', 'message_id']) ?? '',
    senderName:
        _firstString(sender, const ['name', 'full_name']) ??
        (fromRestaurant ? 'Restaurant' : 'Customer'),
    body: _firstString(json, const ['body', 'message']) ?? '',
    sentAt:
        _firstDateTime(json, const ['created_at', 'sent_at']) ?? DateTime.now(),
    fromRestaurant: fromRestaurant,
  );
}

bool _needsReply(List<DemoConversationMessage> messages) {
  if (messages.isEmpty) {
    return false;
  }
  return !messages.last.fromRestaurant;
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
    for (final key in const ['data', 'items', 'messages', 'conversations']) {
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
