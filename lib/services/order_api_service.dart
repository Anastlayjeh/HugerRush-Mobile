import '../models/auth_session.dart';
import 'api_client.dart';
import 'auth_api_service.dart';
import 'authenticated_api_client.dart';

class CustomerOrderApiService {
  CustomerOrderApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<AppOrder> placeOrder({
    required AuthSession session,
    required CustomerOrderDraft draft,
  }) async {
    if (draft.canSyncCart) {
      await _syncCart(session: session, draft: draft);
    }

    final response = await _postOrder(
      session: session,
      body: draft.toOrderJson(),
    );
    if (response != null) {
      return response;
    }

    throw const OrderApiException('Could not place your order right now.');
  }

  Future<List<AppOrder>> fetchHistory({required AuthSession session}) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/orders/history',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load order history.',
    );
    return _extractOrderList(
      payload,
    ).map(AppOrder.fromJson).toList(growable: false);
  }

  Future<AppOrder> fetchOrder({
    required AuthSession session,
    required String orderId,
  }) async {
    final cleanedId = orderId.trim();
    if (cleanedId.isEmpty) {
      throw const OrderApiException('Order ID is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/customer/orders/$cleanedId',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load order.',
    );
    return AppOrder.fromJson(_extractOrderObject(payload));
  }

  Future<AppOrder?> _postOrder({
    required AuthSession session,
    required Map<String, dynamic> body,
    bool allowValidationFallback = true,
  }) async {
    final result = await _apiClient.request(
      session: session,
      method: 'POST',
      endpoint: '/v1/customer/orders',
      body: body,
    );
    final payload = ApiClient.decodeMap(result.response.body);
    if (result.response.statusCode >= 200 && result.response.statusCode < 300) {
      return AppOrder.fromJson(_extractOrderObject(payload));
    }

    if (allowValidationFallback &&
        (result.response.statusCode == 400 ||
            result.response.statusCode == 422)) {
      return null;
    }

    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not place your order right now.',
    );
    return null;
  }

  Future<void> _syncCart({
    required AuthSession session,
    required CustomerOrderDraft draft,
  }) async {
    for (final item in draft.items) {
      final result = await _apiClient.request(
        session: session,
        method: 'POST',
        endpoint: '/v1/customer/cart/items',
        body: item.toCartJson(restaurantId: draft.restaurantId),
      );
      final payload = ApiClient.decodeMap(result.response.body);
      _throwForFailure(
        result.response.statusCode,
        payload,
        fallback: 'Could not sync your cart.',
      );
    }
  }
}

class RestaurantOrderApiService {
  RestaurantOrderApiService({required AuthenticatedApiClient apiClient})
    : _apiClient = apiClient;

  final AuthenticatedApiClient _apiClient;

  Future<List<AppOrder>> fetchOrders({required AuthSession session}) async {
    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/orders',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load restaurant orders.',
    );
    return _extractOrderList(
      payload,
    ).map(AppOrder.fromJson).toList(growable: false);
  }

  Future<AppOrder> fetchOrder({
    required AuthSession session,
    required String orderId,
  }) async {
    final cleanedId = orderId.trim();
    if (cleanedId.isEmpty) {
      throw const OrderApiException('Order ID is required.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'GET',
      endpoint: '/v1/restaurant/orders/$cleanedId',
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Failed to load order details.',
    );
    return AppOrder.fromJson(_extractOrderObject(payload));
  }

  Future<AppOrder> updateStatus({
    required AuthSession session,
    required String orderId,
    required String status,
  }) async {
    final cleanedId = orderId.trim();
    final cleanedStatus = status.trim();
    if (cleanedId.isEmpty || cleanedStatus.isEmpty) {
      throw const OrderApiException('Order status update is incomplete.');
    }

    final result = await _apiClient.request(
      session: session,
      method: 'PATCH',
      endpoint: '/v1/restaurant/orders/$cleanedId/status',
      body: <String, dynamic>{'status': cleanedStatus},
    );
    final payload = ApiClient.decodeMap(result.response.body);
    _throwForFailure(
      result.response.statusCode,
      payload,
      fallback: 'Could not update order status.',
    );
    return AppOrder.fromJson(_extractOrderObject(payload));
  }
}

class CustomerOrderDraft {
  const CustomerOrderDraft({
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.address,
    required this.paymentMethod,
    required this.deliveryMode,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.total,
    this.scheduledLabel = '',
    this.changeRequest = '',
    this.useLoyalty = false,
    this.saveChangeInWallet = false,
    this.branchId,
  });

  final String restaurantId;
  final String restaurantName;
  final List<CustomerOrderDraftItem> items;
  final OrderAddress address;
  final String paymentMethod;
  final String deliveryMode;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double total;
  final String scheduledLabel;
  final String changeRequest;
  final bool useLoyalty;
  final bool saveChangeInWallet;
  final String? branchId;

