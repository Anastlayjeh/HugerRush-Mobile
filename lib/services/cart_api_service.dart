import '../models/auth_session.dart';
import 'api_client.dart';
import 'authenticated_api_client.dart';

class CustomerCartApiService {
  CustomerCartApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<List<CustomerCart>> fetchCarts({required AuthSession session}) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/carts',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load carts.',
    );
    return _extractListFromPayload(payload)
        .map(CustomerCart.fromJson)
        .where((cart) => cart.items.isNotEmpty)
        .toList(growable: false);
  }

  Future<CustomerCart> fetchCart({
    required AuthSession session,
    String? restaurantId,
    String? cartId,
  }) async {
    final queryParameters = <String, String>{
      if (restaurantId != null && restaurantId.trim().isNotEmpty)
        'restaurant_id': restaurantId.trim(),
      if (cartId != null && cartId.trim().isNotEmpty) 'cart_id': cartId.trim(),
    };
    final endpoint = queryParameters.isEmpty
        ? '/v1/customer/cart'
        : Uri(
            path: '/v1/customer/cart',
            queryParameters: queryParameters,
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
      fallback: 'Failed to load cart.',
    );
    return CustomerCart.fromJson(_extractObject(payload));
  }

  Future<CustomerCartItem> addItem({
    required AuthSession session,
    required String menuItemId,
    int quantity = 1,
    String notes = '',
    String? restaurantId,
  }) async {
    final cleanedMenuItemId = menuItemId.trim();
    if (cleanedMenuItemId.isEmpty) {
      throw const CustomerCartApiException('Menu item is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/cart/items',
      body: <String, dynamic>{
        'menu_item_id': cleanedMenuItemId,
        'quantity': quantity.clamp(1, 999),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (restaurantId != null && restaurantId.trim().isNotEmpty)
          'restaurant_id': restaurantId.trim(),
      },
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not add item to cart.',
    );
    return CustomerCartItem.fromJson(_extractObject(payload));
  }

  Future<CustomerCartItem> updateItem({
    required AuthSession session,
    required String cartItemId,
    required int quantity,
    String notes = '',
  }) async {
    final cleanedCartItemId = cartItemId.trim();
    if (cleanedCartItemId.isEmpty) {
      throw const CustomerCartApiException('Cart item is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/customer/cart/items/$cleanedCartItemId',
      body: <String, dynamic>{
        'quantity': quantity.clamp(1, 999),
        'notes': notes.trim(),
      },
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not update cart item.',
    );
    return CustomerCartItem.fromJson(_extractObject(payload));
  }

  Future<void> removeItem({
    required AuthSession session,
    required String cartItemId,
  }) async {
    final cleanedCartItemId = cartItemId.trim();
    if (cleanedCartItemId.isEmpty) {
      return;
    }

    final result = await _apiClient.request(
      session: session,
      method: 'DELETE',
      endpoint: '/v1/customer/cart/items/$cleanedCartItemId',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not remove cart item.',
    );
  }
}

class CustomerCart {
  const CustomerCart({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.fees,
    required this.total,
    required this.totalItems,
    this.loyaltyPointsEstimate = 0,
    this.loyaltyPointsUsed = 0,
    this.discount = 0,
    this.loyaltyOfferId,
    this.loyaltyOffer,
    this.totalLbp = 0,
    this.deliveryFee = 0,
  });

  final String id;
  final String restaurantId;
  final String restaurantName;
  final List<CustomerCartItem> items;
  final double subtotal;
  final double fees;
  final double total;
  final int totalItems;
  final int loyaltyPointsEstimate;
  final int loyaltyPointsUsed;
  final double discount;
  final String? loyaltyOfferId;
  final CartAppliedLoyaltyOffer? loyaltyOffer;
  final int totalLbp;
  final double deliveryFee;

  bool get isEmpty => items.isEmpty;

  factory CustomerCart.fromJson(Map<String, dynamic> json) {
    final restaurant = _stringMap(json['restaurant']);
    final items = _extractList(
      json['items'],
    ).map(CustomerCartItem.fromJson).toList(growable: false);
    return CustomerCart(
      id: _readString(json['id']) ?? '',
      restaurantId:
          _readString(json['restaurant_id']) ??
          _readString(restaurant['id']) ??
          '',
      restaurantName: _readString(restaurant['name']) ?? 'Restaurant',
      items: items,
      subtotal:
          _readDouble(json['subtotal']) ??
          _sum(items, (item) => item.lineTotal),
      fees: _readDouble(json['fees']) ?? _readDouble(json['delivery_fee']) ?? 0,
      deliveryFee:
          _readDouble(json['delivery_fee']) ?? _readDouble(json['fees']) ?? 0,
      total:
          _readDouble(json['total']) ??
          ((_readDouble(json['subtotal']) ??
                  _sum(items, (item) => item.lineTotal)) +
              (_readDouble(json['delivery_fee']) ??
                  _readDouble(json['fees']) ??
                  0) -
              (_readDouble(json['discount']) ?? 0)),
      totalItems:
          _readInt(json['total_items']) ??
          items.fold<int>(0, (sum, item) => sum + item.quantity),
      loyaltyPointsEstimate:
          _readInt(json['loyalty_points_estimate']) ??
          _readInt(json['loyalty_points_earned']) ??
          0,
      loyaltyPointsUsed: _readInt(json['loyalty_points_used']) ?? 0,
      discount: _readDouble(json['discount']) ?? 0,
      loyaltyOfferId:
          _readString(json['loyalty_offer_id']) ??
          _readString(_stringMap(json['loyalty_offer'])['id']),
      loyaltyOffer: _parseLoyaltyOffer(json['loyalty_offer']),
      totalLbp: _readInt(json['total_lbp']) ?? 0,
    );
  }
}

class CartAppliedLoyaltyOffer {
  const CartAppliedLoyaltyOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.isActive,
    this.rewardType,
    this.conditions,
    this.expiresAt,
    this.menuItemId,
    this.menuItemName,
    this.menuItemImageUrl,
    this.menuItemPrice,
    this.menuItemAvailable,
    this.freeItemQuantity = 1,
    this.discountPercentage,
    this.discountAmount,
    this.discountedPrice,
  });

  final String id;
  final String title;
  final String description;
  final int requiredPoints;
  final bool isActive;
  final String? rewardType;
  final String? conditions;
  final DateTime? expiresAt;
  final String? menuItemId;
  final String? menuItemName;
  final String? menuItemImageUrl;
  final double? menuItemPrice;
  final bool? menuItemAvailable;
  final int freeItemQuantity;
  final double? discountPercentage;
  final double? discountAmount;
  final double? discountedPrice;
}

