import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/auth/data/auth_repository.dart';
import 'package:kite_crm/features/auth/domain/user_profile.dart';
import 'package:kite_crm/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kite_crm/features/auth/presentation/screens/profile_screen.dart';
import 'package:kite_crm/features/auth/presentation/widgets/user_avatar_button.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.profileToReturn}) : super(null);

  UserProfile? profileToReturn;
  String? updatedUserId;
  String? updatedName;
  bool signedOut = false;

  @override
  Future<UserProfile?> fetchCurrentUserProfile() async {
    return profileToReturn;
  }

  @override
  Future<void> updateProfileName(String userId, String newName) async {
    updatedUserId = userId;
    updatedName = newName;
    if (profileToReturn != null) {
      profileToReturn = profileToReturn!.copyWith(fullName: newName);
    }
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  group('UserProfile domain tests', () {
    test('Calculates initials properly for various full names and emails', () {
      const p1 = UserProfile(
        id: 'u-1',
        fullName: 'Bruce Wayne',
        email: 'bruce@waynecorp.com',
        role: 'admin',
      );
      expect(p1.initials, 'BW');

      const p2 = UserProfile(
        id: 'u-2',
        fullName: 'Clark',
        email: 'clark@dailyplanet.com',
        role: 'member',
      );
      expect(p2.initials, 'CL');

      const p3 = UserProfile(
        id: 'u-3',
        fullName: '',
        email: 'diana.prince@themyscira.gov',
        role: 'admin',
      );
      expect(p3.initials, 'DP');

      const p4 = UserProfile(
        id: 'u-4',
        fullName: null,
        email: 'barry@starlabs.org',
        role: 'member',
      );
      expect(p4.initials, 'BA');

      const p5 = UserProfile(
        id: 'u-5',
        fullName: null,
        email: '',
        role: 'member',
      );
      expect(p5.initials, '?');
    });
  });

  group('UserAvatarButton widget tests', () {
    testWidgets('Renders CircleAvatar with user initials and tooltip',
        (tester) async {
      const sampleProfile = UserProfile(
        id: 'user-123',
        fullName: 'Selina Kyle',
        email: 'selina@gotham.city',
        role: 'member',
      );

      final fakeRepo = _FakeAuthRepository(profileToReturn: sampleProfile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            currentUserProfileProvider.overrideWith(
              (ref) async => sampleProfile,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserAvatarButton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SK'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });

  group('ProfileScreen widget tests', () {
    final sampleProfile = UserProfile(
      id: 'usr-9876543210',
      fullName: 'Arthur Curry',
      email: 'arthur@atlantis.ocean',
      role: 'admin',
      createdAt: DateTime(2025, 5, 20),
    );

    testWidgets('Renders header with initials, role badge, and details',
        (tester) async {
      final fakeRepo = _FakeAuthRepository(profileToReturn: sampleProfile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            currentUserProfileProvider.overrideWith(
              (ref) async => sampleProfile,
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header details
      expect(find.text('AC'), findsOneWidget);
      expect(find.text('Arthur Curry'), findsWidgets);
      expect(find.text('arthur@atlantis.ocean'), findsWidgets);
      expect(find.text('Administrator'), findsOneWidget);

      // Account information form
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('User ID'), findsOneWidget);
      expect(find.text('usr-9876543210'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);

      // Actions
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Editing name and tapping Save Changes invokes updateUserName',
        (tester) async {
      final fakeRepo = _FakeAuthRepository(profileToReturn: sampleProfile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            currentUserProfileProvider.overrideWith(
              (ref) async => fakeRepo.profileToReturn,
            ),
            currentUserIdProvider.overrideWith((ref) => sampleProfile.id),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find TextFormField for Full Name
      final nameField = find.byType(TextFormField);
      expect(nameField, findsOneWidget);

      // Clear and enter new name
      await tester.enterText(nameField, 'King Arthur');
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Verify repository was called
      expect(fakeRepo.updatedUserId, 'usr-9876543210');
      expect(fakeRepo.updatedName, 'King Arthur');
      expect(find.text('Profile name updated successfully!'), findsOneWidget);
    });

    testWidgets('Tapping Sign Out displays confirmation dialog and triggers signOut',
        (tester) async {
      final fakeRepo = _FakeAuthRepository(profileToReturn: sampleProfile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            currentUserProfileProvider.overrideWith(
              (ref) async => sampleProfile,
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign Out button
      await tester.ensureVisible(find.text('Sign Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Sign Out?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to sign out of Kite CRM? You will need to log back in to access your dashboard, leads, and tasks.',
        ),
        findsOneWidget,
      );

      // Tap Sign Out in the dialog
      final dialogSignOutButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Sign Out'),
      );
      expect(dialogSignOutButton, findsOneWidget);
      await tester.tap(dialogSignOutButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.signedOut, isTrue);
    });
  });
}
