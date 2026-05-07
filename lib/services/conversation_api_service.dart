import '../models/auth_session.dart';
import 'api_client.dart';
import 'authenticated_api_client.dart';

class ConversationApiService {
  ConversationApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<List<AppConversation>> fetchConversations({
    required AuthSession session,
    String? query,
  }) async {
    final endpoint = query == null || query.trim().isEmpty
        ? '/v1/conversations'
        : Uri(
            path: '/v1/conversations',
            queryParameters: <String, String>{'q': query.trim()},
          ).toString();
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: endpoint,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load conversations.',
    );
    return _extractList(
      payload,
    ).map(AppConversation.fromJson).toList(growable: false);
  }

  Future<AppConversation> startConversation({
    required AuthSession session,
    required String restaurantId,
    String? orderId,
    String? subject,
    String? message,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      throw const ConversationApiException('Restaurant is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/conversations',
      body: <String, dynamic>{
        'restaurant_id': cleanedRestaurantId,
        if (orderId != null && orderId.trim().isNotEmpty)
          'order_id': orderId.trim(),
        if (subject != null && subject.trim().isNotEmpty)
          'subject': subject.trim(),
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not start conversation.',
    );
    return AppConversation.fromJson(_extractObject(payload));
  }

  Future<AppConversation> fetchConversation({
    required AuthSession session,
    required String conversationId,
  }) async {
    final cleanedConversationId = conversationId.trim();
    if (cleanedConversationId.isEmpty) {
      throw const ConversationApiException('Conversation is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/conversations/$cleanedConversationId',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load conversation.',
    );
    return AppConversation.fromJson(_extractObject(payload));
  }

  Future<AppConversationMessage> sendMessage({
    required AuthSession session,
    required String conversationId,
    required String body,
  }) async {
    final cleanedConversationId = conversationId.trim();
    final cleanedBody = body.trim();
    if (cleanedConversationId.isEmpty || cleanedBody.isEmpty) {
      throw const ConversationApiException('Message is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/conversations/$cleanedConversationId/messages',
      body: <String, dynamic>{'body': cleanedBody},
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not send message.',
    );
    return AppConversationMessage.fromJson(_extractObject(payload));
  }

  Future<void> markRead({
    required AuthSession session,
    required String conversationId,
  }) async {
    final cleanedConversationId = conversationId.trim();
    if (cleanedConversationId.isEmpty) {
      return;
    }

    final result = await _apiClient.request(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/conversations/$cleanedConversationId/read',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not mark conversation as read.',
    );
  }
}

class AppConversation {
  const AppConversation({
    required this.id,
    required this.restaurantId,
    required this.customerId,
    required this.orderId,
    required this.subject,
    required this.status,
    required this.restaurantName,
    required this.customerName,
    required this.latestMessage,
    required this.messages,
    required this.unreadCount,
    this.lastMessageAt,
  });

  final String id;
  final String restaurantId;
  final String customerId;
  final String orderId;
  final String subject;
  final String status;
  final String restaurantName;
  final String customerName;
  final AppConversationMessage? latestMessage;
  final List<AppConversationMessage> messages;
  final int unreadCount;
  final DateTime? lastMessageAt;

  String get displaySubject => subject.trim().isEmpty
      ? (orderId.isEmpty ? 'Conversation' : '#$orderId')
      : subject;

  String get previewText {
    final latest = latestMessage?.body.trim();
    if (latest != null && latest.isNotEmpty) {
      return latest;
    }
    if (messages.isNotEmpty) {
      return messages.last.body;
    }
    return 'No messages yet.';
  }

  factory AppConversation.fromJson(Map<String, dynamic> json) {
    final restaurant = _stringMap(json['restaurant']);
    final customer = _stringMap(json['customer']);
    final latestMessage = json['latest_message'] is Map
        ? AppConversationMessage.fromJson(_stringMap(json['latest_message']))
        : null;
    return AppConversation(
      id: _readString(json['id']) ?? '',
      restaurantId:
          _readString(json['restaurant_id']) ??
          _readString(restaurant['id']) ??
          '',
      customerId:
          _readString(json['customer_id']) ?? _readString(customer['id']) ?? '',
      orderId: _readString(json['order_id']) ?? '',
      subject: _readString(json['subject']) ?? '',
      status: _readString(json['status']) ?? '',
      restaurantName: _readString(restaurant['name']) ?? 'Restaurant',
      customerName: _readString(customer['name']) ?? 'Customer',
      latestMessage: latestMessage,
      messages: _listOfMaps(
        json['messages'],
      ).map(AppConversationMessage.fromJson).toList(growable: false),
      unreadCount: _readInt(json['unread_count']) ?? 0,
      lastMessageAt: _readDate(json['last_message_at']),
    );
  }
}

class AppConversationMessage {
  const AppConversationMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    this.createdAt,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String body;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get fromRestaurant {
    final role = senderRole.trim().toLowerCase();
    return role.contains('restaurant') ||
        role.contains('vendor') ||
        role.contains('merchant');
  }

  factory AppConversationMessage.fromJson(Map<String, dynamic> json) {
    final sender = _stringMap(json['sender']);
    return AppConversationMessage(
      id: _readString(json['id']) ?? '',
      conversationId: _readString(json['conversation_id']) ?? '',
      senderId:
          _readString(json['sender_id']) ?? _readString(sender['id']) ?? '',
      senderName: _readString(sender['name']) ?? 'User',
      senderRole: _readString(sender['role']) ?? '',
      body: _readString(json['body']) ?? '',
      createdAt: _readDate(json['created_at']),
      readAt: _readDate(json['read_at']),
    );
  }
}

class ConversationApiException implements Exception {
  const ConversationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _extractObject(Map<String, dynamic> payload) {
  final data = payload['data'];
  if (data is Map) {
    return _stringMap(data);
  }
  return payload;
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
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value.whereType<Map>().map(_stringMap).toList(growable: false);
}

Map<String, dynamic> _stringMap(dynamic value) {
  if (value is! Map) {
    return <String, dynamic>{};
  }
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
  throw ConversationApiException(
    '${ApiClient.errorMessageForStatus(statusCode, payload, fallback: fallback)} (HTTP $statusCode)',
  );
}

String? _readString(dynamic value) {
  if (value is String) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }
  if (value is num) {
    return value.toString();
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

DateTime? _readDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim())?.toLocal();
  }
  return null;
}
