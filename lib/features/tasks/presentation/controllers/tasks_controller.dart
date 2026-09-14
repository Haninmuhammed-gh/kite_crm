import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/task_repository.dart';
import '../../domain/task.dart';

final tasksControllerProvider =
    NotifierProvider<TasksController, AsyncValue<List<Task>>>(
  TasksController.new,
);

class TaskSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final taskSearchQueryProvider =
    NotifierProvider<TaskSearchQueryNotifier, String>(
  TaskSearchQueryNotifier.new,
);

class TaskStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

final taskStatusFilterProvider =
    NotifierProvider<TaskStatusFilterNotifier, String>(
  TaskStatusFilterNotifier.new,
);

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasksAsync = ref.watch(tasksControllerProvider);
  final query = ref.watch(taskSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(taskStatusFilterProvider).toLowerCase();

  return tasksAsync.whenData((tasks) {
    return tasks.where((task) {
      final matchesFilter =
          filter == 'all' || task.status.toLowerCase() == filter;
      if (!matchesFilter) return false;

      if (query.isEmpty) return true;

      final title = task.title.toLowerCase();
      final description = (task.description ?? '').toLowerCase();
      final contactName = (task.displayContactName ?? '').toLowerCase();
      final status = task.status.toLowerCase();

      return title.contains(query) ||
          description.contains(query) ||
          contactName.contains(query) ||
          status.contains(query);
    }).toList();
  });
});

class TaskStats {
  const TaskStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.overdue,
  });

  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;
}

final taskStatsProvider = Provider<TaskStats>((ref) {
  final tasksAsync = ref.watch(tasksControllerProvider);
  return tasksAsync.maybeWhen(
    data: (tasks) {
      int pending = 0;
      int inProgress = 0;
      int completed = 0;
      int overdue = 0;

      for (final t in tasks) {
        if (t.isPending) pending++;
        if (t.isInProgress) inProgress++;
        if (t.isCompleted) completed++;
        if (t.isOverdue) overdue++;
      }

      return TaskStats(
        total: tasks.length,
        pending: pending,
        inProgress: inProgress,
        completed: completed,
        overdue: overdue,
      );
    },
    orElse: () => const TaskStats(
      total: 0,
      pending: 0,
      inProgress: 0,
      completed: 0,
      overdue: 0,
    ),
  );
});

final taskByIdProvider =
    FutureProvider.family<Task?, String>((ref, taskId) async {
  // Check memory cache first
  final cached = ref
      .watch(tasksControllerProvider)
      .value
      ?.where((t) => t.id == taskId)
      .firstOrNull;
  if (cached != null) return cached;

  // Fallback to direct fetch
  return await ref.read(taskRepositoryProvider).fetchTaskById(taskId);
});

class TasksController extends Notifier<AsyncValue<List<Task>>> {
  @override
  AsyncValue<List<Task>> build() {
    ref.watch(currentUserIdProvider);
    _fetchTasks();
    return const AsyncValue.loading();
  }

  Future<void> _fetchTasks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(taskRepositoryProvider).fetchTasks();
    });
  }

  Future<void> refresh() async {
    await _fetchTasks();
  }

  void filterByQuery(String query) {
    ref.read(taskSearchQueryProvider.notifier).setQuery(query);
  }

  void filterByStatus(String status) {
    ref.read(taskStatusFilterProvider.notifier).setFilter(status);
  }

  Future<bool> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String status = 'pending',
    required String contactId,
    String? assignedTo,
  }) async {
    try {
      await ref.read(taskRepositoryProvider).addTask(
            title: title,
            description: description,
            dueDate: dueDate,
            status: status,
            contactId: contactId,
            assignedTo: assignedTo,
          );

      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateTask({
    required String taskId,
    required String title,
    String? description,
    DateTime? dueDate,
    String status = 'pending',
    required String contactId,
    String? assignedTo,
  }) async {
    try {
      await ref.read(taskRepositoryProvider).updateTask(
            taskId: taskId,
            title: title,
            description: description,
            dueDate: dueDate,
            status: status,
            contactId: contactId,
            assignedTo: assignedTo,
          );

      ref.invalidateSelf();
      ref.invalidate(taskByIdProvider(taskId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> updateStatus({
    required String taskId,
    required String newStatus,
  }) async {
    final previousState = state;

    // Optimistically update
    state = state.whenData((list) {
      return list.map((task) {
        if (task.id == taskId) {
          return task.copyWith(status: newStatus);
        }
        return task;
      }).toList();
    });

    try {
      await ref.read(taskRepositoryProvider).updateTaskStatus(
            taskId: taskId,
            status: newStatus,
          );
      ref.invalidateSelf();
      ref.invalidate(taskByIdProvider(taskId));
    } catch (e, st) {
      state = previousState;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final previousState = state;

    // Optimistically remove
    state = state.whenData((list) {
      return list.where((t) => t.id != taskId).toList();
    });

    try {
      await ref.read(taskRepositoryProvider).deleteTask(taskId: taskId);
      ref.invalidateSelf();
      ref.invalidate(taskByIdProvider(taskId));
    } catch (e, st) {
      state = previousState;
      state = AsyncValue.error(e, st);
    }
  }
}
