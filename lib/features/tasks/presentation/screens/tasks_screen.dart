import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/tasks_controller.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();

  static const _filterOptions = [
    _FilterTab(key: 'all', label: 'All Tasks'),
    _FilterTab(key: 'pending', label: 'Pending'),
    _FilterTab(key: 'in_progress', label: 'In Progress'),
    _FilterTab(key: 'completed', label: 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null && widget.initialStatus!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(tasksControllerProvider.notifier)
            .filterByStatus(widget.initialStatus!);
      });
    }
  }

  @override
  void didUpdateWidget(TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus &&
        widget.initialStatus != null &&
        widget.initialStatus!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(tasksControllerProvider.notifier)
            .filterByStatus(widget.initialStatus!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasksAsync = ref.watch(filteredTasksProvider);
    final currentFilter = ref.watch(taskStatusFilterProvider);
    final searchQuery = ref.watch(taskSearchQueryProvider);
    final stats = ref.watch(taskStatsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Page Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                child: Row(
                  children: [
                    const Text(
                      'Tasks & Follow-ups',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh tasks',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        ref.read(tasksControllerProvider.notifier).refresh();
                      },
                    ),
                  ],
                ),
              ),

              // Top Metrics Strip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MetricItem(
                        label: 'Total Tasks',
                        value: '${stats.total}',
                        color: const Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'Pending',
                        value: '${stats.pending}',
                        color: const Color(0xFFD97706), // Amber
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'In Progress',
                        value: '${stats.inProgress}',
                        color: const Color(0xFF2563EB), // Blue
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'Completed',
                        value: '${stats.completed}',
                        color: const Color(0xFF059669), // Emerald
                      ),
                      if (stats.overdue > 0) ...[
                        const SizedBox(width: 20),
                        _MetricItem(
                          label: 'Overdue',
                          value: '${stats.overdue}',
                          color: const Color(0xFFDC2626), // Red
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref
                        .read(tasksControllerProvider.notifier)
                        .filterByQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tasks by title, contact, or status...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(tasksControllerProvider.notifier)
                                  .filterByQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),

              // Status Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: _filterOptions.map((opt) {
                    final isSelected =
                        currentFilter.toLowerCase() == opt.key.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(opt.label),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                        selectedColor: primaryColor,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (_) {
                          ref
                              .read(tasksControllerProvider.notifier)
                              .filterByStatus(opt.key);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Tasks Content List / States
              Expanded(
                child: filteredTasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      // Empty Search State
                      if (searchQuery.isNotEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No tasks found for "$searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(tasksControllerProvider.notifier)
                                        .filterByQuery('');
                                  },
                                  child: const Text('Clear Search'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Empty Filter State
                      if (currentFilter != 'all') {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_box_outline_blank_rounded,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No $currentFilter tasks found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    ref
                                        .read(tasksControllerProvider.notifier)
                                        .filterByStatus('all');
                                  },
                                  child: const Text('Show All Tasks'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Empty App State
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.checklist_rounded,
                                  size: 32,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Tasks Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Stay organized and track customer follow-ups by creating your first task.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => TaskFormSheet.show(context),
                                icon: const Icon(Icons.add_task_rounded,
                                    size: 18),
                                label: const Text('Add Task'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(tasksControllerProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(task: task);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 44, color: Colors.red.shade600),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load tasks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(tasksControllerProvider.notifier)
                                  .refresh();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskFormSheet.show(context),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Task'),
      ),
    );
  }
}

class _FilterTab {
  const _FilterTab({required this.key, required this.label});
  final String key;
  final String label;
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
