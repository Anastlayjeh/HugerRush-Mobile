import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/services/auth_api_service.dart';

void main() {
  group('AuthApiService', () {
    test('login parses token and user from successful response', () async {
      final service = AuthApiService(
        client: MockClient((request) async {
          return http.Response(
            '{"message":"Logged in","data":{"token":"abc123","refresh_token":"refresh123","user":{"role":"restaurant_owner","name":"Bella Italia"}}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await service.login(
        email: 'owner@example.com',
        password: 'secure-pass',
      );

      expect(result.token, 'abc123');
      expect(result.refreshToken, 'refresh123');
      expect(result.user?['name'], 'Bella Italia');
      expect(result.user?['role'], 'restaurant_owner');
    });

    test('login throws readable error when response JSON is invalid', () async {
      final service = AuthApiService(
        client: MockClient((request) async {
          return http.Response('<<<invalid-json>>>', 200);
        }),
      );

      expect(
        () =>
            service.login(email: 'owner@example.com', password: 'secure-pass'),
        throwsA(
          isA<AuthApiException>().having(
            (e) => e.message,
            'message',
            contains('unreadable response format'),
          ),
        ),
      );
    });

    test(
      'login propagates backend message and status code on failure',
      () async {
        final service = AuthApiService(
          client: MockClient((request) async {
            return http.Response('{"message":"Invalid credentials"}', 401);
          }),
        );

        expect(
          () => service.login(email: 'owner@example.com', password: 'wrong'),
          throwsA(
            isA<AuthApiException>().having(
              (e) => e.message,
              'message',
              allOf(contains('Invalid credentials'), contains('HTTP 401')),
            ),
          ),
        );
      },
    );

    test('register throws if response does not include an auth token', () async {
      final service = AuthApiService(
        client: MockClient((request) async {
          return http.Response(
            '{"message":"Registration successful.","data":{"user":{"id":1}}}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      expect(
        () => service.register(
          payload: {
            'name': 'Owner',
            'email': 'owner@example.com',
            'password': 'Password123!',
            'password_confirmation': 'Password123!',
            'role': 'restaurant_owner',
          },
        ),
        throwsA(
          isA<AuthApiException>().having(
            (e) => e.message,
            'message',
            contains('auth token'),
          ),
        ),
      );
    });

    test('requestRestaurantApproval allows success response without token', () async {
      late http.Request capturedRequest;
      final service = AuthApiService(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            '{"message":"Registration request submitted.","data":{"status":"pending"}}',
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await service.requestRestaurantApproval(
        payload: {
          'name': 'Bella Kitchen',
          'restaurant_name': 'Bella Kitchen',
          'restaurant_description': 'Cuisine: Italian',
          'email': 'bella@example.com',
          'phone': '+96170000000',
          'password': 'Password123!',
          'password_confirmation': 'Password123!',
          'role': 'restaurant_owner',
        },
      );

      expect(capturedRequest.url.path, '/api/v1/auth/register');
      expect(result.token, isNull);
      expect(result.message, 'Registration request submitted.');
    });

    test(
      'forgotPassword posts email to the v1 forgot password endpoint',
      () async {
        late http.Request capturedRequest;

        final service = AuthApiService(
          client: MockClient((request) async {
            capturedRequest = request;
            return http.Response(
              '{"message":"If this email exists, a reset password link has been sent.","data":{"queued":true}}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        final message = await service.forgotPassword(
          email: ' customer@example.com ',
        );

        expect(capturedRequest.url.path, '/api/v1/auth/forgot-password');
        expect(
          capturedRequest.body,
          contains('"email":"customer@example.com"'),
        );
        expect(message, AuthApiService.forgotPasswordSuccessMessage);
      },
    );

    test('forgotPassword propagates backend validation errors', () async {
      final service = AuthApiService(
        client: MockClient((request) async {
          return http.Response(
            '{"message":"Validation failed.","errors":{"email":["Enter a valid email."]}}',
            422,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      expect(
        () => service.forgotPassword(email: 'bad-email'),
        throwsA(
          isA<AuthApiException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Validation failed.'), contains('HTTP 422')),
          ),
        ),
      );
    });
  });
}
