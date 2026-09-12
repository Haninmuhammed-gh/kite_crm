import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_crm/core/layout/crm_sidebar.dart';
import 'package:kite_crm/core/layout/main_layout.dart';
import 'package:kite_crm/features/auth/data/auth_repository.dart';
import 'package:kite_crm/features/auth/domain/user_profile.dart';
import 'package:kite_crm/features/auth/presentation/controllers/auth_controller.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);

  bool signedOut = false;

  @override
  Future<UserProfile?> fetchCurrentUserProfile() async {
    return const UserProfile(
      id: 'user-1',
      fullName: 'Test User',
      email: 'test@example.com',
      role: 'admin',
    );
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  group('CrmSidebar tests', () {
    late _FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = _FakeAuthRepository();
    });

    testWidgets('Renders all navigation items and brand in expanded state',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CrmSidebar(currentLocation: '/dashboard'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand
      expect(find.text('Kite CRM'), findsOneWidget);

      // 10 Navigation items for admin
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('Leads'), findsOneWidget);
      expect(find.text('Companies'), findsOneWidget);
      expect(find.text('Pipeline'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Sign Out
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('Hides Admin Panel from sidebar when user is a non-admin member',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'member-1',
                fullName: 'Peter Parker',
                email: 'peter@dailybugle.com',
                role: 'member',
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CrmSidebar(currentLocation: '/dashboard'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Admin Panel'), findsNothing);
    });

    testWidgets('Toggling collapse button hides text labels and shows tooltips',
        (tester) async {
      bool? lastCollapsed;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CrmSidebar(
                currentLocation: '/dashboard',
                onCollapseChanged: (collapsed) => lastCollapsed = collapsed,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially expanded
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byTooltip('Collapse sidebar'), findsOneWidget);

      // Tap collapse
      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pumpAndSettle();

      expect(lastCollapsed, isTrue);
      // In collapsed mode, item text is not displayed in the list tile
      expect(find.text('Dashboard'), findsNothing);
      expect(find.byTooltip('Expand sidebar'), findsOneWidget);

      // Tap expand
      await tester.tap(find.byTooltip('Expand sidebar'));
      await tester.pumpAndSettle();

      expect(lastCollapsed, isFalse);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Tapping navigation item invokes context.go', (tester) async {
      String? currentPath;

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              currentPath = state.matchedLocation;
              return const Scaffold(
                body: CrmSidebar(currentLocation: '/dashboard'),
              );
            },
          ),
          GoRoute(
            path: '/contacts',
            builder: (context, state) {
              currentPath = state.matchedLocation;
              return const Scaffold(
                body: CrmSidebar(currentLocation: '/contacts'),
              );
            },
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) {
              currentPath = state.matchedLocation;
              return const Scaffold(
                body: CrmSidebar(currentLocation: '/admin'),
              );
            },
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) {
              currentPath = state.matchedLocation;
              return const Scaffold(
                body: CrmSidebar(currentLocation: '/about'),
              );
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

      expect(currentPath, '/dashboard');

      // Tap Contacts
      await tester.tap(find.text('Contacts'));
      await tester.pumpAndSettle();

      expect(currentPath, '/contacts');

      // Tap Admin Panel
      await tester.tap(find.text('Admin Panel'));
      await tester.pumpAndSettle();

      expect(currentPath, '/admin');

      // Tap About
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(currentPath, '/about');
    });

    testWidgets('Tapping Sign Out displays confirmation dialog and triggers sign out',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CrmSidebar(currentLocation: '/dashboard'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign Out
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to sign out of Kite CRM?'),
          findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(fakeAuth.signedOut, isFalse);

      // Tap Sign Out again and confirm
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Find the Sign Out FilledButton inside the dialog actions
      final dialogSignOut = find.widgetWithText(FilledButton, 'Sign Out');
      await tester.tap(dialogSignOut);
      await tester.pumpAndSettle();

      expect(fakeAuth.signedOut, isTrue);
    });

    testWidgets('Forces collapsed state (72px) and hides toggle buttons on small screens (< 800px)',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CrmSidebar(
                currentLocation: '/dashboard',
                initialCollapsed: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sidebar width must be 72.0 despite initialCollapsed being false
      final sidebarSize = tester.getSize(find.byType(CrmSidebar));
      expect(sidebarSize.width, 72.0);

      // Nav labels must not be displayed
      expect(find.text('Dashboard'), findsNothing);

      // Expand/Collapse toggle buttons must not be rendered
      expect(find.byTooltip('Expand sidebar'), findsNothing);
      expect(find.byTooltip('Collapse sidebar'), findsNothing);
    });
  });

  group('MainLayout shell tests', () {
    testWidgets('Renders global AppBar with Kite CRM brand and embedded child',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'u-1',
                fullName: 'Tony Stark',
                email: 'tony@stark.com',
                role: 'admin',
              ),
            ),
          ],
          child: const MaterialApp(
            home: MainLayout(
              currentLocation: '/dashboard',
              child: Scaffold(
                body: Text('Main Content Area'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify global AppBar
      expect(find.text('Kite CRM'), findsWidgets);
      expect(find.text('Search...'), findsOneWidget);
      expect(find.text('Ctrl+K'), findsOneWidget);

      // Verify sidebar is present
      expect(find.byType(CrmSidebar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);

      // Verify child body is present
      expect(find.text('Main Content Area'), findsOneWidget);
    });
  });
}
