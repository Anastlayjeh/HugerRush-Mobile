import '../models/auth_session.dart';
import 'api_client.dart';
import 'authenticated_api_client.dart';

class LoyaltyApiService {
  LoyaltyApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<CustomerLoyaltyOverview> fetchCustomerLoyaltyPoints({
    required AuthSession session,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/loyalty/points',
      fallback: 'Failed to load loyalty points.',
    );

    final restaurants =
        _extractListFromPayload(payload, const ['restaurants', 'items'])
            .map(CustomerRestaurantLoyaltyPoints.fromJson)
            .where((item) => item.pointsBalance > 0)
            .toList(growable: false);
    return CustomerLoyaltyOverview(
      restaurants: restaurants,
      totalPointsBalance: restaurants.fold<int>(
        0,
        (total, item) => total + item.pointsBalance,
      ),
      totalPointsEarned: restaurants.fold<int>(
        0,
        (total, item) => total + item.totalEarned,
      ),
      totalPointsRedeemed: restaurants.fold<int>(
        0,
        (total, item) => total + item.totalRedeemed,
      ),
    );
  }

  Future<CustomerRestaurantLoyaltyPoints> fetchCustomerRestaurantPoints({
    required AuthSession session,
    required String restaurantId,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return const CustomerRestaurantLoyaltyPoints(
        restaurantId: '',
        restaurantName: 'Restaurant',
        pointsBalance: 0,
        totalEarned: 0,
        totalRedeemed: 0,
        restaurantAddress: '',
        restaurantPhone: '',
      );
    }

    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/loyalty/points/$cleanedRestaurantId',
      fallback: 'Failed to load restaurant loyalty points.',
    );
    return CustomerRestaurantLoyaltyPoints.fromJson(payload);
  }

  Future<List<LoyaltyOffer>> fetchActiveOffersForRestaurant({
    required AuthSession session,
    required String restaurantId,
  }) async {
    final cleanedRestaurantId = restaurantId.trim();
    if (cleanedRestaurantId.isEmpty) {
      return const <LoyaltyOffer>[];
    }
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/restaurants/$cleanedRestaurantId/loyalty-offers',
      fallback: 'Failed to load loyalty offers.',
      keepListData: true,
    );
    return _extractListFromPayload(payload, const [
      'data',
      'offers',
    ]).map(LoyaltyOffer.fromJson).toList(growable: false);
  }

  Future<CustomerRestaurantLoyaltyPoints> redeemOffer({
    required AuthSession session,
    required String offerId,
  }) async {
    final cleanedOfferId = offerId.trim();
    if (cleanedOfferId.isEmpty) {
      throw const LoyaltyApiException('Offer is required.');
    }
    final payload = await _requestObject(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/loyalty/offers/$cleanedOfferId/redeem',
      fallback: 'Could not redeem loyalty offer.',
    );
    final pointsMap = _stringMap(payload['points']);
    final restaurant = _stringMap(payload['restaurant']);
    return CustomerRestaurantLoyaltyPoints(
      restaurantId:
          _readString(pointsMap['restaurant_id']) ??
          _readString(restaurant['id']) ??
          '',
      restaurantName: _readString(restaurant['name']) ?? 'Restaurant',
      pointsBalance: _readInt(pointsMap['points_balance']) ?? 0,
      totalEarned: _readInt(pointsMap['total_earned']) ?? 0,
      totalRedeemed: _readInt(pointsMap['total_redeemed']) ?? 0,
      restaurantAddress: _readString(restaurant['address']) ?? '',
      restaurantPhone: _readString(restaurant['phone']) ?? '',
    );
  }

  Future<List<LoyaltyOffer>> fetchOwnerLoyaltyOffers({
    required AuthSession session,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/loyalty/offers',
      fallback: 'Failed to load loyalty offers.',
      keepListData: true,
    );
    return _extractListFromPayload(payload, const [
      'data',
      'offers',
    ]).map(LoyaltyOffer.fromJson).toList(growable: false);
  }

  Future<LoyaltyOffer> createOwnerLoyaltyOffer({
    required AuthSession session,
    required String title,
    String description = '',
    required int requiredPoints,
    bool isActive = true,
  }) async {
    final payload = await _requestObject(
      session: session,
      method: 'POST',
      endpoint: '/v1/restaurant/loyalty/offers',
      body: <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'required_points': requiredPoints,
        'is_active': isActive,
      },
      fallback: 'Could not create loyalty offer.',
    );
    return LoyaltyOffer.fromJson(payload);
  }

  Future<LoyaltyOffer> updateOwnerLoyaltyOffer({
    required AuthSession session,
    required String offerId,
    required Map<String, dynamic> body,
  }) async {
    final cleanedOfferId = offerId.trim();
    if (cleanedOfferId.isEmpty) {
      throw const LoyaltyApiException('Offer is required.');
    }
    final payload = await _requestObject(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/loyalty/offers/$cleanedOfferId',
      body: body,
      fallback: 'Could not update loyalty offer.',
    );
    return LoyaltyOffer.fromJson(payload);
  }

  Future<Map<String, dynamic>> _requestObject({
    required AuthSession session,
    required String method,
    required String endpoint,
    Object? body,
    required String fallback,
    bool keepListData = false,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: method,
      endpoint: endpoint,
      body: body,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(result.response.statusCode, payload, fallback: fallback);
    if (keepListData) {
      return payload;
    }
    return _extractObject(payload);
  }
}

