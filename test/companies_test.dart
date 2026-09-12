import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/auth/domain/user_profile.dart';
import 'package:kite_crm/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kite_crm/features/companies/domain/company.dart';
import 'package:kite_crm/features/companies/presentation/controllers/companies_controller.dart';
import 'package:kite_crm/features/companies/presentation/screens/companies_screen.dart';
import 'package:kite_crm/features/companies/presentation/screens/company_details_screen.dart';
import 'package:kite_crm/features/companies/presentation/widgets/company_card.dart';
import 'package:kite_crm/features/contacts/domain/contact.dart';
import 'package:kite_crm/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:kite_crm/features/deals/domain/deal.dart';
import 'package:kite_crm/features/deals/presentation/controllers/deals_controller.dart';

void main() {
  group('Company domain model tests', () {
    test('Company serialization and deserialization with assignedTo and phone', () {
      final json = {
        'id': 'comp-100',
        'name': 'Stark Industries',
        'industry': 'Defense & Tech',
        'website': 'https://starkindustries.com',
        'phone': '+1 (555) 999-8888',
        'assigned_to': 'user-tony',
        'created_at': '2026-09-10T00:00:00.000Z',
      };

      final company = Company.fromJson(json);
      expect(company.id, 'comp-100');
      expect(company.name, 'Stark Industries');
      expect(company.industry, 'Defense & Tech');
      expect(company.website, 'https://starkindustries.com');
      expect(company.phone, '+1 (555) 999-8888');
      expect(company.assignedTo, 'user-tony');
      expect(company.initials, 'SI');

      final insertJson = company.toInsertJson();
      expect(insertJson['name'], 'Stark Industries');
      expect(insertJson['industry'], 'Defense & Tech');
      expect(insertJson['website'], 'https://starkindustries.com');
      expect(insertJson['phone'], '+1 (555) 999-8888');
      expect(insertJson['assigned_to'], 'user-tony');
      expect(insertJson.containsKey('id'), isFalse);
    });

    test('Company initials helper handles single word and empty', () {
      const single = Company(id: '1', name: 'Google');
      expect(single.initials, 'GO');

      const multiple = Company(id: '2', name: 'Acme Corporation Inc');
      expect(multiple.initials, 'AC');

      const fallback = Company(id: '3', name: '');
      expect(fallback.initials, 'CO');
    });
  });

  group('CompanyCard RBAC context menu tests', () {
    const testCompany = Company(
      id: 'comp-1',
      name: 'Wayne Enterprises',
      industry: 'Conglomerate',
      website: 'https://wayne.corp',
      assignedTo: 'user-bruce',
    );

    testWidgets('Admin user can see both Edit and Delete options', (tester) async {
      final adminProfile = UserProfile(
        id: 'user-admin',
        role: 'admin',
        fullName: 'Admin User',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) => adminProfile),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CompanyCard(company: testCompany),
            ),
          ),
        ),
      );

      expect(find.text('Wayne Enterprises'), findsOneWidget);
      expect(find.text('Conglomerate'), findsOneWidget);
      expect(find.text('https://wayne.corp'), findsOneWidget);

      // Open context menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit Company'), findsOneWidget);
      expect(find.text('Delete Company'), findsOneWidget);
    });

    testWidgets('Member owner sees Edit Company but not Delete Company',
        (tester) async {
      final memberOwner = UserProfile(
        id: 'user-bruce',
        role: 'member',
        fullName: 'Bruce Wayne',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) => memberOwner),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CompanyCard(company: testCompany),
            ),
          ),
        ),
      );

      // Open context menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Edit Company'), findsOneWidget);
      expect(find.text('Delete Company'), findsNothing);
    });

    testWidgets('Member non-owner cannot see Edit or Delete options',
        (tester) async {
      final memberOther = UserProfile(
        id: 'user-clark',
        role: 'member',
        fullName: 'Clark Kent',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) => memberOther),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CompanyCard(company: testCompany),
            ),
          ),
        ),
      );

      // Kebab menu button should not even be rendered if no actions allowed
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });

    testWidgets('CompanyCard renders phone number when present', (tester) async {
      const companyWithPhone = Company(
        id: 'comp-phone-1',
        name: 'Cyberdyne Systems',
        industry: 'Robotics',
        website: 'https://cyberdyne.com',
        phone: '+1 (555) 777-8888',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CompanyCard(company: companyWithPhone),
            ),
          ),
        ),
      );

      expect(find.text('+1 (555) 777-8888'), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    });
  });

  group('CompaniesScreen widget tests', () {
    final mockCompanies = [
      const Company(
        id: '1',
        name: 'Apex Innovations',
        industry: 'Software',
        website: 'https://apex.io',
        assignedTo: 'user-1',
      ),
      const Company(
        id: '2',
        name: 'Blue Star Logistics',
        industry: 'Logistics',
        website: 'https://bluestar.com',
        assignedTo: 'user-2',
      ),
    ];

    testWidgets('Renders header metrics, search, industry chips, and cards',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(mockCompanies),
            ),
            currentUserProfileProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: CompaniesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Companies Directory'), findsOneWidget);
      expect(find.text('Total Companies'), findsOneWidget);
      expect(find.text('Apex Innovations'), findsOneWidget);
      expect(find.text('Blue Star Logistics'), findsOneWidget);
      expect(find.text('New Company'), findsOneWidget);
    });
  });

  group('CompanyDetailsScreen widget tests', () {
    const detailCompany = Company(
      id: 'comp-detail-1',
      name: 'Stark Enterprises',
      industry: 'Aerospace & Energy',
      website: 'https://stark.com',
      phone: '+1 (555) 999-4321',
    );

    final mockAssociatedContacts = [
      const Contact(
        id: 'c-1',
        companyId: 'comp-detail-1',
        firstName: 'Pepper',
        lastName: 'Potts',
        email: 'pepper@stark.com',
        phone: '555-1111',
        status: 'qualified',
      ),
      const Contact(
        id: 'c-2',
        companyId: 'comp-detail-1',
        firstName: 'Happy',
        lastName: 'Hogan',
        email: 'happy@stark.com',
        status: 'contacted',
      ),
    ];

    final mockCompanyDeals = [
      const Deal(
        id: 'deal-comp-1',
        companyId: 'comp-detail-1',
        title: 'Arc Reactor Supply Contract',
        value: 1200000,
        stage: 'negotiation',
      ),
    ];

    testWidgets(
        'Renders full company details in header, contacts, and active deals',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController([detailCompany]),
            ),
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(mockAssociatedContacts),
            ),
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(mockCompanyDeals),
            ),
          ],
          child: const MaterialApp(
            home: CompanyDetailsScreen(
              companyId: 'comp-detail-1',
              initialCompany: detailCompany,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Stark Enterprises'), findsWidgets);
      expect(find.text('Aerospace & Energy'), findsOneWidget);
      expect(find.text('https://stark.com'), findsOneWidget);
      expect(find.text('+1 (555) 999-4321'), findsOneWidget);
      expect(find.text('SE'), findsOneWidget); // Initials avatar

      // Verify Associated Contacts section
      expect(find.text('Associated Contacts'), findsOneWidget);
      expect(find.text('Pepper Potts'), findsOneWidget);
      expect(find.text('Happy Hogan'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
      expect(find.text('Add Contact'), findsWidgets);

      // Verify Active Deals section
      expect(find.text('Active Deals'), findsOneWidget);
      expect(find.text('Arc Reactor Supply Contract'), findsOneWidget);
      expect(find.text('\$1,200,000'), findsOneWidget);
      expect(find.text('Add Deal'), findsOneWidget);
    });

    testWidgets('Renders empty states when company has no contacts or deals',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController([detailCompany]),
            ),
            contactsControllerProvider.overrideWith(
              () => _MockContactsController([]),
            ),
            dealsControllerProvider.overrideWith(
              () => _MockDealsController([]),
            ),
          ],
          child: const MaterialApp(
            home: CompanyDetailsScreen(
              companyId: 'comp-detail-1',
              initialCompany: detailCompany,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No contacts added for this company yet'),
        findsOneWidget,
      );
      expect(find.text('Add First Contact'), findsOneWidget);

      expect(
        find.text('No active deals for this company yet'),
        findsOneWidget,
      );
      expect(find.text('Create Deal'), findsOneWidget);
    });
  });
}

class _MockCompaniesController extends CompaniesController {
  _MockCompaniesController(this._initial);

  final List<Company> _initial;

  @override
  AsyncValue<List<Company>> build() {
    return AsyncValue.data(_initial);
  }
}

class _MockContactsController extends ContactsController {
  _MockContactsController(this._initial);

  final List<Contact> _initial;

  @override
  AsyncValue<List<Contact>> build() {
    return AsyncValue.data(_initial);
  }
}

class _MockDealsController extends DealsController {
  _MockDealsController(this._initial);

  final List<Deal> _initial;

  @override
  AsyncValue<List<Deal>> build() {
    return AsyncValue.data(_initial);
  }
}
