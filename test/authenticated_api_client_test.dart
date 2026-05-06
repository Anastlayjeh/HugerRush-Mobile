import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/models/auth_session.dart';
import 'package:flutter_application_1/services/auth_api_service.dart';
import 'package:flutter_application_1/services/auth_session_service.dart';
import 'package:flutter_application_1/services/authenticated_api_client.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  FakeSecureStorage();

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

void main() {
  group('AuthenticatedApiClient', () {
    test('clears session on 401 without calling refresh', () async {
      var protectedCallCount = 0;
      final protectedClient = MockClient((request) async {
        protectedCallCount += 1;
        expect(request.headers['Authorization'], 'Bearer old-access');
        return http.Response('Unauthorized', 401);
      });

      final sessionService = AuthSessionService(storage: FakeSecureStorage());
      final initialSession = AuthSession(
        token: 'old-access',
        refreshToken: 'old-refresh',
        role: 'restaurant_owner',
        restaurantName: 'Bella',
      );
      await sessionService.saveSession(initialSession);

      var expiredCallbackCalled = false;

      final client = AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: sessionService,
        client: protectedClient,
        onSessionExpired: () async {
          expiredCallbackCalled = true;
        },
      );

      await expectLater(
        client.request(
          session: initialSession,
          method: 'GET',
          endpoint: '/v1/protected/orders',
        ),
        throwsA(isA<AuthSessionExpiredException>()),
      );

      expect(protectedCallCount, 1);
      expect(expiredCallbackCalled, isTrue);
      final persisted = await sessionService.readSession();
      expect(persisted, isNull);
    });

    test('returns successful protected response without expiring session', () async {
      final protectedClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access-token');
        return http.Response('{"ok":true}', 200);
      });

      final sessionService = AuthSessionService(storage: FakeSecureStorage());
      final session = AuthSession(
        token: 'access-token',
        role: 'restaurant_owner',
        restaurantName: 'Bella',
      );
      await sessionService.saveSession(session);

      final client = AuthenticatedApiClient(
        authApiService: AuthApiService(),
        authSessionService: sessionService,
        client: protectedClient,
      );

      final result = await client.request(
        session: session,
        method: 'GET',
        endpoint: '/v1/protected/orders',
      );

      expect(result.response.statusCode, 200);
      expect(result.usedRefreshFlow, isFalse);
      final persisted = await sessionService.readSession();
      expect(persisted?.token, 'access-token');
    });
  });
}
