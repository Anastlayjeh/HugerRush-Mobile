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

    test('refresh sends expected payload and parses rotated tokens', () async {
      late http.Request capturedRequest;

      final service = AuthApiService(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            '{"message":"Token refreshed","data":{"access_token":"next-access","refresh_token":"next-refresh"}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await service.refresh(refreshToken: 'refresh-abc');

      expect(capturedRequest.url.path, '/api/v1/auth/refresh');
      expect(capturedRequest.body, contains('"refresh_token":"refresh-abc"'));
      expect(
        capturedRequest.body,
        contains('"device_name":"hunger-rush-mobile"'),
      );
      expect(result.token, 'next-access');
      expect(result.refreshToken, 'next-refresh');
    });

    test(
      'forgotPassword posts email to the public forgot password endpoint',
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

        expect(capturedRequest.url.path, '/api/forgot-password');
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
