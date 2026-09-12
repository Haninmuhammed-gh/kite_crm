import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.onTap,
  });

  final String status;
  final VoidCallback? onTap;

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'qualified':
        return const Color(0xFF059669); // Emerald 600
      case 'contacted':
        return const Color(0xFF2563EB); // Blue 600
      case 'new':
        return const Color(0xFF4F46E5); // Indigo 600
      case 'lost':
        return const Color(0xFFDC2626); // Red 600
      default:
        return const Color(0xFF64748B); // Slate 500
    }
  }

  static Color getStatusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'qualified':
        return const Color(0xFFECFDF5); // Emerald 50
      case 'contacted':
        return const Color(0xFFEFF6FF); // Blue 50
      case 'new':
        return const Color(0xFFEEF2FF); // Indigo 50
      case 'lost':
        return const Color(0xFFFEF2F2); // Red 50
      default:
        return const Color(0xFFF1F5F9); // Slate 100
    }
  }

  static String formatStatus(String status) {
    if (status.isEmpty) return 'New';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    final bg = getStatusBackground(status);

    final badge = Container(
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
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: badge,
      );
    }

    return badge;
  }
}
