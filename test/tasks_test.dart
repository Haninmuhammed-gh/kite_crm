import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kite_crm/features/auth/presentation/controllers/auth_controller.dart';
import 'package:kite_crm/features/contacts/domain/company.dart';
import 'package:kite_crm/features/contacts/domain/contact.dart';
import 'package:kite_crm/features/tasks/domain/task.dart';
import 'package:kite_crm/features/tasks/presentation/controllers/tasks_controller.dart';
import 'package:kite_crm/features/tasks/presentation/screens/task_details_screen.dart';
import 'package:kite_crm/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:kite_crm/features/tasks/presentation/widgets/task_card.dart';
import 'package:kite_crm/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:kite_crm/features/tasks/presentation/widgets/task_status_chip.dart';

void main() {
  group('Task domain model tests', () {
    test('Task serialization and join parsing with contact and company', () {
      final json = {
        'id': 'task-1',
        'title': 'Prepare Q3 Proposal',
        'description': 'Gather cost estimates and timeline details.',
        'due_date': '2026-09-30T10:00:00.000Z',
        'status': 'in_progress',
        'contact_id': 'cont-1',
        'contacts': {
          'id': 'cont-1',
          'first_name': 'Pepper',
          'last_name': 'Potts',
          'email': 'pepper@stark.com',
          'companies': {
            'id': 'comp-1',
            'name': 'Stark Enterprises',
          },
        },
      };

      final task = Task.fromJson(json);
      expect(task.id, 'task-1');
      expect(task.title, 'Prepare Q3 Proposal');
      expect(task.description, 'Gather cost estimates and timeline details.');
      expect(task.status, 'in_progress');
      expect(task.isInProgress, isTrue);
      expect(task.isCompleted, isFalse);
      expect(task.contactId, 'cont-1');
      expect(task.contactName, 'Pepper Potts');
      expect(task.contactEmail, 'pepper@stark.com');
      expect(task.companyName, 'Stark Enterprises');
      expect(task.contact, isNotNull);
      expect(task.contact!.fullName, 'Pepper Potts');

      final insertJson = task.toInsertJson();
      expect(insertJson['title'], 'Prepare Q3 Proposal');
      expect(insertJson['status'], 'in_progress');
      expect(insertJson['contact_id'], 'cont-1');
      expect(insertJson.containsKey('contacts'), isFalse);
    });

    test('Task isOverdue and isDueToday calculations', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final overdueTask = Task(
        id: 't-overdue',
        title: 'Overdue task',
        dueDate: yesterday,
        contactId: 'c-1',
        status: 'pending',
      );
      expect(overdueTask.isOverdue, isTrue);

      final completedTask = overdueTask.copyWith(status: 'completed');
      expect(completedTask.isOverdue, isFalse);

      final today = DateTime.now();
      final todayTask = Task(
        id: 't-today',
        title: 'Today task',
        dueDate: today,
        contactId: 'c-1',
        status: 'pending',
      );
      expect(todayTask.isDueToday, isTrue);
    });
  });

  group('TaskCard widget tests', () {
    final sampleContact = const Contact(
      id: 'c-1',
      firstName: 'Diana',
      lastName: 'Prince',
      email: 'diana@themyscira.gov',
      company: Company(id: 'comp-1', name: 'Justice League'),
    );

    final sampleTask = Task(
      id: 'task-card-1',
      title: 'Review Defense Architecture',
      description: 'Check security shields and firewall blueprints.',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: 'pending',
      contactId: 'c-1',
      contact: sampleContact,
    );

    testWidgets(
        'Renders TaskCard with InkWell, checkbox, title, and contact name',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            tasksControllerProvider.overrideWith(
              () => _MockTasksController([sampleTask]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TaskCard(task: sampleTask),
            ),
          ),
        ),
      );

      expect(find.text('Review Defense Architecture'), findsOneWidget);
      expect(find.text('Check security shields and firewall blueprints.'),
          findsOneWidget);
      expect(find.text('Diana Prince'), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('Tapping leading checkbox updates status independently',
        (tester) async {
      final mockController = _MockTasksController([sampleTask]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            tasksControllerProvider.overrideWith(() => mockController),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TaskCard(task: sampleTask),
            ),
          ),
        ),
      );

      // Find the checkbox container by finding the first InkWell in the card
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);

      // Tap the checkbox (inside the leading Row)
      await tester.tap(inkWells.at(1));
      await tester.pumpAndSettle();

      expect(mockController.lastUpdatedStatusTaskId, 'task-card-1');
      expect(mockController.lastUpdatedStatus, 'completed');
    });
  });

  group('TaskDetailsScreen widget tests', () {
    final testContact = const Contact(
      id: 'cont-wayne-1',
      firstName: 'Bruce',
      lastName: 'Wayne',
      email: 'bruce@wayne.com',
      phone: '+1 555-0199',
      status: 'qualified',
      company: Company(id: 'comp-w', name: 'Wayne Enterprises'),
    );

    final overdueDate = DateTime.now().subtract(const Duration(days: 2));

    final testTask = Task(
      id: 'task-detail-1',
      title: 'Finalize Batmobile Specifications',
      description:
          'Review carbon-fiber chassis integrity and jet turbine thrust.',
      dueDate: overdueDate,
      status: 'in_progress',
      contactId: 'cont-wayne-1',
      contact: testContact,
      createdAt: DateTime(2026, 9, 1),
    );

    testWidgets(
        'Renders header details, overdue badge, description, and associated contact card',
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
            isAdminProvider.overrideWith((ref) => true),
            tasksControllerProvider.overrideWith(
              () => _MockTasksController([testTask]),
            ),
          ],
          child: MaterialApp(
            home: TaskDetailsScreen(
              taskId: 'task-detail-1',
              initialTask: testTask,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Finalize Batmobile Specifications'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.textContaining('Overdue'), findsOneWidget);

      // Verify Description
      expect(find.text('Description'), findsOneWidget);
      expect(
        find.text(
            'Review carbon-fiber chassis integrity and jet turbine thrust.'),
        findsOneWidget,
      );

      // Verify Associated Contact Section
      expect(find.text('Associated Contact'), findsOneWidget);
      expect(find.text('Bruce Wayne'), findsOneWidget);
      expect(find.text('Wayne Enterprises'), findsOneWidget);
      expect(find.text('+1 555-0199'), findsOneWidget);
      expect(find.text('bruce@wayne.com'), findsOneWidget);
      expect(find.text('BW'), findsOneWidget); // Initials
    });

    testWidgets('Interactive status chip updates task status',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockController = _MockTasksController([testTask]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            tasksControllerProvider.overrideWith(() => mockController),
          ],
          child: MaterialApp(
            home: TaskDetailsScreen(
              taskId: 'task-detail-1',
              initialTask: testTask,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open status popup menu
      final statusChip = find.byType(TaskStatusChip);
      expect(statusChip, findsOneWidget);
      await tester.tap(statusChip);
      await tester.pumpAndSettle();

      // Select 'Completed'
      final completedItem = find.text('Completed');
      expect(completedItem, findsOneWidget);
      await tester.tap(completedItem);
      await tester.pumpAndSettle();

      expect(mockController.lastUpdatedStatusTaskId, 'task-detail-1');
      expect(mockController.lastUpdatedStatus, 'completed');
    });

    testWidgets('Edit button in AppBar opens TaskFormSheet', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isAdminProvider.overrideWith((ref) => true),
            tasksControllerProvider.overrideWith(
              () => _MockTasksController([testTask]),
            ),
          ],
          child: MaterialApp(
            home: TaskDetailsScreen(
              taskId: 'task-detail-1',
              initialTask: testTask,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editButton = find.byTooltip('Edit Task');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Check that TaskFormSheet modal sheet is displayed
      expect(find.byType(TaskFormSheet), findsOneWidget);
      expect(find.text('Edit Task'), findsOneWidget);
    });
  });

  group('TasksScreen widget tests', () {
    final sampleTasks = [
      Task(
        id: 't-comp',
        title: 'Completed Action Item',
        status: 'completed',
        contactId: 'c-1',
      ),
      Task(
        id: 't-pend',
        title: 'Pending Action Item',
        status: 'pending',
        contactId: 'c-2',
      ),
      Task(
        id: 't-prog',
        title: 'In Progress Action Item',
        status: 'in_progress',
        contactId: 'c-3',
      ),
    ];

    testWidgets('TasksScreen with initialStatus selects matching filter chip and filters list',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksControllerProvider.overrideWith(
              () => _MockTasksController(sampleTasks),
            ),
          ],
          child: const MaterialApp(
            home: TasksScreen(initialStatus: 'completed'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Completed FilterChip is selected
      final completedChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Completed'),
      );
      expect(completedChip.selected, isTrue);

      final allTasksChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'All Tasks'),
      );
      expect(allTasksChip.selected, isFalse);

      // Verify only completed task is visible
      expect(find.text('Completed Action Item'), findsOneWidget);
      expect(find.text('Pending Action Item'), findsNothing);
      expect(find.text('In Progress Action Item'), findsNothing);
    });

    testWidgets('TasksScreen updates filter when initialStatus changes',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksControllerProvider.overrideWith(
              () => _MockTasksController(sampleTasks),
            ),
          ],
          child: const MaterialApp(
            home: TasksScreen(initialStatus: 'pending'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pendingChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Pending'),
      );
      expect(pendingChip.selected, isTrue);
      expect(find.text('Pending Action Item'), findsOneWidget);
      expect(find.text('Completed Action Item'), findsNothing);

      // Re-pump with updated initialStatus
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tasksControllerProvider.overrideWith(
              () => _MockTasksController(sampleTasks),
            ),
          ],
          child: const MaterialApp(
            home: TasksScreen(initialStatus: 'in_progress'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inProgressChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'In Progress'),
      );
      expect(inProgressChip.selected, isTrue);
      expect(find.text('In Progress Action Item'), findsOneWidget);
      expect(find.text('Pending Action Item'), findsNothing);
    });
  });
}

class _MockTasksController extends TasksController {
  _MockTasksController(this._initial);

  final List<Task> _initial;
  String? lastUpdatedStatusTaskId;
  String? lastUpdatedStatus;

  @override
  AsyncValue<List<Task>> build() {
    return AsyncValue.data(_initial);
  }

  @override
  Future<void> updateStatus({
    required String taskId,
    required String newStatus,
  }) async {
    lastUpdatedStatusTaskId = taskId;
    lastUpdatedStatus = newStatus;
    state = state.whenData((list) => list.map((t) {
          if (t.id == taskId) {
            return t.copyWith(status: newStatus);
          }
          return t;
        }).toList());
  }
}
