import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'restaurant_menu_api_service.dart';

class CustomerApiService {
  CustomerApiService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<CustomerProfile> fetchProfile({required String token}) async {
    final payload = await _request(
      'GET',
      '/api/v1/customer/profile',
      token: token,
    );
    return CustomerProfile.fromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<CustomerProfile> updateProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (email.trim().isNotEmpty) 'email': email,
      'phone': phone,
    };
    final payload = await _request(
      'PATCH',
      '/api/v1/customer/profile',
      token: token,
      body: body,
    );
    return CustomerProfile.fromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<List<CustomerRestaurant>> fetchRestaurants({
    required String token,
  }) async {
    final payload = await _request(
      'GET',
      '/api/v1/customer/restaurants',
      token: token,
    );
    return _extractList(
      _unwrapData(payload),
    ).map(CustomerRestaurant.fromJson).toList(growable: false);
  }

  Future<CustomerRestaurantMenu> fetchRestaurantMenu({
    required String token,
    required String restaurantId,
  }) async {
    final payload = await _request(
      'GET',
      '/api/v1/customer/restaurants/$restaurantId/menu',
      token: token,
    );
    final data = _asMap(_unwrapData(payload)) ?? payload;
    final restaurant = _asMap(data['restaurant']);
    final items = _extractMenuItems(data);
    return CustomerRestaurantMenu(
      restaurant: restaurant == null
          ? null
          : CustomerRestaurant.fromJson(restaurant),
      items: items,
    );
  }

