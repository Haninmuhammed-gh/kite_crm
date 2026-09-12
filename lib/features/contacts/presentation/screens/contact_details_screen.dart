import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../deals/presentation/controllers/deals_controller.dart';
import '../../../deals/presentation/widgets/deal_card.dart';
import '../../../deals/presentation/widgets/deal_form_sheet.dart';
import '../../domain/contact.dart';
import '../controllers/contacts_controller.dart';
import '../widgets/contact_form_sheet.dart';
import '../widgets/status_badge.dart';

class ContactDetailsScreen extends ConsumerStatefulWidget {
  const ContactDetailsScreen({
    super.key,
    required this.contactId,
    this.initialContact,
  });

  final String contactId;
  final Contact? initialContact;

  @override
  ConsumerState<ContactDetailsScreen> createState() =>
      _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends ConsumerState<ContactDetailsScreen> {
  late final TextEditingController _notesController;
  bool _isSavingNotes = false;
  String? _lastLoadedContactId;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.initialContact?.notes ?? '',
    );
    _lastLoadedContactId = widget.initialContact?.id;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _syncNotesIfChanged(Contact contact) {
    if (_lastLoadedContactId != contact.id) {
      _lastLoadedContactId = contact.id;
      _notesController.text = contact.notes ?? '';
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/contacts');
    }
  }

