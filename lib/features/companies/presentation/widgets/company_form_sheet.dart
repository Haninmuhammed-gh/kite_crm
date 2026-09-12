import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/company.dart';
import '../controllers/companies_controller.dart';

class CompanyFormSheet extends ConsumerStatefulWidget {
  const CompanyFormSheet({
    super.key,
    this.company,
  });

  final Company? company;

  static Future<void> show(BuildContext context, {Company? company}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanyFormSheet(company: company),
    );
  }

  @override
  ConsumerState<CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends ConsumerState<CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedAssignedTo;
  bool _isSubmitting = false;

  static const _popularIndustries = [
    'Technology',
    'Financial Services',
    'Healthcare & Life Sciences',
    'Manufacturing',
    'Retail & E-commerce',
    'Consulting & Professional',
    'Education',
    'Real Estate',
    'Media & Entertainment',
    'Energy & Utilities',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.company != null) {
      _nameController.text = widget.company!.name;
      _industryController.text = widget.company!.industry ?? '';
      _websiteController.text = widget.company!.website ?? '';
      _phoneController.text = widget.company!.phone ?? '';
      _selectedAssignedTo = widget.company!.assignedTo;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final isAdmin = ref.read(isAdminProvider);
    final isEditing = widget.company != null;

    final String? assignedToValue;
    if (isAdmin) {
      assignedToValue = _selectedAssignedTo;
    } else if (isEditing) {
      assignedToValue = widget.company!.assignedTo;
    } else {
      assignedToValue = null;
    }

    final bool success;
    if (isEditing) {
      success = await ref.read(companiesControllerProvider.notifier).updateCompany(
            companyId: widget.company!.id,
            name: _nameController.text.trim(),
            industry: _industryController.text.trim(),
            website: _websiteController.text.trim(),
            phone: _phoneController.text.trim(),
            assignedTo: assignedToValue,
          );
    } else {
      success = await ref.read(companiesControllerProvider.notifier).addCompany(
            name: _nameController.text.trim(),
            industry: _industryController.text.trim(),
            website: _websiteController.text.trim(),
            phone: _phoneController.text.trim(),
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
                    ? 'Company "${_nameController.text.trim()}" updated successfully'
                    : 'Company "${_nameController.text.trim()}" created successfully',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final state = ref.read(companiesControllerProvider);
      final message = state.hasError
          ? state.error.toString()
          : (isEditing
              ? 'Failed to update company. Please try again.'
              : 'Failed to create company. Please try again.');
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
                      widget.company != null
                          ? 'Edit Company'
                          : 'Add New Company',
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

                // Company Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    hintText: 'Acme Corporation',
                    prefixIcon: Icon(Icons.business_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Industry Autocomplete / Input
                Autocomplete<String>(
                  initialValue:
                      TextEditingValue(text: _industryController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _popularIndustries;
                    }
                    return _popularIndustries.where((industry) {
                      return industry
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _industryController.text = selection;
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Sync controller if prefilled
                    if (_industryController.text.isNotEmpty &&
                        fieldTextEditingController.text.isEmpty) {
                      fieldTextEditingController.text =
                          _industryController.text;
                    }
                    fieldTextEditingController.addListener(() {
                      _industryController.text =
                          fieldTextEditingController.text;
                    });

                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Industry',
                        hintText: 'e.g. Technology, Healthcare',
                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Website URL
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Website URL',
                    hintText: 'https://example.com',
                    prefixIcon: Icon(Icons.language_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: ref.watch(isAdminProvider)
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 (555) 000-0000',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
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
                const SizedBox(height: 8),

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
                          widget.company != null
                              ? 'Save Changes'
                              : 'Save Company',
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