  Future<CustomerCart> fetchCart({required String token}) async {
    final payload = await _request(
      'GET',
      '/api/v1/customer/cart',
      token: token,
    );
    return CustomerCart.fromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<CustomerCart> addCartItem({
    required String token,
    required String menuItemId,
    required int quantity,
    String? notes,
  }) async {
    final payload = await _request(
      'POST',
      '/api/v1/customer/cart/items',
      token: token,
      body: <String, dynamic>{
        'menu_item_id': menuItemId,
        'quantity': quantity,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return CustomerCart.fromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<CustomerCart> updateCartItem({
    required String token,
    required String cartItemId,
    required int quantity,
    String? notes,
  }) async {
    final payload = await _request(
      'PATCH',
      '/api/v1/customer/cart/items/$cartItemId',
      token: token,
      body: <String, dynamic>{
        'quantity': quantity,
        ...?(notes == null ? null : <String, dynamic>{'notes': notes}),
      },
    );
    return CustomerCart.fromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<CustomerCart> removeCartItem({
    required String token,
    required String cartItemId,
  }) async {
    final payload = await _request(
      'DELETE',
      '/api/v1/customer/cart/items/$cartItemId',
      token: token,
    );
    return CustomerCart.fromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<CustomerOrder> placeOrder({
    required String token,
    String? branchId,
  }) async {
    final payload = await _request(
      'POST',
      '/api/v1/customer/orders',
      token: token,
      body: <String, dynamic>{
        if (branchId != null && branchId.trim().isNotEmpty)
          'branch_id': branchId,
      },
    );
    return CustomerOrder.fromJson(_asMap(_unwrapData(payload)) ?? payload);
  }

  Future<List<CustomerOrder>> fetchOrderHistory({required String token}) async {
    final payload = await _request(
      'GET',
      '/api/v1/customer/orders/history',
      token: token,
    );
    return _extractList(
      _unwrapData(payload),
    ).map(CustomerOrder.fromJson).toList(growable: false);
  }

  Future<CustomerOrder> fetchOrder({
    required String token,
    required String orderId,
  }) async {
    final payload = await _request(
      'GET',
      '/api/v1/customer/orders/$orderId',
      token: token,
    );
    return CustomerOrder.fromJson(_asMap(_unwrapData(payload)) ?? payload);
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
      throw const CustomerApiException(
        'Missing authentication token. Please log in again.',
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $cleanedToken',
      if (body != null) 'Content-Type': 'application/json',
    };

    http.Response response;
    try {
      final uri = AppConfig.apiUri(endpoint);
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw CustomerApiException('Unsupported API method $method.');
      }
    } catch (_) {
      throw const CustomerApiException(
        'Unable to reach the server. Check your connection and try again.',
      );
    }

    final payload = _decodeMap(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const CustomerApiException(
        'Your session expired. Please log in again.',
      );
    }
    throw CustomerApiException(
      _extractError(payload) ?? 'Customer request failed.',
    );
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String avatarUrl;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: _firstString(json, const ['id', 'user_id']) ?? '',
      name:
          _firstString(json, const ['name', 'full_name', 'display_name']) ??
          'FoodExplorer',
      email: _firstString(json, const ['email', 'mail']) ?? '',
      phone:
          _firstString(json, const ['phone', 'phone_number', 'mobile']) ?? '',
      role:
          _firstString(json, const ['role', 'user_role', 'account_type']) ??
          'customer',
      avatarUrl:
          _firstString(json, const [
            'avatar_url',
            'avatar',
            'photo_url',
            'image_url',
          ]) ??
          '',
    );
  }
}

class CustomerRestaurant {
  const CustomerRestaurant({
    required this.id,
    required this.name,
    required this.handle,
    required this.description,
    required this.category,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.rating,
    required this.deliveryLabel,
    required this.priceTier,
    required this.ordersCount,
    required this.menuItemsCount,
    required this.status,
  });

  final String id;
  final String name;
  final String handle;
  final String description;
  final String category;
  final String address;
  final String phone;
  final String imageUrl;
  final double rating;
  final String deliveryLabel;
  final int priceTier;
  final int ordersCount;
  final int menuItemsCount;
  final String status;

  factory CustomerRestaurant.fromJson(Map<String, dynamic> json) {
    final name =
        _firstString(json, const [
          'restaurant_name',
          'name',
          'business_name',
          'store_name',
        ]) ??
        'Restaurant';
    final handle =
        _firstString(json, const ['handle', 'slug', 'username']) ??
        _slugify(name);
    final branch = _firstMapFromList(json['branches']);
    final owner = _asMap(json['owner']);
    return CustomerRestaurant(
      id: _firstString(json, const ['id', 'restaurant_id']) ?? handle,
      name: name,
      handle: handle,
      description:
          _firstString(json, const [
            'description',
            'caption',
            'bio',
            'about',
          ]) ??
          'Fresh dishes available now.',
      category:
          _firstString(json, const [
            'cuisine',
            'cuisine_type',
            'category',
            'category_name',
          ]) ??
          'Restaurant',
      address:
          _firstString(json, const ['address', 'location', 'street']) ??
          _firstString(branch ?? const <String, dynamic>{}, const [
            'address',
            'street',
          ]) ??
          '',
      phone:
          _firstString(json, const ['phone', 'phone_number']) ??
          _firstString(branch ?? const <String, dynamic>{}, const ['phone']) ??
          _firstString(owner ?? const <String, dynamic>{}, const ['phone']) ??
          '',
      imageUrl:
          _firstString(json, const [
            'profile_photo_url',
            'cover_image_url',
            'image_url',
            'image',
            'photo_url',
          ]) ??
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=900&q=80',
      rating:
          _firstDouble(json, const [
            'average_rating',
            'reviews_avg_rating',
            'rating',
            'avg_rating',
          ]) ??
          0,
      deliveryLabel:
          _firstString(json, const ['delivery_label', 'eta_label']) ?? 'Open',
      priceTier: (_firstInt(json, const ['price_tier', 'price_level']) ?? 2)
          .clamp(1, 4),
      ordersCount: _firstInt(json, const ['orders_count', 'total_orders']) ?? 0,
      menuItemsCount:
          _firstInt(json, const ['menu_items_count', 'items_count']) ?? 0,
      status: _firstString(json, const ['status']) ?? 'active',
    );
  }
}

class CustomerRestaurantMenu {
  const CustomerRestaurantMenu({required this.items, this.restaurant});

  final CustomerRestaurant? restaurant;
  final List<RestaurantMenuItem> items;
}

class CustomerCart {
  const CustomerCart({
    required this.id,
    required this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.fees,
    required this.total,
  });

  final String id;
  final String restaurantName;
  final List<CustomerCartItem> items;
  final double subtotal;
  final double fees;
  final double total;

  factory CustomerCart.fromJson(Map<String, dynamic> json) {
    final restaurant = _asMap(json['restaurant']);
    final items = _extractList(
      json['items'],
    ).map(CustomerCartItem.fromJson).toList(growable: false);
    return CustomerCart(
      id: _firstString(json, const ['id', 'cart_id']) ?? '',
      restaurantName:
          _firstString(restaurant ?? const <String, dynamic>{}, const [
            'name',
            'restaurant_name',
          ]) ??
          '',
      items: items,
      subtotal:
          _firstDouble(json, const ['subtotal']) ??
          items.fold<double>(0, (total, item) => total + item.lineTotal),
      fees: _firstDouble(json, const ['fees', 'service_fee']) ?? 0,
      total: _firstDouble(json, const ['total']) ?? 0,
    );
  }
}

class CustomerCartItem {
  const CustomerCartItem({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    required this.notes,
    required this.unitPrice,
    required this.lineTotal,
    required this.menuItem,
  });

  final String id;
  final String menuItemId;
  final int quantity;
  final String notes;
  final double unitPrice;
  final double lineTotal;
  final RestaurantMenuItem menuItem;

  factory CustomerCartItem.fromJson(Map<String, dynamic> json) {
    final menuItemJson =
        _asMap(json['menu_item']) ??
        <String, dynamic>{
          'id': _firstString(json, const ['menu_item_id']),
          'name': _firstString(json, const ['name', 'title']),
          'price': _firstDouble(json, const ['unit_price', 'price']),
        };
    return CustomerCartItem(
      id: _firstString(json, const ['id', 'cart_item_id']) ?? '',
      menuItemId:
          _firstString(json, const ['menu_item_id', 'item_id']) ??
          _firstString(menuItemJson, const ['id']) ??
          '',
      quantity: _firstInt(json, const ['quantity', 'qty']) ?? 1,
      notes: _firstString(json, const ['notes']) ?? '',
      unitPrice: _firstDouble(json, const ['unit_price', 'price']) ?? 0,
      lineTotal: _firstDouble(json, const ['line_total', 'total']) ?? 0,
      menuItem: RestaurantMenuItem.fromJson(menuItemJson),
    );
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.restaurantName,
    required this.status,
    required this.total,
    required this.subtotal,
    required this.fees,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String restaurantName;
  final String status;
  final double total;
  final double subtotal;
  final double fees;
  final DateTime? createdAt;
  final List<CustomerOrderItem> items;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final restaurant = _asMap(json['restaurant']);
    return CustomerOrder(
      id: _firstString(json, const ['id', 'order_id']) ?? '',
      restaurantName:
          _firstString(restaurant ?? const <String, dynamic>{}, const [
            'name',
            'restaurant_name',
          ]) ??
          'Restaurant',
      status: _firstString(json, const ['status']) ?? 'pending',
      total: _firstDouble(json, const ['total']) ?? 0,
      subtotal: _firstDouble(json, const ['subtotal']) ?? 0,
      fees: _firstDouble(json, const ['fees']) ?? 0,
      createdAt: _firstDateTime(json, const ['created_at', 'placed_at']),
      items: _extractList(
        json['items'],
      ).map(CustomerOrderItem.fromJson).toList(growable: false),
    );
  }

  String get itemSummary {
    if (items.isEmpty) {
      return 'Order #$id';
    }
    final names = items
        .take(2)
        .map((item) => '${item.quantity}x ${item.title}')
        .join(', ');
    final extra = items.length > 2 ? ' +${items.length - 2} more' : '';
    return '$names$extra';
  }
}

class CustomerOrderItem {
  const CustomerOrderItem({
    required this.title,
    required this.subtitle,
    required this.quantity,
    required this.unitPrice,
    required this.imageUrl,
    required this.menuItemId,
  });

  final String title;
  final String subtitle;
  final int quantity;
  final double unitPrice;
  final String imageUrl;
  final String menuItemId;

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
    final menuItem = _asMap(json['menu_item']) ?? const <String, dynamic>{};
    return CustomerOrderItem(
      title:
          _firstString(menuItem, const ['title', 'name']) ??
          _firstString(json, const ['title', 'name']) ??
          'Menu item',
      subtitle:
          _firstString(menuItem, const ['description', 'category_name']) ??
          _firstString(json, const ['notes']) ??
          '',
      quantity: _firstInt(json, const ['quantity', 'qty']) ?? 1,
      unitPrice:
          _firstDouble(json, const ['unit_price', 'price']) ??
          _firstDouble(menuItem, const ['price']) ??
          0,
      imageUrl:
          _firstString(menuItem, const ['image_url', 'image']) ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
      menuItemId:
          _firstString(json, const ['menu_item_id']) ??
          _firstString(menuItem, const ['id']) ??
          '',
    );
  }
}

class CustomerApiException implements Exception {
  const CustomerApiException(this.message);

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
    for (final key in const [
      'data',
      'items',
      'menu_items',
      'orders',
      'restaurants',
    ]) {
      final list = _extractList(map[key]);
      if (list.isNotEmpty) {
        return list;
      }
    }
  }
  return const <Map<String, dynamic>>[];
}

Map<String, dynamic>? _firstMapFromList(dynamic value) {
  final list = _extractList(value);
  return list.isEmpty ? null : list.first;
}

List<RestaurantMenuItem> _extractMenuItems(Map<String, dynamic> data) {
  final direct = _extractList(data['menu_items']);
  if (direct.isNotEmpty) {
    return direct.map(RestaurantMenuItem.fromJson).toList(growable: false);
  }
  final fromItems = _extractList(data['items']);
  if (fromItems.isNotEmpty) {
    return fromItems.map(RestaurantMenuItem.fromJson).toList(growable: false);
  }
  final result = <RestaurantMenuItem>[];
  for (final category in _extractList(data['categories'])) {
    final categoryName = _firstString(category, const [
      'name',
      'category_name',
      'title',
    ]);
    for (final item in _extractList(category['items'])) {
      if (categoryName != null) {
        item.putIfAbsent('category_name', () => categoryName);
      }
      result.add(RestaurantMenuItem.fromJson(item));
    }
  }
  return result;
}

String? _extractError(Map<String, dynamic> payload) {
  final message = payload['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }
  final errors = payload['errors'];
  final errorMap = _asMap(errors);
  if (errorMap != null) {
    for (final value in errorMap.values) {
      if (value is List && value.isNotEmpty && value.first is String) {
        return (value.first as String).trim();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  }
  return null;
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

String _slugify(String value) {
  final slug = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'restaurant' : slug;
}
