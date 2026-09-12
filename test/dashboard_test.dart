import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/contacts/domain/contact.dart';
import 'package:kite_crm/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:kite_crm/features/dashboard/presentation/controllers/dashboard_metrics_controller.dart';
import 'package:kite_crm/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:kite_crm/features/deals/domain/deal.dart';
import 'package:kite_crm/features/deals/presentation/controllers/deals_controller.dart';

void main() {
  group('DashboardMetricsController logic tests', () {
    test('Calculates active leads, pipeline value, won deals, and conversion rate',
        () {
      final mockContacts = [
        const Contact(id: '1', firstName: 'John', lastName: 'Doe', status: 'new'),
        const Contact(id: '2', firstName: 'Jane', lastName: 'Smith', status: 'contacted'),
        const Contact(id: '3', firstName: 'Jim', lastName: 'Beam', status: 'qualified'),
        const Contact(id: '4', firstName: 'Jill', lastName: 'Hill', status: 'lost'),
      ];

      final mockDeals = [
        const Deal(id: 'd1', title: 'Deal A', value: 10000, stage: 'lead'),
        const Deal(id: 'd2', title: 'Deal B', value: 25000, stage: 'demo'),
        const Deal(id: 'd3', title: 'Deal C', value: 50000, stage: 'won'),
        const Deal(id: 'd4', title: 'Deal D', value: 30000, stage: 'lost'),
      ];

      final container = ProviderContainer(
        overrides: [
          contactsControllerProvider.overrideWith(
            () => _MockContactsController(mockContacts),
          ),
          dealsControllerProvider.overrideWith(
            () => _MockDealsController(mockDeals),
          ),
        ],
      );

      final metrics = container.read(dashboardMetricsControllerProvider);

      // Active leads: status is 'new' or 'contacted' -> 2
      expect(metrics.activeLeads, 2);

      // Pipeline value: deals not 'lost' -> 10000 + 25000 + 50000 = 85000
      expect(metrics.pipelineValue, 85000.0);

      // Won deals: count is 1
      expect(metrics.wonDeals, 1);

      // Total deals: 4
      expect(metrics.totalDeals, 4);

      // Conversion rate: 1 / 4 * 100 = 25.0%
      expect(metrics.conversionRate, 25.0);

      // Recent deals list length: 4 (<= 5)
      expect(metrics.recentDeals.length, 4);
    });
  });

  group('DashboardScreen widget tests', () {
    testWidgets('Renders live metric cards and recent deals list',
        (tester) async {
      final mockContacts = [
        const Contact(id: '1', firstName: 'Alex', lastName: 'Stone', status: 'new'),
      ];

      final mockDeals = [
        const Deal(
          id: 'd1',
          title: 'Cloud Infrastructure Upgrade',
          value: 60000,
          stage: 'won',
          contact: Contact(id: '1', firstName: 'Alex', lastName: 'Stone'),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactsControllerProvider.overrideWith(
              () => _MockContactsController(mockContacts),
            ),
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(mockDeals),
            ),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dashboard headers & title
      expect(find.text('Kite CRM'), findsWidgets);
      expect(find.text('Welcome to Kite CRM'), findsOneWidget);

      // Verify Pipeline Revenue Bar Chart
      expect(find.text('Pipeline Revenue by Stage'), findsOneWidget);

      // Verify live metrics
      expect(find.text('Active Leads'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // 1 active lead, 1 won deal
      expect(find.text('Pipeline Value'), findsOneWidget);
      expect(find.text('\$60,000'), findsWidgets);
      expect(find.text('Won Deals'), findsOneWidget);
      expect(find.text('Conversion Rate'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget); // 1 / 1 * 100

      // Verify Recent Deals activity section
      expect(find.text('Recent Deals Pipeline'), findsOneWidget);
      expect(find.text('Cloud Infrastructure Upgrade'), findsOneWidget);
    });
  });
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
