import '../models/auth_session.dart';
import 'api_client.dart';
import 'authenticated_api_client.dart';

class CustomerProfileApiService {
  CustomerProfileApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<CustomerProfile> fetchProfile({required AuthSession session}) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/profile',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load profile.',
    );
    return CustomerProfile.fromJson(_extractObject(payload));
  }

  Future<CustomerProfile> updateProfile({
    required AuthSession session,
    required String name,
    required String email,
    String phone = '',
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/customer/profile',
      body: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
      },
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not update profile.',
    );
    return CustomerProfile.fromJson(_extractObject(payload));
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.avatarUrl,
    this.ordersCount,
    this.followingCount,
    this.notificationsCount,
    this.points,
    this.rewardsCount,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String avatarUrl;
  final int? ordersCount;
  final int? followingCount;
  final int? notificationsCount;
  final int? points;
  final int? rewardsCount;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: _readString(json['id']) ?? '',
      name: _readString(json['name']) ?? 'FoodExplorer',
      email: _readString(json['email']) ?? '',
      phone: _readString(json['phone']) ?? '',
      role: _readString(json['role']) ?? 'customer',
      status: _readString(json['status']) ?? '',
      avatarUrl:
          _readString(json['avatar_url']) ??
          _readString(json['avatar']) ??
          _readString(json['picture']) ??
          '',
      ordersCount: _firstInt(json, const ['orders_count', 'ordersCount']),
      followingCount: _firstInt(json, const [
        'following_count',
        'followingCount',
      ]),
      notificationsCount: _firstInt(json, const [
        'notifications_count',
        'notificationsCount',
        'unread_notifications_count',
      ]),
      points: _firstInt(json, const [
        'points',
        'loyalty_points',
        'points_balance',
      ]),
      rewardsCount: _firstInt(json, const [
        'rewards_count',
        'active_rewards_count',
      ]),
    );
  }

  Map<String, dynamic> toSessionUser() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'avatar_url': avatarUrl,
    };
  }
}

class CustomerProfileApiException implements Exception {
  const CustomerProfileApiException(this.message);

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
  throw CustomerProfileApiException(
    '${ApiClient.errorMessageForStatus(statusCode, payload, fallback: fallback)} (HTTP $statusCode)',
  );
}

int? _firstInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _readInt(map[key]);
    if (value != null) {
      return value;
    }
  }
  return null;
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
