import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../companies/presentation/controllers/companies_controller.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../controllers/deals_controller.dart';
import '../../domain/deal.dart';
import 'deal_card.dart';

class DealFormSheet extends ConsumerStatefulWidget {
  const DealFormSheet({
    super.key,
    this.deal,
    this.initialStage = 'lead',
    this.preselectedCompanyId,
    this.preselectedContactId,
  });

  final Deal? deal;
  final String initialStage;
  final String? preselectedCompanyId;
  final String? preselectedContactId;

  static Future<void> show(
    BuildContext context, {
    Deal? deal,
    String initialStage = 'lead',
    String? preselectedCompanyId,
    String? preselectedContactId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DealFormSheet(
        deal: deal,
        initialStage: initialStage,
        preselectedCompanyId: preselectedCompanyId,
        preselectedContactId: preselectedContactId,
      ),
    );
  }

  @override
  ConsumerState<DealFormSheet> createState() => _DealFormSheetState();
}

class _DealFormSheetState extends ConsumerState<DealFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();

  late String _selectedStage;
  String? _selectedContactId;
  String? _selectedCompanyId;
  String? _selectedAssignedTo;
  DateTime? _expectedCloseDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.deal != null) {
      _titleController.text = widget.deal!.title;
      _valueController.text = widget.deal!.value.toStringAsFixed(0);
      _selectedStage = widget.deal!.stage;
      _selectedContactId = widget.deal!.contactId;
      _selectedCompanyId = widget.deal!.companyId;
      _selectedAssignedTo = widget.deal!.assignedTo;
      _expectedCloseDate = widget.deal!.expectedCloseDate;
    } else {
      _selectedStage = widget.initialStage;
      _selectedCompanyId = widget.preselectedCompanyId;
      _selectedContactId = widget.preselectedContactId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickCloseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedCloseDate ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() => _expectedCloseDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedValue = double.tryParse(_valueController.text.trim()) ?? 0.0;

    setState(() => _isSubmitting = true);

    final isAdmin = ref.read(isAdminProvider);
    final isEditing = widget.deal != null;

    final String? assignedToValue;
    if (isAdmin) {
      assignedToValue = _selectedAssignedTo;
    } else if (isEditing) {
      assignedToValue = widget.deal!.assignedTo;
    } else {
      assignedToValue = null;
    }

    final bool success;
    if (isEditing) {
      success = await ref.read(dealsControllerProvider.notifier).updateDeal(
            dealId: widget.deal!.id,
            title: _titleController.text.trim(),
            value: parsedValue,
            contactId: _selectedContactId,
            companyId: _selectedCompanyId,
            stage: _selectedStage,
            expectedCloseDate: _expectedCloseDate,
            assignedTo: assignedToValue,
          );
    } else {
      success = await ref.read(dealsControllerProvider.notifier).addDeal(
            title: _titleController.text.trim(),
            value: parsedValue,
            contactId: _selectedContactId,
            companyId: _selectedCompanyId,
            stage: _selectedStage,
            expectedCloseDate: _expectedCloseDate,
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
              Text(
                isEditing
                    ? 'Deal updated successfully'
                    : 'Deal "${_titleController.text.trim()}" added to pipeline',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final dealsState = ref.read(dealsControllerProvider);
      final errorMsg = dealsState.hasError
          ? dealsState.error.toString()
          : (isEditing
              ? 'Failed to update deal. Please try again.'
              : 'Failed to create deal. Please try again.');
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
    final companiesAsync = ref.watch(companiesControllerProvider);
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
                      widget.deal != null ? 'Edit Deal' : 'Create New Deal',
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

                // Title Field
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Deal Title *',
                    hintText: 'e.g. Enterprise License - 50 Seats',
                    prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a deal title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Value Field ($)
                TextFormField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Deal Value (\$) *',
                    hintText: 'e.g. 25000',
                    prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a deal value';
                    }
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Associated Contact Dropdown
                contactsAsync.when(
                  data: (contacts) {
                    final validContactId =
                        contacts.any((c) => c.id == _selectedContactId)
                            ? _selectedContactId
                            : null;
                    return DropdownButtonFormField<String?>(
                      initialValue: validContactId,
                      decoration: const InputDecoration(
                        labelText: 'Associated Contact',
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'No contact linked',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...contacts.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(
                              '${c.fullName}${c.companyName != null ? ' (${c.companyName})' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedContactId = val;
                          if (val != null && _selectedCompanyId == null) {
                            final matchedContact =
                                contacts.where((c) => c.id == val).firstOrNull;
                            if (matchedContact?.companyId != null) {
                              _selectedCompanyId = matchedContact!.companyId;
                            }
                          }
                        });
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, _) => DropdownButtonFormField<String?>(
                    initialValue: null,
                    decoration: const InputDecoration(
                      labelText: 'Associated Contact',
                      prefixIcon:
                          Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No contact linked'),
                      ),
                    ],
                    onChanged: null,
                  ),
                ),
                const SizedBox(height: 16),

                // Associated Company Dropdown
                companiesAsync.when(
                  data: (companies) {
                    final validCompanyId =
                        companies.any((c) => c.id == _selectedCompanyId)
                            ? _selectedCompanyId
                            : null;
                    return DropdownButtonFormField<String?>(
                      initialValue: validCompanyId,
                      decoration: const InputDecoration(
                        labelText: 'Associated Company',
                        prefixIcon:
                            Icon(Icons.business_rounded, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'No company linked',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...companies.map(
                          (comp) => DropdownMenuItem<String?>(
                            value: comp.id,
                            child: Text(
                              comp.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCompanyId = val);
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, _) => DropdownButtonFormField<String?>(
                    initialValue: null,
                    decoration: const InputDecoration(
                      labelText: 'Associated Company',
                      prefixIcon:
                          Icon(Icons.business_rounded, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No company linked'),
                      ),
                    ],
                    onChanged: null,
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

                // Stage Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStage,
                  decoration: const InputDecoration(
                    labelText: 'Pipeline Stage',
                    prefixIcon:
                        Icon(Icons.view_kanban_outlined, size: 20),
                  ),
                  items: DealCard.stages.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(DealCard.stageLabel(s)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStage = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Expected Close Date Picker
                InkWell(
                  onTap: _pickCloseDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expected Close Date',
                      prefixIcon:
                          Icon(Icons.calendar_today_outlined, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _expectedCloseDate != null
                          ? DateFormat('MMMM d, yyyy')
                              .format(_expectedCloseDate!)
                          : 'Select target close date (optional)',
                      style: TextStyle(
                        color: _expectedCloseDate != null
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
                          widget.deal != null ? 'Save Changes' : 'Save Deal',
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
