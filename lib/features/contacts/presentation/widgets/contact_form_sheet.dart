import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/contact.dart';
import '../controllers/contacts_controller.dart';
import 'status_badge.dart';

class ContactFormSheet extends ConsumerStatefulWidget {
  const ContactFormSheet({
    super.key,
    this.contact,
    this.preselectedCompanyId,
  });

  final Contact? contact;
  final String? preselectedCompanyId;

  static Future<void> show(
    BuildContext context, {
    Contact? contact,
    String? preselectedCompanyId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactFormSheet(
        contact: contact,
        preselectedCompanyId: preselectedCompanyId,
      ),
    );
  }

  @override
  ConsumerState<ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends ConsumerState<ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedCompanyId;
  String? _selectedAssignedTo;
  String _selectedStatus = 'new';
  bool _isSubmitting = false;

  final _statuses = ['new', 'contacted', 'qualified', 'lost'];

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _firstNameController.text = widget.contact!.firstName;
      _lastNameController.text = widget.contact!.lastName;
      _emailController.text = widget.contact!.email ?? '';
      _phoneController.text = widget.contact!.phone ?? '';
      _selectedCompanyId = widget.contact!.companyId;
      _selectedAssignedTo = widget.contact!.assignedTo;
      _selectedStatus = widget.contact!.status;
    } else {
      _selectedCompanyId = widget.preselectedCompanyId;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final isAdmin = ref.read(isAdminProvider);
    final isEditing = widget.contact != null;

    final String? assignedToValue;
    if (isAdmin) {
      assignedToValue = _selectedAssignedTo;
    } else if (isEditing) {
      assignedToValue = widget.contact!.assignedTo;
    } else {
      assignedToValue = null;
    }

    final bool success;
    if (isEditing) {
      success =
          await ref.read(contactsControllerProvider.notifier).updateContact(
                contactId: widget.contact!.id,
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                companyId: _selectedCompanyId,
                status: _selectedStatus,
                assignedTo: assignedToValue,
                notes: widget.contact?.notes,
              );
    } else {
      success =
          await ref.read(contactsControllerProvider.notifier).addContact(
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                companyId: _selectedCompanyId,
                status: _selectedStatus,
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
                    ? 'Contact "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}" updated successfully'
                    : 'Contact "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}" added successfully',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorState = ref.read(contactsControllerProvider);
      final message = errorState.hasError
          ? errorState.error.toString()
          : (isEditing
              ? 'Failed to update contact. Please try again.'
              : 'Failed to add contact. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);
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
                      widget.contact != null
                          ? 'Edit Contact'
                          : 'Add New Contact',
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

                // First & Last Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          hintText: 'Jane',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          hintText: 'Doe',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'jane.doe@example.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 (555) 000-0000',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Company Dropdown
                companiesAsync.when(
                  data: (companies) {
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedCompanyId,
                      decoration: const InputDecoration(
                        labelText: 'Company',
                        prefixIcon: Icon(Icons.business_outlined, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'None / Independent',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...companies.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
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
                      labelText: 'Company',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None / Independent'),
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

                // Status Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Contact Status',
                    prefixIcon: Icon(Icons.flag_outlined, size: 20),
                  ),
                  items: _statuses.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Row(
                        children: [
                          StatusBadge(status: s),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                    }
                  },
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
                          widget.contact != null
                              ? 'Save Changes'
                              : 'Save Contact',
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
