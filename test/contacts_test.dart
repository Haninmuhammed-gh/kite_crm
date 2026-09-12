import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kite_crm/features/contacts/domain/company.dart';
import 'package:kite_crm/features/contacts/domain/contact.dart';
import 'package:kite_crm/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:kite_crm/features/contacts/presentation/screens/contact_details_screen.dart';
import 'package:kite_crm/features/contacts/presentation/screens/contacts_list_screen.dart';
import 'package:kite_crm/features/contacts/presentation/screens/leads_screen.dart';
import 'package:kite_crm/features/contacts/presentation/widgets/contact_card.dart';
import 'package:kite_crm/features/contacts/presentation/widgets/status_badge.dart';
import 'package:kite_crm/features/deals/domain/deal.dart';
import 'package:kite_crm/features/deals/presentation/controllers/deals_controller.dart';

void main() {
  group('Company and Contact domain tests', () {
    test('Company serialization and deserialization', () {
      final json = {
        'id': 'comp-1',
        'name': 'Acme Corp',
        'industry': 'Software',
        'website': 'https://acme.com',
      };

      final company = Company.fromJson(json);
      expect(company.id, 'comp-1');
      expect(company.name, 'Acme Corp');
      expect(company.industry, 'Software');
      expect(company.website, 'https://acme.com');

      final serialized = company.toJson();
      expect(serialized['name'], 'Acme Corp');
    });

    test('Contact serialization and join parsing', () {
      final json = {
        'id': 'cont-1',
        'company_id': 'comp-1',
        'assigned_to': 'user-1',
        'first_name': 'Sarah',
        'last_name': 'Connor',
        'email': 'sarah@sky.net',
        'phone': '555-1234',
        'status': 'qualified',
        'companies': {
          'id': 'comp-1',
          'name': 'Cyberdyne',
          'industry': 'Defense',
          'website': 'https://cyberdyne.com',
        },
      };

      final contact = Contact.fromJson(json);
      expect(contact.id, 'cont-1');
      expect(contact.fullName, 'Sarah Connor');
      expect(contact.companyName, 'Cyberdyne');
      expect(contact.status, 'qualified');

      final insertJson = contact.toInsertJson();
      expect(insertJson['first_name'], 'Sarah');
      expect(insertJson['last_name'], 'Connor');
      expect(insertJson['company_id'], 'comp-1');
      expect(insertJson['status'], 'qualified');
      expect(insertJson.containsKey('companies'), isFalse);
    });

    test('Contact serialization and deserialization with notes', () {
      final json = {
        'id': 'cont-2',
        'first_name': 'Bruce',
        'last_name': 'Wayne',
        'email': 'bruce@wayne.com',
        'phone': '555-9999',
        'notes': 'Prefers communication after sunset.',
      };
      final contact = Contact.fromJson(json);
      expect(contact.notes, 'Prefers communication after sunset.');
      expect(contact.toJson()['notes'], 'Prefers communication after sunset.');
      expect(contact.toInsertJson()['notes'], 'Prefers communication after sunset.');

      final updated = contact.copyWith(notes: 'New note content');
      expect(updated.notes, 'New note content');
    });
  });

  group('StatusBadge widget tests', () {
    testWidgets('Renders correct formatted label and color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'qualified'),
          ),
        ),
      );

      expect(find.text('Qualified'), findsOneWidget);
    });
  });

  group('ContactsListScreen tests', () {
    testWidgets('Renders contact list with search bar and contacts',
        (tester) async {
      final mockContacts = [
        const Contact(
          id: 'c1',
          firstName: 'Alice',
          lastName: 'Smith',
          email: 'alice@alpha.com',
          phone: '111-222',
          status: 'qualified',
          company: Company(id: 'comp1', name: 'Alpha Inc'),
        ),
        const Contact(
          id: 'c2',
          firstName: 'Bob',
          lastName: 'Jones',
          email: 'bob@beta.com',
          phone: '333-444',
          status: 'contacted',
          company: Company(id: 'comp2', name: 'Beta LLC'),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(mockContacts),
            ),
          ],
          child: const MaterialApp(
            home: ContactsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Directory'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('Bob Jones'), findsOneWidget);
      expect(find.text('Alpha Inc'), findsOneWidget);
      expect(find.text('Beta LLC'), findsOneWidget);
      expect(find.text('Add Contact'), findsOneWidget);
    });
  });

  group('contactsByCompanyProvider relational tests', () {
    test('filters contacts matching the specific companyId', () {
      final mockContacts = [
        const Contact(
          id: 'c1',
          firstName: 'Alice',
          lastName: 'A',
          companyId: 'comp-10',
        ),
        const Contact(
          id: 'c2',
          firstName: 'Bob',
          lastName: 'B',
          companyId: 'comp-20',
        ),
        const Contact(
          id: 'c3',
          firstName: 'Charlie',
          lastName: 'C',
          companyId: 'comp-10',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          contactsControllerProvider.overrideWith(
            () => _MockContactsController(mockContacts),
          ),
        ],
      );

      final company10Contacts =
          container.read(contactsByCompanyProvider('comp-10'));
      expect(company10Contacts.value?.length, 2);
      expect(
        company10Contacts.value?.map((c) => c.firstName),
        containsAll(['Alice', 'Charlie']),
      );

      final company20Contacts =
          container.read(contactsByCompanyProvider('comp-20'));
      expect(company20Contacts.value?.length, 1);
      expect(company20Contacts.value?.first.firstName, 'Bob');

      final emptyContacts =
          container.read(contactsByCompanyProvider('comp-999'));
      expect(emptyContacts.value, isEmpty);
    });
  });

  group('qualifiedLeadsProvider tests', () {
    test('filters only contacts with status qualified', () {
      final mockContacts = [
        const Contact(
          id: '1',
          firstName: 'John',
          lastName: 'Doe',
          status: 'new',
        ),
        const Contact(
          id: '2',
          firstName: 'Jane',
          lastName: 'Smith',
          status: 'qualified',
        ),
        const Contact(
          id: '3',
          firstName: 'Jim',
          lastName: 'Beam',
          status: 'Qualified',
        ),
        const Contact(
          id: '4',
          firstName: 'Jill',
          lastName: 'Hill',
          status: 'lost',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          contactsControllerProvider.overrideWith(
            () => _MockContactsController(mockContacts),
          ),
        ],
      );

      final leads = container.read(qualifiedLeadsProvider);
      expect(leads.value?.length, 2);
      expect(
        leads.value?.map((c) => c.firstName),
        containsAll(['Jane', 'Jim']),
      );
    });
  });

  group('LeadsScreen widget tests', () {
    final mockContacts = [
      const Contact(
        id: '1',
        firstName: 'Diana',
        lastName: 'Prince',
        email: 'diana@themyscira.gov',
        phone: '555-7777',
        status: 'qualified',
        company: Company(id: 'c1', name: 'Justice League'),
      ),
      const Contact(
        id: '2',
        firstName: 'Barry',
        lastName: 'Allen',
        email: 'barry@ccpd.gov',
        status: 'contacted',
      ),
    ];

    testWidgets('Renders metrics strip, search bar, and qualified lead cards',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(mockContacts),
            ),
          ],
          child: const MaterialApp(
            home: LeadsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Qualified Leads'), findsOneWidget);
      expect(find.text('Total Leads'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // 1 qualified lead
      expect(find.text('Diana Prince'), findsOneWidget);
      expect(find.text('Barry Allen'), findsNothing); // contacted, not qualified
      expect(find.text('New Lead'), findsOneWidget);
    });

    testWidgets('Renders empty state when no qualified leads exist',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(
              () => _MockContactsController([
                const Contact(
                  id: '1',
                  firstName: 'Clark',
                  lastName: 'Kent',
                  status: 'new',
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: LeadsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No qualified leads yet'), findsOneWidget);
      expect(find.text('Add Contact'), findsOneWidget);
    });
  });

  group('ContactCard widget tests', () {
    const testContact = Contact(
      id: 'c-test-1',
      firstName: 'Tony',
      lastName: 'Stark',
      email: 'tony@stark.com',
      phone: '555-1234',
      status: 'qualified',
      notes: 'Genius, billionaire, philanthropist',
    );

    testWidgets(
        'Renders ContactCard with InkWell and navigates or taps properly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            contactsControllerProvider.overrideWith(
              () => _MockContactsController([testContact]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ContactCard(contact: testContact),
            ),
          ),
        ),
      );

      expect(find.text('Tony Stark'), findsOneWidget);
      expect(find.text('tony@stark.com'), findsOneWidget);
      expect(find.text('555-1234'), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });
  });

  group('ContactDetailsScreen widget tests', () {
    const contactWithAllActions = Contact(
      id: 'contact-all-1',
      firstName: 'Bruce',
      lastName: 'Wayne',
      email: 'bruce@wayne.com',
      phone: '+1 555-0199',
      status: 'qualified',
      notes: 'Initial meeting notes about Wayne Enterprises.',
      company: Company(id: 'comp-w', name: 'Wayne Enterprises'),
    );

    const contactWithoutActions = Contact(
      id: 'contact-none-1',
      firstName: 'Clark',
      lastName: 'Kent',
      status: 'new',
    );

    final mockContactDeals = [
      const Deal(
        id: 'deal-1',
        contactId: 'contact-all-1',
        title: 'Batmobile R&D Contract',
        value: 5000000,
        stage: 'proposal',
      ),
    ];

    testWidgets(
        'Renders full header details, quick action buttons, and notes',
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
            contactsControllerProvider.overrideWith(
              () => _MockContactsController([contactWithAllActions]),
            ),
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(mockContactDeals),
            ),
          ],
          child: const MaterialApp(
            home: ContactDetailsScreen(
              contactId: 'contact-all-1',
              initialContact: contactWithAllActions,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Bruce Wayne'), findsWidgets);
      expect(find.text('Wayne Enterprises'), findsOneWidget);
      expect(find.text('+1 555-0199'), findsOneWidget);
      expect(find.text('bruce@wayne.com'), findsOneWidget);
      expect(find.text('BW'), findsOneWidget); // Initials

      // Quick Actions Row (All 3 buttons present because phone & email exist)
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);

      // Notes section verification
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Initial meeting notes about Wayne Enterprises.'),
          findsOneWidget);
      expect(find.text('Save Note'), findsOneWidget);

      // Associated deals verification
      expect(find.text('Associated Deals'), findsOneWidget);
      expect(find.text('Batmobile R&D Contract'), findsOneWidget);
    });

    testWidgets(
        'Quick Actions row hides Call and WhatsApp when phone is absent, hides Email when email is absent',
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
            contactsControllerProvider.overrideWith(
              () => _MockContactsController([contactWithoutActions]),
            ),
            dealsControllerProvider.overrideWith(
              () => _MockDealsController([]),
            ),
          ],
          child: const MaterialApp(
            home: ContactDetailsScreen(
              contactId: 'contact-none-1',
              initialContact: contactWithoutActions,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick actions buttons should NOT be present
      expect(find.text('Call'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(
        find.text('No phone number or email registered for quick actions.'),
        findsOneWidget,
      );
    });

    testWidgets('Save Note triggers updateContact in controller',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockController =
          _MockContactsController([contactWithAllActions]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(() => mockController),
            dealsControllerProvider.overrideWith(() => _MockDealsController([])),
          ],
          child: const MaterialApp(
            home: ContactDetailsScreen(
              contactId: 'contact-all-1',
              initialContact: contactWithAllActions,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find TextFormField and enter new notes text
      final noteField = find.widgetWithText(
        TextFormField,
        'Initial meeting notes about Wayne Enterprises.',
      );
      expect(noteField, findsOneWidget);

      await tester.enterText(
          noteField, 'Updated meeting notes for Q3 planning.');
      await tester.pumpAndSettle();

      // Tap Save Note
      final saveBtn = find.text('Save Note');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify controller was called with updated notes
      expect(mockController.lastUpdatedNotes,
          'Updated meeting notes for Q3 planning.');
      expect(find.text('Notes updated successfully'), findsOneWidget);
    });
  });
}

class _MockContactsController extends ContactsController {
  _MockContactsController(this._initial);

  final List<Contact> _initial;
  String? lastUpdatedNotes;

  @override
  AsyncValue<List<Contact>> build() {
    return AsyncValue.data(_initial);
  }

  @override
  Future<bool> updateContact({
    required String contactId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? companyId,
    String status = 'new',
    String? assignedTo,
    String? notes,
  }) async {
    lastUpdatedNotes = notes;
    state = state.whenData((list) => list.map((c) {
          if (c.id == contactId) {
            return c.copyWith(
              firstName: firstName,
              lastName: lastName,
              email: email,
              phone: phone,
              companyId: companyId,
              status: status,
              assignedTo: assignedTo,
              notes: notes,
            );
          }
          return c;
        }).toList());
    return true;
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