class CustomerLoyaltyOverview {
  const CustomerLoyaltyOverview({
    required this.restaurants,
    required this.totalPointsBalance,
    required this.totalPointsEarned,
    required this.totalPointsRedeemed,
  });

  final List<CustomerRestaurantLoyaltyPoints> restaurants;
  final int totalPointsBalance;
  final int totalPointsEarned;
  final int totalPointsRedeemed;
}

class CustomerRestaurantLoyaltyPoints {
  const CustomerRestaurantLoyaltyPoints({
    required this.restaurantId,
    required this.restaurantName,
    required this.pointsBalance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.restaurantAddress,
    required this.restaurantPhone,
  });

  final String restaurantId;
  final String restaurantName;
  final int pointsBalance;
  final int totalEarned;
  final int totalRedeemed;
  final String restaurantAddress;
  final String restaurantPhone;

  factory CustomerRestaurantLoyaltyPoints.fromJson(Map<String, dynamic> json) {
    final restaurant = _stringMap(json['restaurant']);
    return CustomerRestaurantLoyaltyPoints(
      restaurantId:
          _readString(json['restaurant_id']) ??
          _readString(restaurant['id']) ??
          '',
      restaurantName:
          _readString(restaurant['name']) ??
          _readString(json['restaurant_name']) ??
          'Restaurant',
      pointsBalance:
          _readInt(json['points_balance']) ??
          _readInt(json['points']) ??
          _readInt(json['balance']) ??
          0,
      totalEarned: _readInt(json['total_earned']) ?? 0,
      totalRedeemed: _readInt(json['total_redeemed']) ?? 0,
      restaurantAddress:
          _readString(restaurant['address']) ??
          _readString(json['restaurant_address']) ??
          '',
      restaurantPhone:
          _readString(restaurant['phone']) ??
          _readString(json['restaurant_phone']) ??
          '',
    );
  }
}

class LoyaltyOffer {
  const LoyaltyOffer({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.isActive,
  });

  final String id;
  final String restaurantId;
  final String title;
  final String description;
  final int requiredPoints;
  final bool isActive;

  factory LoyaltyOffer.fromJson(Map<String, dynamic> json) {
    return LoyaltyOffer(
      id: _readString(json['id']) ?? '',
      restaurantId: _readString(json['restaurant_id']) ?? '',
      title: _readString(json['title']) ?? 'Offer',
      description: _readString(json['description']) ?? '',
      requiredPoints: _readInt(json['required_points']) ?? 0,
      isActive: _readBool(json['is_active']) ?? true,
    );
  }
}

class LoyaltyApiException implements Exception {
  const LoyaltyApiException(this.message);

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

List<Map<String, dynamic>> _extractListFromPayload(
  Map<String, dynamic> payload,
  List<String> preferredKeys,
) {
  final candidates = <dynamic>[];

  for (final key in preferredKeys) {
    candidates.add(payload[key]);
  }

  final data = payload['data'];
  if (data is Map) {
    final mapped = _stringMap(data);
    for (final key in preferredKeys) {
      candidates.add(mapped[key]);
    }
  } else {
    candidates.add(data);
  }

  for (final candidate in candidates) {
    if (candidate is List) {
      return candidate.whereType<Map>().map(_stringMap).toList(growable: false);
    }
  }
  return const <Map<String, dynamic>>[];
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
  throw LoyaltyApiException(
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

bool? _readBool(dynamic value) {
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
  return null;
}
