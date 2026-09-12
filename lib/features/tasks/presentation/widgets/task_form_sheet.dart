import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../controllers/tasks_controller.dart';
import '../../domain/task.dart';
import 'task_status_chip.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({
    super.key,
    this.task,
    this.initialContactId,
    this.initialStatus = 'pending',
    this.initialAssignedTo,
  });

  final Task? task;
  final String? initialContactId;
  final String initialStatus;
  final String? initialAssignedTo;

  static Future<void> show(
    BuildContext context, {
    Task? task,
    String? initialContactId,
    String initialStatus = 'pending',
    String? initialAssignedTo,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormSheet(
        task: task,
        initialContactId: initialContactId,
        initialStatus: initialStatus,
        initialAssignedTo: initialAssignedTo,
      ),
    );
  }

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _selectedStatus;
  String? _selectedContactId;
  String? _selectedAssignedTo;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedStatus = widget.task!.status;
      _selectedContactId = widget.task!.contactId;
      _selectedAssignedTo = widget.task!.assignedTo;
      _dueDate = widget.task!.dueDate;
    } else {
      _selectedStatus = widget.initialStatus;
      _selectedContactId = widget.initialContactId;
      _selectedAssignedTo = widget.initialAssignedTo;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _dueDate != null
            ? TimeOfDay.fromDateTime(_dueDate!)
            : const TimeOfDay(hour: 17, minute: 0),
      );

      setState(() {
        if (pickedTime != null) {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        } else {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            17,
            0,
          );
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedContactId == null || _selectedContactId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an associated contact'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final isAdmin = ref.read(isAdminProvider);
    final isEditing = widget.task != null;

    final String? assignedToValue;
    if (isAdmin) {
      assignedToValue = _selectedAssignedTo;
    } else if (isEditing) {
      assignedToValue = widget.task!.assignedTo;
    } else {
      assignedToValue = null;
    }

    final bool success;
    if (isEditing) {
      success = await ref.read(tasksControllerProvider.notifier).updateTask(
            taskId: widget.task!.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            dueDate: _dueDate,
            status: _selectedStatus,
            contactId: _selectedContactId!,
            assignedTo: assignedToValue,
          );
    } else {
      success = await ref.read(tasksControllerProvider.notifier).addTask(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            dueDate: _dueDate,
            status: _selectedStatus,
            contactId: _selectedContactId!,
            assignedTo: assignedToValue,
          );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(isEditing
                  ? 'Task updated successfully'
                  : 'Task "${_titleController.text.trim()}" created'),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final tasksState = ref.read(tasksControllerProvider);
      final errorMsg = tasksState.hasError
          ? tasksState.error.toString()
          : (isEditing
              ? 'Failed to update task. Please try again.'
              : 'Failed to create task. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsControllerProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.task != null ? 'Edit Task' : 'Create New Task',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Task Title
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Task Title *',
                    hintText: 'e.g. Follow up on proposal contract',
                    prefixIcon: Icon(Icons.check_box_outlined, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add details, talking points, or action items...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Associated Contact Dropdown
                contactsAsync.when(
                  data: (contacts) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedContactId,
                      decoration: const InputDecoration(
                        labelText: 'Associated Contact *',
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select a contact';
                        }
                        return null;
                      },
                      items: contacts.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(
                            '${c.fullName}${c.companyName != null ? ' (${c.companyName})' : ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedContactId = val);
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, _) => const Text(
                    'Failed to load contacts for assignment',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 16),

                // Admin "Assign To" Dropdown
                if (ref.watch(isAdminProvider)) ...[
                  ref.watch(teamProfilesProvider).when(
                        data: (profiles) => DropdownButtonFormField<String?>(
                          initialValue: _selectedAssignedTo,
                          decoration: const InputDecoration(
                            labelText: 'Assign To (Team Member)',
                            prefixIcon:
                                Icon(Icons.assignment_ind_outlined, size: 20),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Assign to myself (Default)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            ...profiles.map(
                              (p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text('${p.displayName} (${p.role})'),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedAssignedTo = val);
                          },
                        ),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                  const SizedBox(height: 16),
                ],

                // Status & Due Date Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Initial Status',
                          prefixIcon:
                              Icon(Icons.flag_outlined, size: 20),
                        ),
                        items: TaskStatusChip.availableStatuses.map((s) {
                          return DropdownMenuItem<String>(
                            value: s,
                            child: Text(TaskStatusChip.formatStatus(s)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Due Date Picker
                    Expanded(
                      child: InkWell(
                        onTap: _pickDueDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 20),
                            suffixIcon: _dueDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 16),
                                    onPressed: () {
                                      setState(() => _dueDate = null);
                                    },
                                  )
                                : const Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _dueDate != null
                                ? DateFormat('MMM d, h:mm a').format(_dueDate!)
                                : 'Select date',
                            style: TextStyle(
                              color: _dueDate != null
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey.shade500,
                              fontSize: 13.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.task != null ? 'Save Changes' : 'Create Task',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
