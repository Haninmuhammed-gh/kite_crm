import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kite_crm/core/utils/currency_formatter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../contacts/presentation/widgets/contact_form_sheet.dart';
import '../../domain/deal.dart';
import '../controllers/deals_controller.dart';
import 'deal_form_sheet.dart';

class DealCard extends ConsumerWidget {
  const DealCard({
    super.key,
    required this.deal,
  });

  final Deal deal;

  static const stages = ['lead', 'demo', 'negotiation', 'won', 'lost'];

  static String stageLabel(String s) {
    switch (s.toLowerCase()) {
      case 'lead':
        return 'Lead';
      case 'demo':
        return 'Demo / Pitch';
      case 'negotiation':
        return 'Negotiation';
      case 'won':
        return 'Closed Won';
      case 'lost':
        return 'Closed Lost';
      default:
        return s;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Deal?'),
        content: Text('Are you sure you want to delete "${deal.title}"?'),
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
              ref.read(dealsControllerProvider.notifier).deleteDeal(deal.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedValue = CurrencyFormatter.format(deal.value);
    final isAdmin = ref.watch(isAdminProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final canEdit = isAdmin || (deal.assignedTo != null && deal.assignedTo == currentUserId);

    final cardContent = _CardBody(
      deal: deal,
      formattedValue: formattedValue,
      isAdmin: isAdmin,
      onStageSelected: (newStage) {
        ref
            .read(dealsControllerProvider.notifier)
            .updateStage(dealId: deal.id, newStage: newStage);
      },
      onEdit: canEdit ? () => DealFormSheet.show(context, deal: deal) : null,
      onDelete: isAdmin ? () => _showDeleteConfirmation(context, ref) : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Draggable<Deal>(
        data: deal,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Opacity(
              opacity: 0.92,
              child: _CardBody(
                deal: deal,
                formattedValue: formattedValue,
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: cardContent,
        ),
        child: cardContent,
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.deal,
    required this.formattedValue,
    this.onStageSelected,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  final Deal deal;
  final String formattedValue;
  final ValueChanged<String>? onStageSelected;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final companyId = deal.companyId ?? deal.contact?.companyId;
    final companyName = deal.companyName;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and stage quick-menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    deal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (onStageSelected != null || onEdit != null || (isAdmin && onDelete != null))
                  PopupMenuButton<String>(
                    tooltip: 'Deal options',
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (val) {
                      if (val == '__edit__' && onEdit != null) {
                        onEdit!();
                      } else if (val == '__delete__' && onDelete != null) {
                        onDelete!();
                      } else if (onStageSelected != null) {
                        onStageSelected!(val);
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        if (onStageSelected != null)
                          ...DealCard.stages.map((s) {
                            final isCurrent =
                                s.toLowerCase() == deal.stage.toLowerCase();
                            return PopupMenuItem<String>(
                              value: s,
                              child: Row(
                                children: [
                                  Text(
                                    DealCard.stageLabel(s),
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isCurrent ? primaryColor : null,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isCurrent)
                                    Icon(Icons.check_rounded,
                                        size: 16, color: primaryColor),
                                ],
                              ),
                            );
                          }),
                        if (onEdit != null) ...[
                          if (onStageSelected != null) const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: '__edit__',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFF0F172A)),
                                SizedBox(width: 8),
                                Text(
                                  'Edit Deal',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isAdmin && onDelete != null) ...[
                          if (onStageSelected != null && onEdit == null)
                            const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: '__delete__',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Colors.red.shade600),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Deal',
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ];
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Deal Value Badge & Expected Close Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formattedValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669), // Emerald 600
                    ),
                  ),
                ),
                if (deal.expectedCloseDate != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(deal.expectedCloseDate!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Relational Action Chips: Contact and Company
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (deal.contactName != null)
                  ActionChip(
                    avatar: const Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: Color(0xFF475569),
                    ),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        deal.contactName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: BorderSide(color: Colors.grey.shade300, width: 0.8),
                    onPressed: deal.contact != null
                        ? () => ContactFormSheet.show(context, contact: deal.contact)
                        : null,
                  ),
                if (companyName != null && companyName.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(
                      Icons.business_rounded,
                      size: 13,
                      color: Color(0xFF0F766E),
                    ),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    backgroundColor: const Color(0xFFF0FDFA),
                    side: const BorderSide(color: Color(0xFFCCFBF1), width: 0.8),
                    onPressed: companyId != null
                        ? () => context.push('/companies/$companyId')
                        : null,
                  ),
                if (deal.contactName == null && (companyName == null || companyName.isEmpty))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      'No contact linked',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
