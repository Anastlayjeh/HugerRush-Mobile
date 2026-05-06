import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/services/auth_api_service.dart';

void main() {
  testWidgets('Login screen renders core content', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.text('HungerRush'), findsOneWidget);
    expect(find.text('Discover food. Order instantly.'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('OR CONTINUE WITH'), findsOneWidget);
    expect(
      find.textContaining("Don't have an account?", findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Sign Up', findRichText: true), findsOneWidget);
  });

  testWidgets('Forgot password button opens the reset-link screen', (
    WidgetTester tester,
  ) async {
    final authApiService = AuthApiService(
      client: MockClient((request) async {
        return http.Response(
          '{"message":"If this email exists, a reset password link has been sent."}',
          200,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authApiService: authApiService)),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Send Reset Link'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
  });

  testWidgets('Forgot password screen sends email and shows generic message', (
    WidgetTester tester,
  ) async {
    late http.Request capturedRequest;
    final authApiService = AuthApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"message":"If this email exists, a reset password link has been sent."}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordScreen(authApiService: authApiService)),
    );

    await tester.enterText(find.byType(TextField), 'customer@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(capturedRequest.url.path, '/api/v1/auth/forgot-password');
    expect(
      find.text(AuthApiService.forgotPasswordSuccessMessage),
      findsWidgets,
    );
  });
}
