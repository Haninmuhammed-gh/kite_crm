import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../domain/task.dart';
import '../controllers/tasks_controller.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_status_chip.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  const TaskDetailsScreen({
    super.key,
    required this.taskId,
    this.initialTask,
  });

  final String taskId;
  final Task? initialTask;

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Reactive task lookup from controller
    final tasksAsync = ref.watch(tasksControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final liveTask = tasksAsync.value
        ?.where((t) => t.id == widget.taskId)
        .firstOrNull;
    final task = liveTask ?? widget.initialTask;

    if (task == null) {
      final fetchedTaskAsync = ref.watch(taskByIdProvider(widget.taskId));
      return fetchedTaskAsync.when(
        data: (loadedTask) {
          if (loadedTask == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: const Text('Task Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _handleBack(context),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Task Not Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _handleBack(context),
                      child: const Text('Return to Tasks'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _buildScaffold(
            context,
            loadedTask,
            primaryColor,
            isAdmin,
            currentUserId,
          );
        },
        loading: () => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Task Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => _handleBack(context),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Task Details'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => _handleBack(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 12),
                Text('Failed to load task: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(taskByIdProvider(widget.taskId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildScaffold(context, task, primaryColor, isAdmin, currentUserId);
  }

  Widget _buildScaffold(
    BuildContext context,
    Task task,
    Color primaryColor,
    bool isAdmin,
    String? currentUserId,
  ) {
    final canEdit = isAdmin ||
        (task.assignedTo != null && task.assignedTo == currentUserId);

    // Resolve associated contact (either attached on task or fetched via provider)
    Contact? contact = task.contact;
    if (contact == null && task.contactId.isNotEmpty) {
      final contactAsync = ref.watch(contactDetailProvider(task.contactId));
      contact = contactAsync.value;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _handleBack(context),
        ),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Edit Task',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => TaskFormSheet.show(context, task: task),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(tasksControllerProvider.notifier).refresh();
              if (task.contactId.isNotEmpty) {
                ref.invalidate(contactDetailProvider(task.contactId));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(tasksControllerProvider.notifier).refresh();
              if (task.contactId.isNotEmpty) {
                ref.invalidate(contactDetailProvider(task.contactId));
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                // Header Card: Title, Status Chip, Due Date
                _TaskHeaderCard(
                  task: task,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),

                // Description Card
                _TaskDescriptionCard(
                  description: task.description,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 20),

                // Associated Contact Section Header
                Row(
                  children: [
                    Icon(
                      Icons.person_pin_rounded,
                      size: 20,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Associated Contact',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Associated Contact Card
                _AssociatedContactCard(
                  contact: contact,
                  contactId: task.contactId,
                  fallbackContactName: task.displayContactName,
                  fallbackContactEmail: task.displayContactEmail,
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskHeaderCard extends ConsumerWidget {
  const _TaskHeaderCard({
    required this.task,
    required this.primaryColor,
  });

  final Task task;
  final Color primaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.isCompleted;
    final isOverdue = task.isOverdue;
    final isDueToday = task.isDueToday;

    // Due date styling
    Color dueDateColor = const Color(0xFF475569);
    Color dueDateBg = const Color(0xFFF1F5F9);
    IconData dueDateIcon = Icons.calendar_today_outlined;
    String dueDateText = '';

    if (task.dueDate != null) {
      if (isCompleted) {
        dueDateText = DateFormat('EEE, MMM d, yyyy').format(task.dueDate!);
        dueDateColor = const Color(0xFF64748B);
      } else if (isOverdue) {
        dueDateColor = const Color(0xFFDC2626); // Red 600
        dueDateBg = const Color(0xFFFEF2F2); // Red 50
        dueDateIcon = Icons.error_outline_rounded;
        dueDateText =
            'Overdue (${DateFormat('MMM d, yyyy').format(task.dueDate!)})';
      } else if (isDueToday) {
        dueDateColor = const Color(0xFFD97706); // Amber 600
        dueDateBg = const Color(0xFFFFFBEB); // Amber 50
        dueDateIcon = Icons.access_time_rounded;
        dueDateText = 'Due Today (${DateFormat('MMM d').format(task.dueDate!)})';
      } else {
        dueDateColor = primaryColor;
        dueDateBg = primaryColor.withValues(alpha: 0.08);
        dueDateText = DateFormat('EEE, MMM d, yyyy').format(task.dueDate!);
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? Colors.grey.shade200
              : isOverdue
                  ? const Color(0xFFFCA5A5)
                  : Colors.grey.shade200,
          width: isOverdue ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Checkbox + Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Toggle Checkbox
                Padding(
                  padding: const EdgeInsets.only(right: 14.0, top: 2.0),
                  child: InkWell(
                    onTap: () {
                      final newStatus = isCompleted ? 'pending' : 'completed';
                      ref
                          .read(tasksControllerProvider.notifier)
                          .updateStatus(taskId: task.id, newStatus: newStatus);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF059669)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF059669)
                              : Colors.grey.shade400,
                          width: 2.0,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),

                // Title
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? Colors.grey.shade500
                          : const Color(0xFF0F172A),
                      height: 1.25,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Metadata Badges: Status Chip + Due Date
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Interactive Status Badge
                TaskStatusChip(
                  status: task.status,
                  onStatusSelected: (newStatus) {
                    ref
                        .read(tasksControllerProvider.notifier)
                        .updateStatus(taskId: task.id, newStatus: newStatus);
                  },
                ),

                // Due Date Badge
                if (task.dueDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: dueDateBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dueDateColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(dueDateIcon, size: 14, color: dueDateColor),
                        const SizedBox(width: 6),
                        Text(
                          dueDateText,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: dueDateColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'No due date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Created date if available
                if (task.createdAt != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Created ${DateFormat('MMM d, yyyy').format(task.createdAt!)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDescriptionCard extends StatelessWidget {
  const _TaskDescriptionCard({
    required this.description,
    required this.primaryColor,
  });

  final String? description;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        description != null && description!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 20,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasDescription)
              SelectableText(
                description!,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              )
            else
              Text(
                'No description provided for this task.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssociatedContactCard extends StatelessWidget {
  const _AssociatedContactCard({
    required this.contact,
    required this.contactId,
    required this.fallbackContactName,
    required this.fallbackContactEmail,
    required this.primaryColor,
  });

  final Contact? contact;
  final String contactId;
  final String? fallbackContactName;
  final String? fallbackContactEmail;
  final Color primaryColor;

  String get _initials {
    final name = contact?.fullName ?? fallbackContactName ?? '';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = contact?.fullName ?? fallbackContactName;
    final displayCompany = contact?.companyName;
    final displayEmail = contact?.email ?? fallbackContactEmail;
    final displayPhone = contact?.phone;

    if (contactId.isEmpty && displayName == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.person_off_outlined,
                size: 24, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Text(
              'No contact associated with this task.',
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (contactId.isNotEmpty) {
            context.push('/contacts/$contactId', extra: contact);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.04),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Initials Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.18),
                      primaryColor.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Contact Name & Company
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? 'Unnamed Contact',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    if (displayCompany != null &&
                        displayCompany.trim().isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayCompany,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Independent Contact',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    // Phone / Email chips if available
                    if (displayEmail != null || displayPhone != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (displayEmail != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mail_outline_rounded,
                                    size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  displayEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          if (displayPhone != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_outlined,
                                    size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  displayPhone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Forward arrow / View profile indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
