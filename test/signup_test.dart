import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/auth/data/auth_repository.dart';
import 'package:kite_crm/features/auth/domain/user_profile.dart';
import 'package:kite_crm/features/auth/presentation/screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);

  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpFullName;
  bool shouldFailSignUp = false;
  String? signUpErrorMessage;
  Session? sessionToReturn;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpFullName = fullName;

    if (shouldFailSignUp) {
      throw AuthException(signUpErrorMessage ?? 'Sign-up failed');
    }

    return AuthResponse(
      session: sessionToReturn,
      user: const User(
        id: 'new-user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00.000Z',
      ),
    );
  }

  @override
  Future<UserProfile?> fetchCurrentUserProfile() async {
    return null;
  }
}

void main() {
  group('SignupScreen Email Confirmation Tests', () {
    late _FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = _FakeAuthRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
        ],
        child: const MaterialApp(
          home: SignupScreen(),
        ),
      );
    }

    testWidgets(
        'Displays green SnackBar with message when res.session == null (Confirm Email enabled)',
        (tester) async {
      fakeAuth.sessionToReturn = null; // Email confirmation required

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify form elements exist
      expect(find.text('Create an Account'), findsOneWidget);

      // Enter valid credentials
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Jane Doe'), 'Jane Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'name@company.com'),
          'jane@example.com');
      await tester.enterText(
          find.widgetWithText(
              TextFormField, 'Create a password (min 6 characters)'),
          'secret123');

      // Tap Create Account
      await tester.tap(find.text('Create Account'));
      await tester.pump(); // Start loading
      await tester.pumpAndSettle(); // Finish sign-up

      // Verify repository was invoked with correct arguments
      expect(fakeAuth.lastSignUpFullName, 'Jane Doe');
      expect(fakeAuth.lastSignUpEmail, 'jane@example.com');
      expect(fakeAuth.lastSignUpPassword, 'secret123');

      // Verify green SnackBar is shown with exact required message
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);

      final snackBar = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBar.backgroundColor, Colors.green);
      expect(
        find.text(
            'Registration successful! Please check your email to confirm your account.'),
        findsOneWidget,
      );

      // Verify UI handles state gracefully without errors
      expect(find.text('Create an Account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Does not show confirmation email SnackBar when session is not null',
        (tester) async {
      fakeAuth.sessionToReturn = Session(
        accessToken: 'access-token',
        tokenType: 'bearer',
        user: const User(
          id: 'user-123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01T00:00:00.000Z',
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Jane Doe'), 'Jane Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'name@company.com'),
          'jane@example.com');
      await tester.enterText(
          find.widgetWithText(
              TextFormField, 'Create a password (min 6 characters)'),
          'secret123');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // No confirmation email SnackBar should be shown
      expect(
        find.text(
            'Registration successful! Please check your email to confirm your account.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Shows error SnackBar and not success SnackBar on failure',
        (tester) async {
      fakeAuth.shouldFailSignUp = true;
      fakeAuth.signUpErrorMessage = 'User already registered';

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Jane Doe'), 'Jane Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'name@company.com'),
          'jane@example.com');
      await tester.enterText(
          find.widgetWithText(
              TextFormField, 'Create a password (min 6 characters)'),
          'secret123');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify error SnackBar is displayed
      expect(find.text('User already registered'), findsOneWidget);

      // Verify success SnackBar is NOT displayed
      expect(
        find.text(
            'Registration successful! Please check your email to confirm your account.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
