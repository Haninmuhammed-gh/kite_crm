import 'package:flutter/material.dart';

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({
    super.key,
    required this.status,
    this.onStatusSelected,
  });

  final String status;
  final ValueChanged<String>? onStatusSelected;

  static const availableStatuses = ['pending', 'in_progress', 'completed'];

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF059669); // Emerald 600
      case 'in_progress':
        return const Color(0xFF2563EB); // Blue 600
      case 'pending':
      default:
        return const Color(0xFFD97706); // Amber 600
    }
  }

  static Color getStatusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFECFDF5); // Emerald 50
      case 'in_progress':
        return const Color(0xFFEFF6FF); // Blue 50
      case 'pending':
      default:
        return const Color(0xFFFFFBEB); // Amber 50
    }
  }

  static String formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    final bg = getStatusBackground(status);

    final chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatStatus(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onStatusSelected != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: color,
            ),
          ],
        ],
      ),
    );

    if (onStatusSelected != null) {
      return PopupMenuButton<String>(
        tooltip: 'Change Status',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: onStatusSelected,
        itemBuilder: (context) {
          return availableStatuses.map((s) {
            final isCurrent = s.toLowerCase() == status.toLowerCase();
            final sColor = getStatusColor(s);
            return PopupMenuItem<String>(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatStatus(s),
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? sColor : null,
                    ),
                  ),
                  const Spacer(),
                  if (isCurrent)
                    Icon(Icons.check_rounded, size: 16, color: sColor),
                ],
              ),
            );
          }).toList();
        },
        child: chipContent,
      );
    }

    return chipContent;
  }
}
