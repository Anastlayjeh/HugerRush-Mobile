import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Login screen renders core content', (WidgetTester tester) async {
    await tester.pumpWidget(const HungerRushApp());

    expect(find.text('HungerRush'), findsOneWidget);
    expect(find.text('Discover food. Order instantly.'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('OR CONTINUE WITH'), findsOneWidget);
    expect(
      find.textContaining("Don't have an account?", findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Sign Up', findRichText: true),
      findsOneWidget,
    );
  });
}
