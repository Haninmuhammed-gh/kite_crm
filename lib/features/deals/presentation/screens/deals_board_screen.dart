import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/deals_controller.dart';
import '../widgets/deal_column.dart';
import '../widgets/deal_form_sheet.dart';

class DealsBoardScreen extends ConsumerWidget {
  const DealsBoardScreen({super.key});

  static const _stages = [
    _StageConfig(
      key: 'lead',
      title: 'Lead / Discovery',
      color: Color(0xFF6366F1), // Indigo
    ),
    _StageConfig(
      key: 'demo',
      title: 'Demo / Pitch',
      color: Color(0xFF2563EB), // Blue
    ),
    _StageConfig(
      key: 'negotiation',
      title: 'Negotiation',
      color: Color(0xFFD97706), // Amber
    ),
    _StageConfig(
      key: 'won',
      title: 'Closed Won',
      color: Color(0xFF059669), // Emerald
    ),
    _StageConfig(
      key: 'lost',
      title: 'Closed Lost',
      color: Color(0xFFDC2626), // Red
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsControllerProvider);
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 0);

    return Scaffold(
      body: dealsAsync.when(
        data: (deals) {
          final totalPipeline =
              deals.fold<double>(0.0, (sum, d) => sum + d.value);
          final wonDeals = deals
              .where((d) => d.stage.toLowerCase() == 'won')
              .fold<double>(0.0, (sum, d) => sum + d.value);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Deals Pipeline',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh deals',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        ref.read(dealsControllerProvider.notifier).refresh();
                      },
                    ),
                  ],
                ),
              ),

              // Top Pipeline Metrics Strip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MetricItem(
                        label: 'Total Pipeline',
                        value: currencyFormatter.format(totalPipeline),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 24),
                      _MetricItem(
                        label: 'Total Deals',
                        value: '${deals.length}',
                        color: const Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 24),
                      _MetricItem(
                        label: 'Closed Won',
                        value: currencyFormatter.format(wonDeals),
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Icon(Icons.touch_app_outlined,
                              size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            'Drag cards between columns to change stage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Kanban Board Columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _stages.map((stage) {
                      final stageDeals = deals
                          .where((d) =>
                              d.stage.toLowerCase() == stage.key.toLowerCase())
                          .toList();

                      return DealColumn(
                        stageKey: stage.key,
                        title: stage.title,
                        accentColor: stage.color,
                        deals: stageDeals,
                        onAddDeal: () => DealFormSheet.show(
                          context,
                          initialStage: stage.key,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 44, color: Colors.red.shade600),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load deals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(dealsControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DealFormSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Deal'),
      ),
    );
  }
}

class _StageConfig {
  const _StageConfig({
    required this.key,
    required this.title,
    required this.color,
  });

  final String key;
  final String title;
  final Color color;
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
