import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/contact.dart';
import '../controllers/contacts_controller.dart';
import 'contact_form_sheet.dart';
import 'status_badge.dart';

class ContactCard extends ConsumerWidget {
  const ContactCard({
    super.key,
    required this.contact,
  });

  final Contact contact;

  static const _availableStatuses = ['new', 'contacted', 'qualified', 'lost'];

  String get _initials {
    final first = contact.firstName.isNotEmpty ? contact.firstName[0] : '';
    final last = contact.lastName.isNotEmpty ? contact.lastName[0] : '';
    final res = '$first$last'.toUpperCase();
    return res.isNotEmpty ? res : '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isAdmin = ref.watch(isAdminProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final canEdit = isAdmin || (contact.assignedTo != null && contact.assignedTo == currentUserId);
    final canDelete = isAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          context.push('/contacts/${contact.id}', extra: contact);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name & Company, Status Badge / Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Initials Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Company
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              contact.companyName ?? 'Independent',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge with PopupMenu to update status
                PopupMenuButton<String>(
                  tooltip: 'Update Status',
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
                              const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Color(0xFF0F766E),
                              ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: StatusBadge(status: contact.status),
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
                        ContactFormSheet.show(context, contact: contact);
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
                                'Edit Contact',
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
                                'Delete Contact',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),

            // Contact details (Email, Phone) if available
            if ((contact.email != null && contact.email!.isNotEmpty) ||
                (contact.phone != null && contact.phone!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (contact.email != null && contact.email!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          contact.email!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  if (contact.phone != null && contact.phone!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          contact.phone!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
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
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete "${contact.fullName}"? Associated deals and tasks will also be affected.',
        ),
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
              ref
                  .read(contactsControllerProvider.notifier)
                  .deleteContact(contact.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
