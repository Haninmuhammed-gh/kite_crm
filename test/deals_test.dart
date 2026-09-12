import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/companies/domain/company.dart';
import 'package:kite_crm/features/contacts/domain/contact.dart';
import 'package:kite_crm/features/deals/domain/deal.dart';
import 'package:kite_crm/features/deals/presentation/controllers/deals_controller.dart';
import 'package:kite_crm/features/deals/presentation/screens/deals_board_screen.dart';
import 'package:kite_crm/features/deals/presentation/widgets/deal_card.dart';

void main() {
  group('Deal domain model tests', () {
    test('Deal serialization and join parsing', () {
      final json = {
        'id': 'deal-101',
        'contact_id': 'cont-55',
        'title': 'Cloud Migration Suite',
        'value': 75000,
        'stage': 'negotiation',
        'expected_close_date': '2026-12-15',
        'contacts': {
          'id': 'cont-55',
          'first_name': 'Bruce',
          'last_name': 'Wayne',
          'email': 'bruce@wayne.com',
        },
      };

      final deal = Deal.fromJson(json);
      expect(deal.id, 'deal-101');
      expect(deal.title, 'Cloud Migration Suite');
      expect(deal.value, 75000.0);
      expect(deal.stage, 'negotiation');
      expect(deal.contactName, 'Bruce Wayne');
      expect(deal.expectedCloseDate, DateTime(2026, 12, 15));

      final serialized = deal.toJson();
      expect(serialized['title'], 'Cloud Migration Suite');
      expect(serialized['value'], 75000.0);

      final insertJson = deal.toInsertJson();
      expect(insertJson['title'], 'Cloud Migration Suite');
      expect(insertJson['contact_id'], 'cont-55');
      expect(insertJson.containsKey('contacts'), isFalse);
    });

    test('Deal serialization and company relation parsing', () {
      final json = {
        'id': 'deal-202',
        'contact_id': 'cont-55',
        'company_id': 'comp-88',
        'title': 'AI Infrastructure Contract',
        'value': 120000,
        'stage': 'demo',
        'contacts': {
          'id': 'cont-55',
          'first_name': 'Diana',
          'last_name': 'Prince',
          'email': 'diana@themyscira.com',
        },
        'companies': {
          'id': 'comp-88',
          'name': 'Themyscira Enterprises',
          'industry': 'Defense',
          'website': 'https://themyscira.gov',
        },
      };

      final deal = Deal.fromJson(json);
      expect(deal.id, 'deal-202');
      expect(deal.companyId, 'comp-88');
      expect(deal.contactName, 'Diana Prince');
      expect(deal.companyName, 'Themyscira Enterprises');
      expect(deal.company?.industry, 'Defense');

      final insertJson = deal.toInsertJson();
      expect(insertJson['company_id'], 'comp-88');
      expect(insertJson.containsKey('companies'), isFalse);
    });

    test('Deal copyWith updates fields correctly', () {
      const deal = Deal(
        id: 'deal-1',
        title: 'Initial Title',
        value: 10000,
        stage: 'lead',
      );

      final updated = deal.copyWith(
        stage: 'won',
        value: 12500,
      );

      expect(updated.id, 'deal-1');
      expect(updated.stage, 'won');
      expect(updated.value, 12500.0);
      expect(updated.title, 'Initial Title');
    });
  });

  group('dealsByCompanyProvider tests', () {
    test('Filters deals matching specific companyId', () {
      final container = ProviderContainer(
        overrides: [
          dealsControllerProvider.overrideWith(
            () => _MockDealsController([
              const Deal(
                id: 'd1',
                title: 'Deal Comp 1',
                value: 10000,
                companyId: 'comp-1',
              ),
              const Deal(
                id: 'd2',
                title: 'Deal Comp 2',
                value: 20000,
                companyId: 'comp-2',
              ),
              const Deal(
                id: 'd3',
                title: 'Another Deal Comp 1',
                value: 30000,
                companyId: 'comp-1',
              ),
            ]),
          ),
        ],
      );

      final dealsForComp1 =
          container.read(dealsByCompanyProvider('comp-1')).value;
      expect(dealsForComp1?.length, 2);
      expect(dealsForComp1?.map((d) => d.id), containsAll(['d1', 'd3']));

      final dealsForComp2 =
          container.read(dealsByCompanyProvider('comp-2')).value;
      expect(dealsForComp2?.length, 1);
      expect(dealsForComp2?.first.id, 'd2');

      final dealsForComp3 =
          container.read(dealsByCompanyProvider('comp-3')).value;
      expect(dealsForComp3?.length, 0);
    });
  });

  group('DealCard tests', () {
    testWidgets('Renders deal details with formatted currency and contact',
        (tester) async {
      const deal = Deal(
        id: 'd1',
        title: 'Acme Annual Plan',
        value: 48000,
        stage: 'demo',
        contact: Contact(
          id: 'c1',
          firstName: 'Clark',
          lastName: 'Kent',
        ),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DealCard(deal: deal),
            ),
          ),
        ),
      );

      expect(find.text('Acme Annual Plan'), findsOneWidget);
      expect(find.text('\$48,000'), findsOneWidget);
      expect(find.text('Clark Kent'), findsOneWidget);
    });

    testWidgets('Renders clickable chips for contact and company',
        (tester) async {
      const deal = Deal(
        id: 'd2',
        title: 'Enterprise Server Migration',
        value: 95000,
        stage: 'negotiation',
        companyId: 'comp-10',
        contact: Contact(
          id: 'c2',
          firstName: 'Tony',
          lastName: 'Stark',
        ),
        company: Company(
          id: 'comp-10',
          name: 'Stark Industries',
        ),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DealCard(deal: deal),
            ),
          ),
        ),
      );

      expect(find.text('Enterprise Server Migration'), findsOneWidget);
      expect(find.text('\$95,000'), findsOneWidget);
      expect(find.text('Tony Stark'), findsOneWidget);
      expect(find.text('Stark Industries'), findsOneWidget);
    });
  });

  group('DealsBoardScreen tests', () {
    testWidgets('Renders Kanban columns and metrics strip', (tester) async {
      final mockDeals = [
        const Deal(
          id: 'd1',
          title: 'Starter Deal',
          value: 5000,
          stage: 'lead',
        ),
        const Deal(
          id: 'd2',
          title: 'Enterprise Pilot',
          value: 30000,
          stage: 'won',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(mockDeals),
            ),
          ],
          child: const MaterialApp(
            home: DealsBoardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deals Pipeline'), findsOneWidget);
      expect(find.text('Total Pipeline: '), findsOneWidget);
      expect(find.text('\$35,000'), findsOneWidget); // 5000 + 30000
      expect(find.text('Lead / Discovery'), findsOneWidget);
      expect(find.text('Demo / Pitch'), findsOneWidget);
      expect(find.text('Negotiation'), findsOneWidget);
      expect(find.text('Closed Won'), findsOneWidget);
      expect(find.text('Closed Lost'), findsOneWidget);
      expect(find.text('Starter Deal'), findsOneWidget);
      expect(find.text('Enterprise Pilot'), findsOneWidget);
      expect(find.text('New Deal'), findsOneWidget);
    });
  });
}

class _MockDealsController extends DealsController {
  _MockDealsController(this._initial);

  final List<Deal> _initial;

  @override
  AsyncValue<List<Deal>> build() {
    return AsyncValue.data(_initial);
  }
}
