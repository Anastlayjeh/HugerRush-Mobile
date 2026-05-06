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
    test('refreshes access token on 401 and retries request once', () async {
      var protectedCallCount = 0;
      final protectedClient = MockClient((request) async {
        protectedCallCount += 1;
        if (protectedCallCount == 1) {
          expect(request.headers['Authorization'], 'Bearer old-access');
          return http.Response('Unauthorized', 401);
        }

        expect(request.headers['Authorization'], 'Bearer new-access');
        return http.Response('{"ok":true}', 200);
      });

      final authApiService = AuthApiService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/refresh');
          expect(request.body, contains('"refresh_token":"old-refresh"'));
          return http.Response(
            '{"message":"refreshed","data":{"access_token":"new-access","refresh_token":"new-refresh"}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final sessionService = AuthSessionService(storage: FakeSecureStorage());
      final initialSession = AuthSession(
        token: 'old-access',
        refreshToken: 'old-refresh',
        role: 'restaurant_owner',
        restaurantName: 'Bella',
      );
      await sessionService.saveSession(initialSession);

      AuthSession? callbackSession;
      var expiredCallbackCalled = false;

      final client = AuthenticatedApiClient(
        authApiService: authApiService,
        authSessionService: sessionService,
        client: protectedClient,
        onSessionUpdated: (session) async {
          callbackSession = session;
        },
        onSessionExpired: () async {
          expiredCallbackCalled = true;
        },
      );

      final result = await client.request(
        session: initialSession,
        method: 'GET',
        endpoint: '/v1/protected/orders',
      );

      expect(result.response.statusCode, 200);
      expect(result.usedRefreshFlow, isTrue);
      expect(result.session.token, 'new-access');
      expect(result.session.refreshToken, 'new-refresh');
      expect(protectedCallCount, 2);
      expect(expiredCallbackCalled, isFalse);
      expect(callbackSession?.token, 'new-access');

      final persisted = await sessionService.readSession();
      expect(persisted?.token, 'new-access');
      expect(persisted?.refreshToken, 'new-refresh');
    });

    test('clears session and throws when refresh fails', () async {
      final protectedClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final authApiService = AuthApiService(
        client: MockClient((request) async {
          return http.Response('{"message":"invalid refresh"}', 401);
        }),
      );

      final sessionService = AuthSessionService(storage: FakeSecureStorage());
      final session = AuthSession(
        token: 'expired-access',
        refreshToken: 'expired-refresh',
        role: 'restaurant_owner',
        restaurantName: 'Bella',
      );
      await sessionService.saveSession(session);

      var expiredCallbackCalled = false;
      final client = AuthenticatedApiClient(
        authApiService: authApiService,
        authSessionService: sessionService,
        client: protectedClient,
        onSessionExpired: () async {
          expiredCallbackCalled = true;
        },
      );

      await expectLater(
        client.request(
          session: session,
          method: 'GET',
          endpoint: '/v1/protected/orders',
        ),
        throwsA(
          isA<AuthSessionExpiredException>().having(
            (e) => e.message,
            'message',
            contains('Session expired'),
          ),
        ),
      );

      expect(expiredCallbackCalled, isTrue);
      final persisted = await sessionService.readSession();
      expect(persisted, isNull);
    });
  });
}
