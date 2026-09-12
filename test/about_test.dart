import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/about/presentation/screens/about_screen.dart';

void main() {
  group('AboutScreen Widget Tests', () {
    testWidgets('Renders page header and description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About Kite CRM'), findsOneWidget);
      expect(
        find.text('Platform overview, developer details, and support channels'),
        findsOneWidget,
      );
    });

    testWidgets('Renders Card 1 (App Info) with name, version, and description',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kite CRM'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(
        find.text(
          'A modern, relational customer relationship management platform.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
    });

    testWidgets('Renders Card 2 (The Team) with Tesseract Developers branding and tagline',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('The Team'), findsOneWidget);
      expect(find.text('Tesseract Developers'), findsOneWidget);
      expect(find.text('Small people building big apps.'), findsOneWidget);
      expect(find.byIcon(Icons.group_work_rounded), findsOneWidget);
    });

    testWidgets('Renders Card 3 (Help & Feedback) and Contact Support button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Feedback'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);

      // Scroll into view and verify button is tappable
      await tester.ensureVisible(find.text('Contact Support'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contact Support'));
      await tester.pumpAndSettle();
      // No unhandled exception should occur
    });
  });
}