  Future<void> _launchAction(
    BuildContext context,
    Uri uri,
    String actionName,
  ) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to platform default
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $actionName: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveNotes(Contact contact) async {
    setState(() => _isSavingNotes = true);

    final notesText = _notesController.text.trim();
    final success =
        await ref.read(contactsControllerProvider.notifier).updateContact(
              contactId: contact.id,
              firstName: contact.firstName,
              lastName: contact.lastName,
              email: contact.email,
              phone: contact.phone,
              companyId: contact.companyId,
              status: contact.status,
              assignedTo: contact.assignedTo,
              notes: notesText.isEmpty ? null : notesText,
            );

    if (!mounted) return;
    setState(() => _isSavingNotes = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Notes updated successfully'),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorState = ref.read(contactsControllerProvider);
      final message = errorState.hasError
          ? errorState.error.toString()
          : 'Failed to update notes. Please try again.';
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

    // Check reactive controller list for live contact updates
    final contactsAsync = ref.watch(contactsControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final liveContact = contactsAsync.value
        ?.where((c) => c.id == widget.contactId)
        .firstOrNull;
    final contact = liveContact ?? widget.initialContact;

    if (contact == null) {
      final fetchedContactAsync =
          ref.watch(contactDetailProvider(widget.contactId));
      return fetchedContactAsync.when(
        data: (loadedContact) {
          if (loadedContact == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: const Text('Contact Details'),
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
                      Icons.person_off_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Contact Not Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _handleBack(context),
                      child: const Text('Return to Directory'),
                    ),
                  ],
                ),
              ),
            );
          }
          _syncNotesIfChanged(loadedContact);
          return _buildScaffold(
            context,
            loadedContact,
            primaryColor,
            isAdmin,
            currentUserId,
          );
        },
        loading: () => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Contact Details'),
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
            title: const Text('Contact Details'),
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
                Text('Failed to load contact: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(contactDetailProvider(widget.contactId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _syncNotesIfChanged(contact);
    return _buildScaffold(
      context,
      contact,
      primaryColor,
      isAdmin,
      currentUserId,
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    Contact contact,
    Color primaryColor,
    bool isAdmin,
    String? currentUserId,
  ) {
    final canEdit = isAdmin ||
        (contact.assignedTo != null && contact.assignedTo == currentUserId);
    final dealsAsync = ref.watch(dealsByContactProvider(widget.contactId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          contact.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _handleBack(context),
        ),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Edit Contact',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => ContactFormSheet.show(context, contact: contact),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(contactsControllerProvider.notifier).refresh();
              ref.read(dealsControllerProvider.notifier).refresh();
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
              await ref.read(contactsControllerProvider.notifier).refresh();
              await ref.read(dealsControllerProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                // Header Card: Contact Details
                _ContactHeaderCard(
                  contact: contact,
                  primaryColor: primaryColor,
                  canEdit: canEdit,
                ),
                const SizedBox(height: 16),

                // Quick Actions Row
                _QuickActionsCard(
                  contact: contact,
                  primaryColor: primaryColor,
                  onLaunch: (uri, label) =>
                      _launchAction(context, uri, label),
                ),
                const SizedBox(height: 16),

                // Notes Section
                _NotesCard(
                  contact: contact,
                  primaryColor: primaryColor,
                  notesController: _notesController,
                  isSaving: _isSavingNotes,
                  onSaveNotes: () => _saveNotes(contact),
                ),
                const SizedBox(height: 24),

                // Associated Deals Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Associated Deals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        dealsAsync.maybeWhen(
                          data: (deals) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${deals.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        DealFormSheet.show(
                          context,
                          preselectedContactId: contact.id,
                          preselectedCompanyId: contact.companyId,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: const Text(
                        'Add Deal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Deals List
                dealsAsync.when(
                  data: (deals) {
                    if (deals.isEmpty) {
                      return _EmptyDealsState(
                        contactName: contact.fullName,
                        primaryColor: primaryColor,
                        onAddDeal: () {
                          DealFormSheet.show(
                            context,
                            preselectedContactId: contact.id,
                            preselectedCompanyId: contact.companyId,
                          );
                        },
                      );
                    }

                    return Column(
                      children: deals.map((deal) {
                        return DealCard(deal: deal);
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 36,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load deals',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(dealsControllerProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Try Again'),
                        ),
                      ],
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

class _ContactHeaderCard extends ConsumerWidget {
  const _ContactHeaderCard({
    required this.contact,
    required this.primaryColor,
    required this.canEdit,
  });

  final Contact contact;
  final Color primaryColor;
  final bool canEdit;

  static const _availableStatuses = ['new', 'contacted', 'qualified', 'lost'];

  String get _initials {
    final first = contact.firstName.isNotEmpty ? contact.firstName[0] : '';
    final last = contact.lastName.isNotEmpty ? contact.lastName[0] : '';
    final res = '$first$last'.toUpperCase();
    return res.isNotEmpty ? res : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEmail = contact.email != null && contact.email!.trim().isNotEmpty;
    final hasPhone = contact.phone != null && contact.phone!.trim().isNotEmpty;
    final hasCompany =
        contact.companyName != null && contact.companyName!.trim().isNotEmpty;

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
            // Avatar + Name + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initials Avatar
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.18),
                        primaryColor.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Company
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasCompany)
                        InkWell(
                          onTap: contact.companyId != null
                              ? () => context.push(
                                    '/companies/${contact.companyId}',
                                    extra: contact.company,
                                  )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 15,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    contact.companyName!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (contact.companyId != null) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: primaryColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          'Independent Contact',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge with dropdown selection
                PopupMenuButton<String>(
                  tooltip: 'Change Status',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (newStatus) {
                    ref.read(contactsControllerProvider.notifier).updateStatus(
                          contactId: contact.id,
                          newStatus: newStatus,
                        );
                  },
                  itemBuilder: (context) {
                    return _availableStatuses.map((s) {
                      final isSelected =
                          s.toLowerCase() == contact.status.toLowerCase();
                      return PopupMenuItem<String>(
                        value: s,
                        child: Row(
                          children: [
                            StatusBadge(status: s),
                            const Spacer(),
                            if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: primaryColor,
                              ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: StatusBadge(status: contact.status),
                ),
              ],
            ),

            // Contact info rows
            if (hasEmail || hasPhone) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  if (hasEmail)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.mail_outline_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SelectableText(
                          contact.email!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  if (hasPhone)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SelectableText(
                          contact.phone!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
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
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.contact,
    required this.primaryColor,
    required this.onLaunch,
  });

  final Contact contact;
  final Color primaryColor;
  final void Function(Uri uri, String actionName) onLaunch;

  String _cleanPhoneNumber(String phone) {
    // Keep digits and leading plus if present
    final trimmed = phone.trim();
    final hasPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = contact.phone != null && contact.phone!.trim().isNotEmpty;
    final hasEmail = contact.email != null && contact.email!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasPhone && !hasEmail)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No phone number or email registered for quick actions.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Row(
                children: [
                  // Call Button
                  if (hasPhone) ...[
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: primaryColor,
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                        onTap: () {
                          final uri = Uri(
                            scheme: 'tel',
                            path: contact.phone!.trim(),
                          );
                          onLaunch(uri, 'Phone Call');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // WhatsApp Button
                  if (hasPhone) ...[
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF059669), // WhatsApp Emerald
                        backgroundColor:
                            const Color(0xFF059669).withValues(alpha: 0.1),
                        onTap: () {
                          final cleanPhone =
                              _cleanPhoneNumber(contact.phone!);
                          final uri =
                              Uri.parse('https://wa.me/$cleanPhone');
                          onLaunch(uri, 'WhatsApp');
                        },
                      ),
                    ),
                    if (hasEmail) const SizedBox(width: 10),
                  ],

                  // Email Button
                  if (hasEmail) ...[
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        color: const Color(0xFF2563EB), // Blue
                        backgroundColor:
                            const Color(0xFF2563EB).withValues(alpha: 0.1),
                        onTap: () {
                          final uri = Uri(
                            scheme: 'mailto',
                            path: contact.email!.trim(),
                          );
                          onLaunch(uri, 'Email Client');
                        },
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.contact,
    required this.primaryColor,
    required this.notesController,
    required this.isSaving,
    required this.onSaveNotes,
  });

  final Contact contact;
  final Color primaryColor;
  final TextEditingController notesController;
  final bool isSaving;
  final VoidCallback onSaveNotes;

  @override
  Widget build(BuildContext context) {
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
                  Icons.edit_note_rounded,
                  size: 22,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Add private notes, meeting logs, or reminders about ${contact.fullName}.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 14),

            // Multiline TextFormField
            TextFormField(
              controller: notesController,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                hintText:
                    'e.g. Spoke about Q4 renewal, prefers WhatsApp for follow-ups...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Save Note Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSaveNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  minimumSize: const Size(120, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  isSaving ? 'Saving...' : 'Save Note',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDealsState extends StatelessWidget {
  const _EmptyDealsState({
    required this.contactName,
    required this.primaryColor,
    required this.onAddDeal,
  });

  final String contactName;
  final Color primaryColor;
  final VoidCallback onAddDeal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.handshake_outlined,
              size: 26,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No active deals for this contact',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a deal to track revenue, pipeline stage, and follow-ups with $contactName.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddDeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              minimumSize: const Size(120, 40),
            ),
            icon: const Icon(Icons.add_business_rounded, size: 16),
            label: const Text(
              'Add Deal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
