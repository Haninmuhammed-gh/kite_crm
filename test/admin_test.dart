import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_crm/features/admin/presentation/screens/admin_panel_screen.dart';
import 'package:kite_crm/features/auth/data/auth_repository.dart';
import 'package:kite_crm/features/auth/domain/user_profile.dart';
import 'package:kite_crm/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kite_crm/features/auth/presentation/screens/suspended_screen.dart';

class _MockUsersDirectoryController extends UsersDirectoryController {
  _MockUsersDirectoryController(this._initial);

  final List<UserProfile> _initial;
  String? lastUpdatedUserId;
  String? lastUpdatedRole;
  String? lastUpdatedStatus;

  @override
  Future<List<UserProfile>> build() async => _initial;

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    lastUpdatedUserId = userId;
    lastUpdatedRole = newRole;
    final index = _initial.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _initial[index] = _initial[index].copyWith(role: newRole);
    }
    state = AsyncValue.data(List.from(_initial));
  }

  @override
  Future<void> updateUserStatus(String userId, String newStatus) async {
    lastUpdatedUserId = userId;
    lastUpdatedStatus = newStatus;
    final index = _initial.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _initial[index] = _initial[index].copyWith(status: newStatus);
    }
    state = AsyncValue.data(List.from(_initial));
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required this.currentProfile}) : super(null);

  final UserProfile currentProfile;
  bool signedOut = false;

  @override
  Future<UserProfile?> fetchCurrentUserProfile() async => currentProfile;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  final sampleUsers = [
    UserProfile(
      id: 'u-1',
      fullName: 'Alice Walker',
      email: 'alice@example.com',
      role: 'admin',
      status: 'active',
      createdAt: DateTime(2025, 1, 10),
    ),
    UserProfile(
      id: 'u-2',
      fullName: 'Bob Smith',
      email: 'bob@example.com',
      role: 'member',
      status: 'active',
      createdAt: DateTime(2025, 2, 15),
    ),
    UserProfile(
      id: 'u-3',
      fullName: 'Charlie Brown',
      email: 'charlie@example.com',
      role: 'member',
      status: 'suspended',
      createdAt: DateTime(2025, 3, 20),
    ),
  ];

  group('AdminPanelScreen Widget Tests', () {
    testWidgets('Renders header and System Metrics summary strip',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersDirectoryControllerProvider.overrideWith(
              () => _MockUsersDirectoryController(List.from(sampleUsers)),
            ),
          ],
          child: const MaterialApp(
            home: AdminPanelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Admin Panel & User Management'), findsOneWidget);
      expect(
        find.text(
          'Manage team access permissions, role promotions, and account statuses',
        ),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);

      // System Metrics Strip
      expect(find.text('Total Registered Users'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // Total users in card & list count

      expect(find.text('Administrators'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // 1 admin, 1 suspended

      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 members

      expect(find.text('Suspended Accounts'), findsOneWidget);
    });

    testWidgets('Renders User Directory table with avatars, roles, and statuses',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersDirectoryControllerProvider.overrideWith(
              () => _MockUsersDirectoryController(List.from(sampleUsers)),
            ),
          ],
          child: const MaterialApp(
            home: AdminPanelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify User Directory title and users
      expect(find.text('User Directory'), findsOneWidget);
      expect(find.text('Alice Walker'), findsOneWidget);
      expect(find.text('alice@example.com • Joined Jan 10, 2025'), findsOneWidget);
      expect(find.text('Bob Smith'), findsOneWidget);
      expect(find.text('Charlie Brown'), findsOneWidget);

      // Role badges
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Member'), findsWidgets);

      // Status badges
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Suspended'), findsWidgets);
    });

    testWidgets('Filters user directory via search input and choice chips',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersDirectoryControllerProvider.overrideWith(
              () => _MockUsersDirectoryController(List.from(sampleUsers)),
            ),
          ],
          child: const MaterialApp(
            home: AdminPanelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type "bob" in search
      await tester.enterText(find.byType(TextField), 'bob');
      await tester.pumpAndSettle();

      expect(find.text('Bob Smith'), findsOneWidget);
      expect(find.text('Alice Walker'), findsNothing);
      expect(find.text('Charlie Brown'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Alice Walker'), findsOneWidget);
      expect(find.text('Bob Smith'), findsOneWidget);

      // Filter by "Admins" chip
      await tester.tap(find.text('Admins (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Walker'), findsOneWidget);
      expect(find.text('Bob Smith'), findsNothing);
      expect(find.text('Charlie Brown'), findsNothing);

      // Filter by "Suspended" chip
      await tester.tap(find.text('Suspended (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Charlie Brown'), findsOneWidget);
      expect(find.text('Alice Walker'), findsNothing);

      // Search with zero matches
      await tester.enterText(find.byType(TextField), 'nobodyhere');
      await tester.pumpAndSettle();

      expect(find.text('No users found'), findsOneWidget);
    });

    testWidgets('Interactive actions: Promotes member to admin',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockController =
          _MockUsersDirectoryController(List.from(sampleUsers));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersDirectoryControllerProvider.overrideWith(
              () => mockController,
            ),
          ],
          child: const MaterialApp(
            home: AdminPanelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Bob Smith's action menu (Bob is member, index 1)
      final moreButtons = find.byIcon(Icons.more_vert_rounded);
      expect(moreButtons, findsNWidgets(3));

      // Ensure visible and tap Bob's popup menu (2nd item)
      await tester.ensureVisible(moreButtons.at(1));
      await tester.pumpAndSettle();
      await tester.tap(moreButtons.at(1));
      await tester.pumpAndSettle();

      expect(find.text('Promote to Admin'), findsOneWidget);
      expect(find.text('Suspend Account'), findsOneWidget);

      // Tap Promote to Admin
      await tester.tap(find.text('Promote to Admin'));
      await tester.pumpAndSettle();

      expect(mockController.lastUpdatedUserId, 'u-2');
      expect(mockController.lastUpdatedRole, 'admin');
      expect(find.text('Promoted Bob Smith to Administrator'), findsOneWidget);
    });

    testWidgets('Interactive actions: Demotes admin to member with confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockController =
          _MockUsersDirectoryController(List.from(sampleUsers));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersDirectoryControllerProvider.overrideWith(
              () => mockController,
            ),
          ],
          child: const MaterialApp(
            home: AdminPanelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Alice Walker is admin (index 0)
      final aliceMore = find.byIcon(Icons.more_vert_rounded).first;
      await tester.ensureVisible(aliceMore);
      await tester.pumpAndSettle();
      await tester.tap(aliceMore);
      await tester.pumpAndSettle();

      expect(find.text('Demote to Member'), findsOneWidget);

      await tester.tap(find.text('Demote to Member'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Demote Administrator?'), findsOneWidget);
      await tester.tap(find.text('Demote').last);
      await tester.pumpAndSettle();

      expect(mockController.lastUpdatedUserId, 'u-1');
      expect(mockController.lastUpdatedRole, 'member');
      expect(find.text('Demoted Alice Walker to Member'), findsOneWidget);
    });

    testWidgets('Interactive actions: Suspends active account with confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockController =
          _MockUsersDirectoryController(List.from(sampleUsers));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersDirectoryControllerProvider.overrideWith(
              () => mockController,
            ),
          ],
          child: const MaterialApp(
            home: AdminPanelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Bob's popup menu (2nd item)
      final bobMore = find.byIcon(Icons.more_vert_rounded).at(1);
      await tester.ensureVisible(bobMore);
      await tester.pumpAndSettle();
      await tester.tap(bobMore);
      await tester.pumpAndSettle();

      // Tap Suspend Account
      await tester.tap(find.text('Suspend Account'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Suspend Account?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to suspend Bob Smith? They will be blocked from accessing CRM activities until re-activated.',
        ),
        findsOneWidget,
      );

      // Confirm suspend
      await tester.tap(find.text('Suspend').last);
      await tester.pumpAndSettle();

      expect(mockController.lastUpdatedUserId, 'u-2');
      expect(mockController.lastUpdatedStatus, 'suspended');
      expect(find.text('Suspended account for Bob Smith'), findsOneWidget);
    });

    testWidgets('Interactive actions: Activates suspended account',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockController =
          _MockUsersDirectoryController(List.from(sampleUsers));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            usersDirectoryControllerProvider.overrideWith(
              () => mockController,
            ),
          ],
          child: const MaterialApp(
            home: AdminPanelScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Charlie's popup menu (3rd item, currently suspended)
      final charlieMore = find.byIcon(Icons.more_vert_rounded).at(2);
      await tester.ensureVisible(charlieMore);
      await tester.pumpAndSettle();
      await tester.tap(charlieMore);
      await tester.pumpAndSettle();

      expect(find.text('Activate Account'), findsOneWidget);

      await tester.tap(find.text('Activate Account'));
      await tester.pumpAndSettle();

      expect(mockController.lastUpdatedUserId, 'u-3');
      expect(mockController.lastUpdatedStatus, 'active');
      expect(find.text('Activated account for Charlie Brown'), findsOneWidget);
    });
  });

  group('SuspendedScreen Widget Tests', () {
    testWidgets('Renders block icon, title, message, and Sign Out button',
        (tester) async {
      final fakeRepo = _FakeAuthRepository(
        currentProfile: const UserProfile(
          id: 'u-suspended',
          fullName: 'Banned User',
          email: 'banned@example.com',
          role: 'member',
          status: 'suspended',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: SuspendedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
      expect(find.text('Account Suspended'), findsOneWidget);
      expect(
        find.text(
          'Your access to Kite CRM has been temporarily suspended. Please contact your administrator.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign Out'), findsOneWidget);

      // Tap Sign Out
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(fakeRepo.signedOut, isTrue);
    });
  });

  group('Route Protection & Guard Tests', () {
    testWidgets('Non-admin member accessing /admin is redirected to /dashboard',
        (tester) async {
      final fakeMemberRepo = _FakeAuthRepository(
        currentProfile: const UserProfile(
          id: 'u-member',
          fullName: 'Clark Kent',
          email: 'clark@dailyplanet.com',
          role: 'member',
        ),
      );

      String? currentLocation;

      final router = GoRouter(
        initialLocation: '/admin',
        redirect: (context, state) async {
          if (state.matchedLocation.startsWith('/admin')) {
            final profile = await fakeMemberRepo.fetchCurrentUserProfile();
            if (profile == null || !profile.isAdmin) {
              return '/dashboard';
            }
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Dashboard Destination'));
            },
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Admin Panel Destination'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeMemberRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should be redirected to /dashboard
      expect(currentLocation, '/dashboard');
      expect(find.text('Dashboard Destination'), findsOneWidget);
      expect(find.text('Admin Panel Destination'), findsNothing);
    });

    testWidgets('Admin user accessing /admin successfully displays Admin Panel',
        (tester) async {
      final fakeAdminRepo = _FakeAuthRepository(
        currentProfile: const UserProfile(
          id: 'u-admin',
          fullName: 'Bruce Wayne',
          email: 'bruce@wayne.com',
          role: 'admin',
        ),
      );

      String? currentLocation;

      final router = GoRouter(
        initialLocation: '/admin',
        redirect: (context, state) async {
          if (state.matchedLocation.startsWith('/admin')) {
            final profile = await fakeAdminRepo.fetchCurrentUserProfile();
            if (profile == null || !profile.isAdmin) {
              return '/dashboard';
            }
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Dashboard Destination'));
            },
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Admin Panel Destination'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAdminRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentLocation, '/admin');
      expect(find.text('Admin Panel Destination'), findsOneWidget);
      expect(find.text('Dashboard Destination'), findsNothing);
    });

    testWidgets('Suspended user accessing any authenticated route is redirected to /suspended',
        (tester) async {
      final fakeSuspendedRepo = _FakeAuthRepository(
        currentProfile: const UserProfile(
          id: 'u-suspended',
          fullName: 'Banned User',
          email: 'banned@example.com',
          role: 'member',
          status: 'suspended',
        ),
      );

      String? currentLocation;

      final router = GoRouter(
        initialLocation: '/dashboard',
        redirect: (context, state) async {
          final profile = await fakeSuspendedRepo.fetchCurrentUserProfile();
          if (profile != null && profile.isSuspended) {
            if (state.matchedLocation != '/suspended') {
              return '/suspended';
            }
            return null;
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Dashboard Destination'));
            },
          ),
          GoRoute(
            path: '/suspended',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const SuspendedScreen();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeSuspendedRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should be redirected to /suspended
      expect(currentLocation, '/suspended');
      expect(find.text('Account Suspended'), findsOneWidget);
      expect(find.text('Dashboard Destination'), findsNothing);
    });

    testWidgets('Active user accessing /suspended is redirected to /dashboard',
        (tester) async {
      final fakeActiveRepo = _FakeAuthRepository(
        currentProfile: const UserProfile(
          id: 'u-active',
          fullName: 'Active User',
          email: 'active@example.com',
          role: 'member',
          status: 'active',
        ),
      );

      String? currentLocation;

      final router = GoRouter(
        initialLocation: '/suspended',
        redirect: (context, state) async {
          final profile = await fakeActiveRepo.fetchCurrentUserProfile();
          if (profile != null && profile.isSuspended) {
            if (state.matchedLocation != '/suspended') {
              return '/suspended';
            }
            return null;
          }
          if (state.matchedLocation == '/suspended') {
            return '/dashboard';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const Scaffold(body: Text('Dashboard Destination'));
            },
          ),
          GoRoute(
            path: '/suspended',
            builder: (context, state) {
              currentLocation = state.matchedLocation;
              return const SuspendedScreen();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeActiveRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentLocation, '/dashboard');
      expect(find.text('Dashboard Destination'), findsOneWidget);
      expect(find.text('Account Suspended'), findsNothing);
    });
  });
}
