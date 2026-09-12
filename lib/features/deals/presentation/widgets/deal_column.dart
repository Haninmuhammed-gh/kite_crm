import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/deal.dart';
import '../controllers/deals_controller.dart';
import 'deal_card.dart';

class DealColumn extends ConsumerWidget {
  const DealColumn({
    super.key,
    required this.stageKey,
    required this.title,
    required this.accentColor,
    required this.deals,
    required this.onAddDeal,
  });

  final String stageKey;
  final String title;
  final Color accentColor;
  final List<Deal> deals;
  final VoidCallback onAddDeal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 0);
    final totalValue = deals.fold<double>(0.0, (sum, d) => sum + d.value);

    return Container(
      width: 290,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: DragTarget<Deal>(
        onWillAcceptWithDetails: (details) =>
            details.data.stage.toLowerCase() != stageKey.toLowerCase(),
        onAcceptWithDetails: (details) {
          ref.read(dealsControllerProvider.notifier).updateStage(
                dealId: details.data.id,
                newStage: stageKey,
              );
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              color: isHovering
                  ? accentColor.withValues(alpha: 0.08)
                  : const Color(0xFFF1F5F9), // Slate 100
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering
                    ? accentColor
                    : Colors.grey.shade200,
                width: isHovering ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column Header
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${deals.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 20),
                      tooltip: 'Add deal to $title',
                      color: Colors.grey.shade600,
                      onPressed: onAddDeal,
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Total stage value
                Text(
                  currencyFormatter.format(totalValue),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Deals List inside Column
                Expanded(
                  child: deals.isEmpty
                      ? Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 36.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isHovering
                                    ? accentColor
                                    : Colors.grey.shade300,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHovering
                                      ? Icons.file_download_rounded
                                      : Icons.inbox_outlined,
                                  size: 28,
                                  color: isHovering
                                      ? accentColor
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isHovering
                                      ? 'Drop to move here'
                                      : 'No deals in this stage',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isHovering
                                        ? accentColor
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: deals.length,
                          itemBuilder: (context, index) {
                            return DealCard(deal: deals[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
