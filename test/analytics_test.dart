import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kite_crm/features/analytics/presentation/controllers/analytics_controller.dart';
import 'package:kite_crm/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:kite_crm/features/analytics/presentation/widgets/industry_pie_chart.dart';
import 'package:kite_crm/features/analytics/presentation/widgets/pipeline_bar_chart.dart';
import 'package:kite_crm/features/analytics/presentation/widgets/task_completion_card.dart';
import 'package:kite_crm/features/companies/domain/company.dart';
import 'package:kite_crm/features/companies/presentation/controllers/companies_controller.dart';
import 'package:kite_crm/features/deals/domain/deal.dart';
import 'package:kite_crm/features/deals/presentation/controllers/deals_controller.dart';
import 'package:kite_crm/features/tasks/domain/task.dart';
import 'package:kite_crm/features/tasks/presentation/controllers/tasks_controller.dart';

class _MockDealsController extends DealsController {
  _MockDealsController(this._initial);

  final List<Deal> _initial;

  @override
  AsyncValue<List<Deal>> build() => AsyncValue.data(_initial);
}

class _MockCompaniesController extends CompaniesController {
  _MockCompaniesController(this._initial);

  final List<Company> _initial;

  @override
  AsyncValue<List<Company>> build() => AsyncValue.data(_initial);
}

class _MockTasksController extends TasksController {
  _MockTasksController(this._initial);

  final List<Task> _initial;

  @override
  AsyncValue<List<Task>> build() => AsyncValue.data(_initial);
}

