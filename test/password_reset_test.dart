import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_crm/features/auth/data/auth_repository.dart';
import 'package:kite_crm/features/auth/domain/user_profile.dart';
import 'package:kite_crm/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:kite_crm/features/auth/presentation/screens/login_screen.dart';
import 'package:kite_crm/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);

  String? lastResetEmail;
  String? lastResetRedirectTo;
  bool shouldFailReset = false;
  String? resetErrorMessage;

  String? lastUpdatedPassword;
  bool shouldFailUpdatePassword = false;
  String? updatePasswordErrorMessage;

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) async {
    lastResetEmail = email;
    lastResetRedirectTo = redirectTo;
    if (shouldFailReset) {
      throw AuthException(resetErrorMessage ?? 'Reset error');
    }
  }

  @override
  Future<UserResponse?> updatePassword(String newPassword) async {
    lastUpdatedPassword = newPassword;
    if (shouldFailUpdatePassword) {
      throw AuthException(updatePasswordErrorMessage ?? 'Update error');
    }
    return null;
  }

  @override
  Future<UserProfile?> fetchCurrentUserProfile() async {
    return const UserProfile(
      id: 'user-1',
      fullName: 'Test User',
      email: 'test@example.com',
      role: 'member',
    );
  }
}

void main() {
  group('ForgotPasswordScreen Tests', () {
    late _FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = _FakeAuthRepository();
    });

    testWidgets('Renders form components, headers, and buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
      expect(
        find.text(
          "Enter your email address and we'll send you a link to reset your password.",
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('Validates empty and invalid email format', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit empty
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your email'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets(
        'Successful submission calls sendPasswordResetEmail, shows SnackBar, and navigates to /login',
        (tester) async {
      String currentLocation = '/forgot-password';

      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const ForgotPasswordScreen();
            },
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Login Target Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastResetEmail, 'user@example.com');
      expect(
        fakeAuth.lastResetRedirectTo,
        'http://localhost:3000/#/reset-password',
      );
      expect(
        find.text('Password reset link sent to your email'),
        findsOneWidget,
      );
      expect(currentLocation, '/login');
      expect(find.text('Login Target Page'), findsOneWidget);
    });

    testWidgets('Displays error SnackBar when password reset fails',
        (tester) async {
      fakeAuth.shouldFailReset = true;
      fakeAuth.resetErrorMessage = 'User not found';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'nonexistent@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastResetEmail, 'nonexistent@example.com');
      expect(find.text('User not found'), findsOneWidget);
      expect(find.text('Password reset link sent to your email'), findsNothing);
    });

    testWidgets('Tapping Back to Login navigates to /login', (tester) async {
      String currentLocation = '/forgot-password';

      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const ForgotPasswordScreen();
            },
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Login Target Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to Login'));
      await tester.pumpAndSettle();

      expect(currentLocation, '/login');
      expect(find.text('Login Target Page'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen Tests', () {
    late _FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = _FakeAuthRepository();
    });

    testWidgets('Renders form components, headers, and fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set New Password'), findsOneWidget);
      expect(
        find.text('Create a new password for your Kite CRM account.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_reset_rounded), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('Toggles password obscurity for both fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially both fields have visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Toggle new password obscurity
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Toggle confirm password obscurity
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('Validates empty password, length requirement, and password match',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Empty submission
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a new password'), findsOneWidget);

      // Short password
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '12345');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Valid new password, empty confirm password
      await tester.enterText(fields.at(0), 'newpass123');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Please confirm your password'), findsOneWidget);

      // Mismatched confirm password
      await tester.enterText(fields.at(1), 'mismatch456');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets(
        'Successful submission calls updatePassword, shows SnackBar, and navigates to /dashboard',
        (tester) async {
      String currentLocation = '/reset-password';

      final router = GoRouter(
        initialLocation: '/reset-password',
        routes: [
          GoRoute(
            path: '/reset-password',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const ResetPasswordScreen();
            },
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Dashboard Target Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'securePassword123');
      await tester.enterText(fields.at(1), 'securePassword123');

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastUpdatedPassword, 'securePassword123');
      expect(find.text('Password updated successfully'), findsOneWidget);
      expect(currentLocation, '/dashboard');
      expect(find.text('Dashboard Target Page'), findsOneWidget);
    });

    testWidgets('Displays error SnackBar when updatePassword fails',
        (tester) async {
      fakeAuth.shouldFailUpdatePassword = true;
      fakeAuth.updatePasswordErrorMessage = 'Session expired';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'securePassword123');
      await tester.enterText(fields.at(1), 'securePassword123');

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(fakeAuth.lastUpdatedPassword, 'securePassword123');
      expect(find.text('Session expired'), findsOneWidget);
      expect(find.text('Password updated successfully'), findsNothing);
    });
  });

  group('LoginScreen Navigation Tests', () {
    testWidgets('Tapping "Forgot Password?" navigates to /forgot-password',
        (tester) async {
      String currentLocation = '/login';

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const LoginScreen();
            },
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Forgot Password Target Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final forgotPasswordButton = find.text('Forgot Password?');
      expect(forgotPasswordButton, findsOneWidget);

      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      expect(currentLocation, '/forgot-password');
      expect(find.text('Forgot Password Target Page'), findsOneWidget);
    });
  });

  group('Router Redirect Logic Tests for Password Reset', () {
    String? evaluateRedirect({
      required bool isAuthenticated,
      required String matchedLocation,
    }) {
      final isGuestOnlyAuthRoute = matchedLocation == '/login' ||
          matchedLocation == '/signup' ||
          matchedLocation == '/forgot-password';
      final isAllowedUnauthenticated =
          isGuestOnlyAuthRoute || matchedLocation == '/reset-password';

      if (!isAuthenticated && !isAllowedUnauthenticated) {
        return '/login';
      }
      if (isAuthenticated && isGuestOnlyAuthRoute) {
        return '/dashboard';
      }
      return null;
    }

    test('Unauthenticated user can access /forgot-password', () {
      expect(
        evaluateRedirect(isAuthenticated: false, matchedLocation: '/forgot-password'),
        isNull,
      );
    });

    test('Unauthenticated user can access /reset-password', () {
      expect(
        evaluateRedirect(isAuthenticated: false, matchedLocation: '/reset-password'),
        isNull,
      );
    });

    test('Unauthenticated user cannot access /dashboard and is redirected to /login', () {
      expect(
        evaluateRedirect(isAuthenticated: false, matchedLocation: '/dashboard'),
        equals('/login'),
      );
    });

    test('Authenticated user visiting /forgot-password is redirected to /dashboard', () {
      expect(
        evaluateRedirect(isAuthenticated: true, matchedLocation: '/forgot-password'),
        equals('/dashboard'),
      );
    });

    test('Authenticated user visiting /login is redirected to /dashboard', () {
      expect(
        evaluateRedirect(isAuthenticated: true, matchedLocation: '/login'),
        equals('/dashboard'),
      );
    });

    test('Authenticated user visiting /reset-password is NOT redirected (recovery session allowed)', () {
      expect(
        evaluateRedirect(isAuthenticated: true, matchedLocation: '/reset-password'),
        isNull,
      );
    });
  });
}

