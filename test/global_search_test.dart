import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_crm/core/layout/main_layout.dart';
import 'package:kite_crm/core/presentation/widgets/global_search_dialog.dart';
import 'package:kite_crm/features/auth/domain/user_profile.dart';
import 'package:kite_crm/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kite_crm/features/companies/domain/company.dart';
import 'package:kite_crm/features/companies/presentation/controllers/companies_controller.dart';
import 'package:kite_crm/features/contacts/domain/contact.dart';
import 'package:kite_crm/features/contacts/presentation/controllers/contacts_controller.dart';

class _MockContactsController extends ContactsController {
  _MockContactsController(this._initial);

  final List<Contact> _initial;

  @override
  AsyncValue<List<Contact>> build() => AsyncValue.data(_initial);
}

class _MockCompaniesController extends CompaniesController {
  _MockCompaniesController(this._initial);

  final List<Company> _initial;

  @override
  AsyncValue<List<Company>> build() => AsyncValue.data(_initial);
}

void main() {
  final sampleContacts = [
    const Contact(
      id: 'c-1',
      firstName: 'Bruce',
      lastName: 'Wayne',
      email: 'bruce@wayne-enterprises.com',
      status: 'customer',
    ),
    const Contact(
      id: 'c-2',
      firstName: 'Diana',
      lastName: 'Prince',
      email: 'diana@themyscira.gov',
      status: 'lead',
    ),
  ];

  final sampleCompanies = [
    const Company(
      id: 'comp-1',
      name: 'Wayne Enterprises',
      industry: 'Defense & Technology',
    ),
    const Company(
      id: 'comp-2',
      name: 'Daily Planet',
      industry: 'Media & Publishing',
    ),
  ];

  group('GlobalSearchDialog Unit / Widget Tests', () {
    testWidgets('Displays initial search prompt when query is empty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(sampleContacts),
            ),
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GlobalSearchDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search Kite CRM'), findsOneWidget);
      expect(
        find.text('Type a name, email, or company to instantly jump to details'),
        findsOneWidget,
      );
      expect(find.text('ESC'), findsOneWidget);
    });

    testWidgets('Filters contacts and companies by text query',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(sampleContacts),
            ),
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GlobalSearchDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter query "bruce"
      await tester.enterText(find.byType(TextField), 'bruce');
      await tester.pumpAndSettle();

      expect(find.text('CONTACTS'), findsOneWidget);
      expect(find.text('Bruce Wayne'), findsOneWidget);
      expect(find.text('bruce@wayne-enterprises.com'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);
      // Diana Prince & Daily Planet should not be matched
      expect(find.text('Diana Prince'), findsNothing);
      expect(find.text('Daily Planet'), findsNothing);

      // Search for company "Daily"
      await tester.enterText(find.byType(TextField), 'Daily');
      await tester.pumpAndSettle();

      expect(find.text('COMPANIES'), findsOneWidget);
      expect(find.text('Daily Planet'), findsOneWidget);
      expect(find.text('Media & Publishing'), findsOneWidget);
      expect(find.text('Company'), findsOneWidget);
      expect(find.text('Bruce Wayne'), findsNothing);

      // Clear button clears text
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Search Kite CRM'), findsOneWidget);

      // Search for term with no matches
      await tester.enterText(find.byType(TextField), 'nonexistentquery123');
      await tester.pumpAndSettle();
      expect(find.text('No results found for "nonexistentquery123"'), findsOneWidget);
    });

    testWidgets('Tapping contact or company navigates to correct deep links',
        (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => Scaffold(
              body: ElevatedButton(
                onPressed: () => GlobalSearchDialog.show(context),
                child: const Text('Open Search'),
              ),
            ),
          ),
          GoRoute(
            path: '/contacts/:id',
            builder: (context, state) {
              navigatedRoute = '/contacts/${state.pathParameters['id']}';
              return Scaffold(body: Text('Contact Page: $navigatedRoute'));
            },
          ),
          GoRoute(
            path: '/companies/:id',
            builder: (context, state) {
              navigatedRoute = '/companies/${state.pathParameters['id']}';
              return Scaffold(body: Text('Company Page: $navigatedRoute'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(sampleContacts),
            ),
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open search dialog
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchDialog), findsOneWidget);

      // Search for Diana
      await tester.enterText(find.byType(TextField), 'Diana');
      await tester.pumpAndSettle();

      // Tap Diana Prince contact item
      await tester.tap(find.text('Diana Prince'));
      await tester.pumpAndSettle();

      // Dialog closed and navigated to contact route
      expect(find.byType(GlobalSearchDialog), findsNothing);
      expect(navigatedRoute, '/contacts/c-2');
      expect(find.text('Contact Page: /contacts/c-2'), findsOneWidget);

      // Navigate back and test company navigation
      router.go('/test');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Search for Wayne
      await tester.enterText(find.byType(TextField), 'Wayne Enterprises');
      await tester.pumpAndSettle();

      // Tap Wayne Enterprises company result
      await tester.tap(find.text('Wayne Enterprises').last);
      await tester.pumpAndSettle();

      expect(find.byType(GlobalSearchDialog), findsNothing);
      expect(navigatedRoute, '/companies/comp-1');
      expect(find.text('Company Page: /companies/comp-1'), findsOneWidget);
    });
  });

  group('MainLayout Search Integration Tests', () {
    testWidgets('Tapping AppBar search pill opens GlobalSearchDialog',
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
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(sampleContacts),
            ),
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
          ],
          child: const MaterialApp(
            home: MainLayout(
              currentLocation: '/dashboard',
              child: Scaffold(body: Text('Main Content Area')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search button in actions
      expect(find.text('Search...'), findsOneWidget);
      expect(find.text('Ctrl+K'), findsOneWidget);

      // Tap search button
      await tester.tap(find.text('Search...'));
      await tester.pumpAndSettle();

      // Dialog is displayed
      expect(find.byType(GlobalSearchDialog), findsOneWidget);
      expect(find.text('Search Kite CRM'), findsOneWidget);
    });

    testWidgets('Ctrl+K keyboard shortcut opens GlobalSearchDialog',
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
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(sampleContacts),
            ),
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
          ],
          child: const MaterialApp(
            home: MainLayout(
              currentLocation: '/dashboard',
              child: Scaffold(body: Text('Main Content Area')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send Ctrl+K shortcut event
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.byType(GlobalSearchDialog), findsOneWidget);
      expect(find.text('Search Kite CRM'), findsOneWidget);
    });
  });
}