class CustomerCartItem {
  const CustomerCartItem({
    required this.id,
    required this.menuItemId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.quantity,
    required this.notes,
    required this.unitPrice,
    required this.lineTotal,
    required this.isAvailable,
  });

  final String id;
  final String menuItemId;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final int quantity;
  final String notes;
  final double unitPrice;
  final double lineTotal;
  final bool isAvailable;

  factory CustomerCartItem.fromJson(Map<String, dynamic> json) {
    final menuItem = _stringMap(json['menu_item']);
    final category =
        _readString(menuItem['category']) ??
        _readString(menuItem['category_name']) ??
        '';
    final unitPrice =
        _readDouble(json['unit_price']) ?? _readDouble(menuItem['price']) ?? 0;
    final quantity = _readInt(json['quantity']) ?? 1;
    return CustomerCartItem(
      id: _readString(json['id']) ?? '',
      menuItemId:
          _readString(json['menu_item_id']) ??
          _readString(menuItem['id']) ??
          '',
      title:
          _readString(menuItem['name']) ??
          _readString(menuItem['title']) ??
          _readString(json['name']) ??
          'Item',
      description: _readString(menuItem['description']) ?? '',
      imageUrl: _readString(menuItem['image_url']) ?? '',
      category: category,
      quantity: quantity,
      notes: _readString(json['notes']) ?? '',
      unitPrice: unitPrice,
      lineTotal: _readDouble(json['line_total']) ?? (unitPrice * quantity),
      isAvailable:
          _readBool(menuItem['is_available']) ??
          _readBool(menuItem['available']) ??
          true,
    );
  }
}

class CustomerCartApiException implements Exception {
  const CustomerCartApiException(this.message);

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

List<Map<String, dynamic>> _extractList(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map(_stringMap).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _extractListFromPayload(
  Map<String, dynamic> payload,
) {
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
  throw CustomerCartApiException(
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

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
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

CartAppliedLoyaltyOffer? _parseLoyaltyOffer(dynamic value) {
  final data = _stringMap(value);
  if (data.isEmpty) {
    return null;
  }
  final menuItem = _stringMap(data['menu_item']);
  final expiresAtRaw = _readString(data['expires_at']);
  return CartAppliedLoyaltyOffer(
    id: _readString(data['id']) ?? '',
    title: _readString(data['title']) ?? 'Offer',
    description: _readString(data['description']) ?? '',
    requiredPoints: _readInt(data['required_points']) ?? 0,
    isActive: _readBool(data['is_active']) ?? true,
    rewardType: _readString(data['reward_type']),
    conditions: _readString(data['conditions']) ?? _readString(data['terms']),
    expiresAt: expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw),
    menuItemId:
        _readString(data['menu_item_id']) ?? _readString(menuItem['id']),
    menuItemName: _readString(menuItem['name']),
    menuItemImageUrl: _readString(menuItem['image_url']),
    menuItemPrice: _readDouble(menuItem['price']),
    menuItemAvailable: _readBool(menuItem['is_available']),
    freeItemQuantity: _readInt(data['free_item_quantity']) ?? 1,
    discountPercentage: _readDouble(data['discount_percentage']),
    discountAmount: _readDouble(data['discount_amount']),
    discountedPrice: _readDouble(data['discounted_price']),
  );
}

double _sum<T>(List<T> items, double Function(T item) value) {
  var total = 0.0;
  for (final item in items) {
    total += value(item);
  }
  return total;
}