void main() {
  group('Analytics state aggregation provider tests', () {
    test('dealsByStageChartProvider groups and sums deals by stage', () {
      final mockDeals = [
        const Deal(id: '1', title: 'Deal A', value: 15000, stage: 'lead'),
        const Deal(id: '2', title: 'Deal B', value: 25000, stage: 'lead'),
        const Deal(id: '3', title: 'Deal C', value: 40000, stage: 'demo'),
        const Deal(id: '4', title: 'Deal D', value: 50000, stage: 'negotiation'),
        const Deal(id: '5', title: 'Deal E', value: 100000, stage: 'won'),
        const Deal(id: '6', title: 'Deal F', value: 20000, stage: 'lost'),
      ];

      final container = ProviderContainer(
        overrides: [
          dealsControllerProvider.overrideWith(
            () => _MockDealsController(mockDeals),
          ),
        ],
      );

      final stagesAsync = container.read(dealsByStageChartProvider);
      expect(stagesAsync.hasValue, isTrue);

      final stages = stagesAsync.value!;
      final leadStage = stages.firstWhere((s) => s.stageKey == 'lead');
      expect(leadStage.totalValue, 40000.0);
      expect(leadStage.count, 2);

      final demoStage = stages.firstWhere((s) => s.stageKey == 'demo');
      expect(demoStage.totalValue, 40000.0);
      expect(demoStage.count, 1);

      final negotiationStage = stages.firstWhere((s) => s.stageKey == 'negotiation');
      expect(negotiationStage.totalValue, 50000.0);
      expect(negotiationStage.count, 1);

      final wonStage = stages.firstWhere((s) => s.stageKey == 'won');
      expect(wonStage.totalValue, 100000.0);
      expect(wonStage.count, 1);

      final lostStage = stages.firstWhere((s) => s.stageKey == 'lost');
      expect(lostStage.totalValue, 20000.0);
      expect(lostStage.count, 1);
    });

    test('companiesByIndustryProvider counts and computes percentage by industry', () {
      final mockCompanies = [
        const Company(id: '1', name: 'Alpha Tech', industry: 'Technology'),
        const Company(id: '2', name: 'Beta Software', industry: 'Technology'),
        const Company(id: '3', name: 'Gamma Health', industry: 'Healthcare'),
        const Company(id: '4', name: 'Delta Wealth', industry: 'Finance'),
        const Company(id: '5', name: 'Mystery Corp', industry: null),
      ];

      final container = ProviderContainer(
        overrides: [
          companiesControllerProvider.overrideWith(
            () => _MockCompaniesController(mockCompanies),
          ),
        ],
      );

      final industriesAsync = container.read(companiesByIndustryProvider);
      expect(industriesAsync.hasValue, isTrue);

      final industries = industriesAsync.value!;
      expect(industries.length, 4);

      // Technology should be top with 2 companies (40%)
      expect(industries[0].industry, 'Technology');
      expect(industries[0].count, 2);
      expect(industries[0].percentage, 40.0);

      // Unspecified should be present for null industry
      expect(industries.any((i) => i.industry == 'Unspecified'), isTrue);
    });

    test('taskCompletionStatsProvider calculates status breakdown and completion rate', () {
      final now = DateTime.now();
      final mockTasks = [
        Task(
          id: 't1',
          title: 'Completed Task 1',
          status: 'completed',
          contactId: 'c1',
        ),
        Task(
          id: 't2',
          title: 'Completed Task 2',
          status: 'completed',
          contactId: 'c1',
        ),
        Task(
          id: 't3',
          title: 'In Progress Task',
          status: 'in_progress',
          contactId: 'c2',
        ),
        Task(
          id: 't4',
          title: 'Overdue Pending Task',
          status: 'pending',
          dueDate: now.subtract(const Duration(days: 2)),
          contactId: 'c2',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          tasksControllerProvider.overrideWith(
            () => _MockTasksController(mockTasks),
          ),
        ],
      );

      final statsAsync = container.read(taskCompletionStatsProvider);
      expect(statsAsync.hasValue, isTrue);

      final stats = statsAsync.value!;
      expect(stats.total, 4);
      expect(stats.completed, 2);
      expect(stats.inProgress, 1);
      expect(stats.pending, 1);
      expect(stats.completionRate, 50.0);
      expect(stats.overdueCount, 1);
    });
  });

  group('Analytics widgets tests', () {
    final sampleDeals = [
      const Deal(id: '1', title: 'Tech Stack Upgrade', value: 80000, stage: 'won'),
      const Deal(id: '2', title: 'Security Audit', value: 30000, stage: 'lead'),
    ];

    final sampleCompanies = [
      const Company(id: '1', name: 'Wayne Enterprises', industry: 'Defense'),
      const Company(id: '2', name: 'Queen Industries', industry: 'Technology'),
    ];

    final sampleTasks = [
      Task(id: 't1', title: 'Follow-up Call', status: 'completed', contactId: 'c1'),
      Task(id: 't2', title: 'Send Proposal', status: 'pending', contactId: 'c2'),
    ];

    testWidgets('PipelineBarChart renders BarChart with data and titles',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(sampleDeals),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PipelineBarChart(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pipeline Revenue by Stage'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('\$110,000'), findsOneWidget);
      expect(find.text('Lead'), findsOneWidget);
      expect(find.text('Won'), findsOneWidget);
    });

    testWidgets(
        'PipelineBarChart rotates labels, abbreviates Negotiation to Negot. and reduces font size on mobile viewport',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mobileDeals = [
        const Deal(id: '1', title: 'Tech Stack', value: 50000, stage: 'negotiation'),
        const Deal(id: '2', title: 'Security Audit', value: 30000, stage: 'lead'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(mobileDeals),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PipelineBarChart(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Negot.'), findsOneWidget);
      expect(find.text('Negotiation'), findsNothing);
      expect(find.text('Lead'), findsOneWidget);

      // Verify rotation angle is -45 degrees on mobile
      final sideTitleWidgets =
          tester.widgetList<SideTitleWidget>(find.byType(SideTitleWidget));
      expect(
        sideTitleWidgets.any(
            (w) => (w.angle - (-45 * (3.141592653589793 / 180))).abs() < 0.001),
        isTrue,
      );

      // Verify no exceptions / overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('PipelineBarChart renders empty state when no deals exist',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dealsControllerProvider.overrideWith(
              () => _MockDealsController([]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PipelineBarChart(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Deals in Pipeline'), findsOneWidget);
    });

    testWidgets('IndustryPieChart renders PieChart with legends',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: IndustryPieChart(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Company Distribution by Industry'), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Defense'), findsWidgets);
      expect(find.text('Technology'), findsWidgets);
    });

    testWidgets('TaskCompletionCard renders completion bar and status counts',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksControllerProvider.overrideWith(
              () => _MockTasksController(sampleTasks),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TaskCompletionCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task Completion & Productivity'), findsOneWidget);
      expect(find.text('50% Done'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('AnalyticsScreen renders all chart cards and KPI metrics',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(sampleDeals),
            ),
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
            tasksControllerProvider.overrideWith(
              () => _MockTasksController(sampleTasks),
            ),
          ],
          child: const MaterialApp(
            home: AnalyticsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Analytics & Reports'), findsOneWidget);
      expect(find.text('Total Pipeline'), findsOneWidget);
      expect(find.text('Active Accounts'), findsOneWidget);
      expect(find.text('Task Completion'), findsOneWidget);

      expect(find.byType(PipelineBarChart), findsOneWidget);
      expect(find.byType(IndustryPieChart), findsOneWidget);
      expect(find.byType(TaskCompletionCard), findsOneWidget);
    });

    testWidgets('Tapping Total Pipeline and Active Accounts KPI cards navigates to routes',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/analytics',
        routes: [
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/deals',
            builder: (context, state) =>
                const Scaffold(body: Text('Deals Board Destination')),
          ),
          GoRoute(
            path: '/companies',
            builder: (context, state) =>
                const Scaffold(body: Text('Companies Directory Destination')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dealsControllerProvider.overrideWith(
              () => _MockDealsController(sampleDeals),
            ),
            companiesControllerProvider.overrideWith(
              () => _MockCompaniesController(sampleCompanies),
            ),
            tasksControllerProvider.overrideWith(
              () => _MockTasksController(sampleTasks),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Total Pipeline"
      await tester.tap(find.text('Total Pipeline'));
      await tester.pumpAndSettle();
      expect(find.text('Deals Board Destination'), findsOneWidget);

      // Navigate back to /analytics
      router.go('/analytics');
      await tester.pumpAndSettle();

      // Tap "Active Accounts"
      await tester.tap(find.text('Active Accounts'));
      await tester.pumpAndSettle();
      expect(find.text('Companies Directory Destination'), findsOneWidget);
    });

    testWidgets('Tapping TaskCompletionCard status metrics deep-links to /tasks with query param',
        (tester) async {
      String? currentQueryStatus;
      final router = GoRouter(
        initialLocation: '/analytics',
        routes: [
          GoRoute(
            path: '/analytics',
            builder: (context, state) =>
                const Scaffold(body: TaskCompletionCard()),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) {
              currentQueryStatus = state.uri.queryParameters['status'];
              return Scaffold(body: Text('Tasks Screen: $currentQueryStatus'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksControllerProvider.overrideWith(
              () => _MockTasksController(sampleTasks),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Completed" status box
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(currentQueryStatus, 'completed');
      expect(find.text('Tasks Screen: completed'), findsOneWidget);

      // Navigate back to /analytics
      router.go('/analytics');
      await tester.pumpAndSettle();

      // Tap "In Progress" status box
      await tester.tap(find.text('In Progress'));
      await tester.pumpAndSettle();
      expect(currentQueryStatus, 'in_progress');
      expect(find.text('Tasks Screen: in_progress'), findsOneWidget);

      // Navigate back to /analytics
      router.go('/analytics');
      await tester.pumpAndSettle();

      // Tap "Pending" status box
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();
      expect(currentQueryStatus, 'pending');
      expect(find.text('Tasks Screen: pending'), findsOneWidget);
    });
  });
}