  bool get canSyncCart =>
      restaurantId.trim().isNotEmpty &&
      items.isNotEmpty &&
      items.every((item) => item.menuItemId.trim().isNotEmpty);

  Map<String, dynamic> toOrderJson() {
    return <String, dynamic>{
      if (branchId != null && branchId!.trim().isNotEmpty)
        'branch_id': branchId!.trim(),
    };
  }
}

class CustomerOrderDraftItem {
  const CustomerOrderDraftItem({
    required this.menuItemId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    this.notes = '',
  });

  final String menuItemId;
  final String title;
  final int quantity;
  final double unitPrice;
  final String notes;

  Map<String, dynamic> toOrderJson() {
    return <String, dynamic>{
      'menu_item_id': menuItemId,
      'item_id': menuItemId,
      'name': title,
      'quantity': quantity,
      'unit_price': unitPrice,
      'price': unitPrice,
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
  }

  Map<String, dynamic> toCartJson({required String restaurantId}) {
    return <String, dynamic>{
      'menu_item_id': menuItemId,
      'quantity': quantity,
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
  }
}

class OrderAddress {
  const OrderAddress({
    required this.city,
    required this.street,
    required this.building,
    this.floor = '',
    this.apartment = '',
    this.landmark = '',
  });

  final String city;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final String landmark;

  String get label {
    return <String>[
          city,
          street,
          if (building.trim().isNotEmpty) 'Building $building',
          if (floor.trim().isNotEmpty) 'Floor $floor',
          if (apartment.trim().isNotEmpty) 'Apt $apartment',
          if (landmark.trim().isNotEmpty) landmark,
        ]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'city': city.trim(),
      'street': street.trim(),
      'building': building.trim(),
      'floor': floor.trim(),
      'apartment': apartment.trim(),
      'landmark': landmark.trim(),
    };
  }
}

class AppOrder {
  const AppOrder({
    required this.id,
    required this.displayId,
    required this.customerName,
    required this.restaurantName,
    required this.status,
    required this.itemSummary,
    required this.total,
    required this.channelLabel,
    required this.etaLabel,
    required this.addressLabel,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String displayId;
  final String customerName;
  final String restaurantName;
  final String status;
  final String itemSummary;
  final double? total;
  final String channelLabel;
  final String etaLabel;
  final String addressLabel;
  final DateTime? createdAt;
  final List<AppOrderItem> items;

  String get statusLabel => orderStatusLabel(status);

  String get totalLabel =>
      total == null ? '-' : '\$${total!.toStringAsFixed(2)}';

  bool get isCompleted {
    final normalized = _normalizeStatus(status);
    return normalized == 'delivered' ||
        normalized == 'completed' ||
        normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'rejected';
  }

  bool get isActive => !isCompleted;

  factory AppOrder.fromJson(Map<String, dynamic> json) {
    final customer = _stringMap(json['customer']);
    final user = _stringMap(json['user']);
    final restaurant = _stringMap(json['restaurant']);
    final items = _extractOrderItems(
      json,
    ).map(AppOrderItem.fromJson).toList(growable: false);
    final id =
        _firstString(json, const ['id', 'uuid', 'order_id']) ??
        _firstString(json, const ['number', 'order_number', 'reference']) ??
        '';
    final displayId =
        _firstString(json, const [
          'display_id',
          'order_number',
          'number',
          'reference',
          'code',
        ]) ??
        (id.isEmpty ? 'Order' : '#$id');
    final customerName =
        _firstString(json, const ['customer_name', 'name']) ??
        _firstString(customer, const ['name', 'full_name']) ??
        _firstString(user, const ['name', 'full_name']) ??
        'Customer';
    final restaurantName =
        _firstString(json, const ['restaurant_name']) ??
        _firstString(restaurant, const ['name']) ??
        'Restaurant';
    final status =
        _firstString(json, const ['status', 'order_status', 'state']) ??
        'pending';
    final itemSummary =
        _firstString(json, const [
          'item_summary',
          'summary',
          'items_summary',
        ]) ??
        _buildItemSummary(items);
    final addressLabel =
        _firstString(json, const ['address', 'delivery_address_label']) ??
        _addressLabelFromValue(json['delivery_address']) ??
        '';
    return AppOrder(
      id: id,
      displayId: displayId,
      customerName: customerName,
      restaurantName: restaurantName,
      status: status,
      itemSummary: itemSummary,
      total: _firstDouble(json, const [
        'total',
        'total_amount',
        'grand_total',
        'amount',
        'payable_total',
      ]),
      channelLabel:
          _firstString(json, const [
            'channel',
            'delivery_method',
            'delivery_type',
            'fulfillment_type',
            'order_type',
          ]) ??
          'Delivery',
      etaLabel:
          _firstString(json, const [
            'eta_label',
            'eta',
            'estimated_time',
            'estimated_delivery_time',
          ]) ??
          '',
      addressLabel: addressLabel,
      createdAt: _firstDate(json, const [
        'created_at',
        'placed_at',
        'ordered_at',
      ]),
      items: items,
    );
  }
}

class AppOrderItem {
  const AppOrderItem({
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String title;
  final int quantity;
  final double? unitPrice;
  final double? total;

  String get quantityLabel => '${quantity}x';

  String get totalLabel {
    final value = total ?? (unitPrice == null ? null : unitPrice! * quantity);
    return value == null ? '-' : '\$${value.toStringAsFixed(2)}';
  }

  factory AppOrderItem.fromJson(Map<String, dynamic> json) {
    final menuItem = _stringMap(json['menu_item']);
    final title =
        _firstString(json, const ['name', 'title', 'item_name']) ??
        _firstString(menuItem, const ['name', 'title']) ??
        'Item';
    return AppOrderItem(
      title: title,
      quantity: _firstInt(json, const ['quantity', 'qty']) ?? 1,
      unitPrice: _firstDouble(json, const ['unit_price', 'price']),
      total: _firstDouble(json, const ['total', 'line_total', 'subtotal']),
    );
  }
}

class OrderApiException implements Exception {
  const OrderApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

String orderStatusLabel(String status) {
  switch (_normalizeStatus(status)) {
    case 'pending':
      return 'Pending';
    case 'accepted':
      return 'Accepted';
    case 'preparing':
      return 'Preparing';
    case 'ready':
    case 'ready_for_pickup':
      return 'Ready';
    case 'picked_up':
      return 'Picked up';
    case 'on_the_way':
    case 'on the way':
      return 'On the way';
    case 'delivered':
    case 'completed':
      return 'Delivered';
    case 'rejected':
      return 'Rejected';
    case 'cancelled':
    case 'canceled':
      return 'Canceled';
  }
  final cleaned = status.trim();
  if (cleaned.isEmpty) {
    return 'Pending';
  }
  return cleaned
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
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
    throw const AuthApiException('Your session expired. Please log in again.');
  }
  if (statusCode == 403) {
    throw const AuthApiException(
      'You do not have permission to perform this action.',
    );
  }
  throw OrderApiException(
    '${ApiClient.errorMessageForStatus(statusCode, payload, fallback: fallback)} (HTTP $statusCode)',
  );
}

Map<String, dynamic> _extractOrderObject(Map<String, dynamic> payload) {
  final data = payload['data'];
  if (data is Map) {
    final mapped = _stringMap(data);
    final nestedOrder = mapped['order'];
    if (nestedOrder is Map) {
      return _stringMap(nestedOrder);
    }
    return mapped;
  }
  final order = payload['order'];
  if (order is Map) {
    return _stringMap(order);
  }
  return payload;
}

List<Map<String, dynamic>> _extractOrderList(Map<String, dynamic> payload) {
  final candidates = <dynamic>[
    payload['data'],
    payload['orders'],
    payload['items'],
    payload['data'] is Map ? payload['data']['data'] : null,
    payload['data'] is Map ? payload['data']['orders'] : null,
    payload['data'] is Map ? payload['data']['items'] : null,
  ];
  for (final candidate in candidates) {
    final parsed = _listOfMaps(candidate);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _extractOrderItems(Map<String, dynamic> payload) {
  final candidates = <dynamic>[
    payload['items'],
    payload['order_items'],
    payload['lines'],
    payload['data'] is Map ? payload['data']['items'] : null,
    payload['data'] is Map ? payload['data']['order_items'] : null,
  ];
  for (final candidate in candidates) {
    final parsed = _listOfMaps(candidate);
    if (parsed.isNotEmpty) {
      return parsed;
    }
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

String _buildItemSummary(List<AppOrderItem> items) {
  if (items.isEmpty) {
    return 'Order items';
  }
  return items.map((item) => '${item.quantity}x ${item.title}').join(', ');
}

String? _addressLabelFromValue(dynamic value) {
  if (value is String) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }
  if (value is Map) {
    final mapped = _stringMap(value);
    final parts = <String>[
      _readString(mapped['city']) ?? '',
      _readString(mapped['street']) ?? '',
      _readString(mapped['building']) ?? '',
      _readString(mapped['floor']) ?? '',
      _readString(mapped['apartment']) ?? '',
      _readString(mapped['landmark']) ?? '',
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
  }
  return null;
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _readString(map[key]);
    if (value != null) {
      return value;
    }
  }
  return null;
}

double? _firstDouble(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _readDouble(map[key]);
    if (value != null) {
      return value;
    }
  }
  return null;
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

DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _readDateTime(map[key]);
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

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
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

DateTime? _readDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

String _normalizeStatus(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_');
}
