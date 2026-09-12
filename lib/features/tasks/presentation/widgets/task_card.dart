import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/task.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/tasks_controller.dart';
import 'task_form_sheet.dart';
import 'task_status_chip.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
  });

  final Task task;

  String get _contactInitials {
    final name = task.displayContactName ?? '';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isAdmin = ref.watch(isAdminProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final canEdit = isAdmin || (task.assignedTo != null && task.assignedTo == currentUserId);
    final canDelete = isAdmin;
    final isCompleted = task.isCompleted;
    final isOverdue = task.isOverdue;
    final isDueToday = task.isDueToday;

    // Due date styling
    Color dueDateColor = const Color(0xFF64748B);
    Color dueDateBg = const Color(0xFFF1F5F9);
    IconData dueDateIcon = Icons.calendar_today_outlined;
    String dueDateText = '';

    if (task.dueDate != null) {
      if (isCompleted) {
        dueDateText = DateFormat('MMM d, yyyy').format(task.dueDate!);
      } else if (isOverdue) {
        dueDateColor = const Color(0xFFDC2626); // Red 600
        dueDateBg = const Color(0xFFFEF2F2); // Red 50
        dueDateIcon = Icons.error_outline_rounded;
        dueDateText = 'Overdue (${DateFormat('MMM d').format(task.dueDate!)})';
      } else if (isDueToday) {
        dueDateColor = const Color(0xFFD97706); // Amber 600
        dueDateBg = const Color(0xFFFFFBEB); // Amber 50
        dueDateIcon = Icons.access_time_rounded;
        dueDateText = 'Due Today';
      } else {
        dueDateText = DateFormat('MMM d, yyyy').format(task.dueDate!);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? Colors.grey.shade200
              : isOverdue
                  ? const Color(0xFFFCA5A5) // Light red border for overdue
                  : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/tasks/${task.id}', extra: task);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Checkbox, Title & Status Chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Toggle Checkbox
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 1.0),
                  child: InkWell(
                    onTap: () {
                      final newStatus = isCompleted ? 'pending' : 'completed';
                      ref
                          .read(tasksControllerProvider.notifier)
                          .updateStatus(taskId: task.id, newStatus: newStatus);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF059669)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF059669)
                              : Colors.grey.shade400,
                          width: 1.8,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),

                // Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.grey.shade500
                              : const Color(0xFF0F172A),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted
                                ? Colors.grey.shade400
                                : const Color(0xFF64748B),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Chip with interactive update popup
                TaskStatusChip(
                  status: task.status,
                  onStatusSelected: (newStatus) {
                    ref.read(tasksControllerProvider.notifier).updateStatus(
                          taskId: task.id,
                          newStatus: newStatus,
                        );
                  },
                ),

                // Actions Menu (Edit / Delete)
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    tooltip: 'More options',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (action) {
                      if (action == 'edit') {
                        TaskFormSheet.show(context, task: task);
                      } else if (action == 'delete') {
                        _showDeleteConfirmation(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      if (canEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF0F172A)),
                              SizedBox(width: 8),
                              Text(
                                'Edit Task',
                                style: TextStyle(color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red.shade600),
                              SizedBox(width: 8),
                              Text(
                                'Delete Task',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),

            // Bottom Meta Row: Linked Contact & Due Date
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Contact Tag
                if (task.displayContactName != null &&
                    task.displayContactName!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: primaryColor.withValues(alpha: 0.12),
                        child: Text(
                          _contactInitials,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.displayContactName!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Contact ID: ${task.contactId.length > 8 ? '${task.contactId.substring(0, 8)}...' : task.contactId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),

                // Due Date Badge
                if (task.dueDate != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dueDateBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: dueDateColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(dueDateIcon, size: 12, color: dueDateColor),
                        const SizedBox(width: 4),
                        Text(
                          dueDateText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: dueDateColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'No due date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () {
              ref.read(tasksControllerProvider.notifier).deleteTask(task.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
