import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/models/auth_session.dart';
import 'package:flutter_application_1/services/auth_api_service.dart';
import 'package:flutter_application_1/services/auth_session_service.dart';
import 'package:flutter_application_1/services/authenticated_api_client.dart';
import 'package:flutter_application_1/services/cart_api_service.dart';
import 'package:flutter_application_1/services/conversation_api_service.dart';
import 'package:flutter_application_1/services/customer_restaurant_api_service.dart';
import 'package:flutter_application_1/services/order_api_service.dart';
import 'package:flutter_application_1/services/restaurant_owner_api_service.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
      return;
    }
    _store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

AuthenticatedApiClient _authenticatedClient(http.Client client) {
  return AuthenticatedApiClient(
    authApiService: AuthApiService(),
    authSessionService: AuthSessionService(storage: FakeSecureStorage()),
    client: client,
  );
}

const _session = AuthSession(
  token: 'token',
  role: 'customer',
  restaurantName: 'HungerRush',
);

void main() {
  test('cart add item uses the live cart payload shape', () async {
    late http.Request captured;
    final service = CustomerCartApiService(
      apiClient: _authenticatedClient(
        MockClient((request) async {
          captured = request;
          return http.Response(
            '{"data":{"id":9,"menu_item_id":42,"quantity":2,"notes":"extra sauce","unit_price":7.5,"line_total":15,"menu_item":{"name":"Shawarma","is_available":true}}}',
            200,
          );
        }),
      ),
    );

    final item = await service.addItem(
      session: _session,
      menuItemId: '42',
      quantity: 2,
      notes: 'extra sauce',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/customer/cart/items');
    expect(captured.body, contains('"menu_item_id":"42"'));
    expect(captured.body, contains('"quantity":2'));
    expect(captured.body, contains('"notes":"extra sauce"'));
    expect(item.id, '9');
    expect(item.title, 'Shawarma');
  });

  test('placeOrder syncs cart before posting the order', () async {
    final paths = <String>[];
    final bodies = <String>[];
    final service = CustomerOrderApiService(
      apiClient: _authenticatedClient(
        MockClient((request) async {
          paths.add(request.url.path);
          bodies.add(request.body);
          if (request.url.path.endsWith('/cart/items')) {
            return http.Response('{"data":{"id":1}}', 200);
          }
          return http.Response(
            '{"data":{"id":77,"order_number":"HR-77","status":"pending","restaurant":{"name":"Cedar Bowl"},"items":[],"total":12.5}}',
            201,
          );
        }),
      ),
    );

    final order = await service.placeOrder(
      session: _session,
      draft: const CustomerOrderDraft(
        restaurantId: '5',
        restaurantName: 'Cedar Bowl',
        items: [
          CustomerOrderDraftItem(
            menuItemId: '42',
            title: 'Falafel',
            quantity: 1,
            unitPrice: 12.5,
          ),
        ],
        address: OrderAddress(city: 'Beirut', street: 'Main', building: '1'),
        phone: '+96170123456',
        paymentMethod: 'cash_on_delivery',
        deliveryMode: 'now',
        subtotal: 12.5,
        deliveryFee: 0,
        serviceFee: 0,
        total: 12.5,
      ),
    );

    expect(paths, ['/api/v1/customer/cart/items', '/api/v1/customer/orders']);
    expect(bodies.first, contains('"menu_item_id":"42"'));
    expect(bodies.last, contains('"restaurant_id":"5"'));
    expect(order.id, '77');
  });

  test('conversation send message posts body to the live route', () async {
    late http.Request captured;
    final service = ConversationApiService(
      apiClient: _authenticatedClient(
        MockClient((request) async {
          captured = request;
          return http.Response(
            '{"data":{"id":3,"conversation_id":5,"sender":{"name":"Maya","role":"customer"},"body":"Hello","created_at":"2026-05-06T10:00:00Z"}}',
            200,
          );
        }),
      ),
    );

    final message = await service.sendMessage(
      session: _session,
      conversationId: '5',
      body: 'Hello',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/conversations/5/messages');
    expect(captured.body, '{"body":"Hello"}');
    expect(message.body, 'Hello');
  });

  test('customer review submit posts to restaurant review route', () async {
    late http.Request captured;
    final service = CustomerRestaurantApiService(
      apiClient: _authenticatedClient(
        MockClient((request) async {
          captured = request;
          return http.Response(
            '{"data":{"id":15,"restaurant_id":3,"customer_id":8,"order_id":91,"rating":5,"comment":"Amazing food","customer":{"id":8,"name":"Ahmad"},"created_at":"2026-05-07T09:00:00Z","updated_at":"2026-05-07T09:00:00Z"}}',
            201,
          );
        }),
      ),
    );

    final created = await service.submitRestaurantReview(
      session: _session,
      restaurantId: '3',
      rating: 5,
      comment: 'Amazing food',
      orderId: '91',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/customer/restaurants/3/reviews');
    expect(captured.body, contains('"rating":5'));
    expect(captured.body, contains('"comment":"Amazing food"'));
    expect(captured.body, contains('"order_id":"91"'));
    expect(created.id, '15');
    expect(created.customerName, 'Ahmad');
    expect(created.rating, 5);
  });

  test('restaurant status and moderation parsing use backend values', () {
    expect(orderStatusLabel('ready_for_pickup'), 'Ready');
    expect(orderStatusLabel('picked_up'), 'Picked up');

    final rejected = RestaurantVideoItem.fromJson(const <String, dynamic>{
      'id': 1,
      'title': 'Clip',
      'status': 'published',
      'moderation_status': 'rejected',
      'moderation_reason': 'not_food',
    });
    expect(rejected.moderationLabel, 'Rejected / Not food-related');
    expect(rejected.canAppearPublished, isFalse);
  });
}
