import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kite_crm/main.dart';

void main() {
  testWidgets('Unauthenticated app redirects to login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that router redirects to LoginScreen
    expect(find.text('Welcome to Kite CRM'), findsOneWidget);
    expect(
        find.text('Sign in to access your dashboard & leads'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('Login validation shows error messages on empty submission',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the Sign In button with empty fields
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Validation errors should appear
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Navigating from Login to Signup screen works properly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the 'Sign up' link
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    // Verify we are on the Signup screen
    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Join Kite CRM to streamline customer relations'),
        findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3)); // Name, Email, Password
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    // Scroll until 'Sign in' link is visible and tap to navigate back
    await tester.ensureVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Kite CRM'), findsOneWidget);
  });
}
