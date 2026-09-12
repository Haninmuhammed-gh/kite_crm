import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../companies/presentation/controllers/companies_controller.dart';
import '../../../deals/presentation/controllers/deals_controller.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../controllers/analytics_controller.dart';
import '../widgets/industry_pie_chart.dart';
import '../widgets/pipeline_bar_chart.dart';
import '../widgets/task_completion_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 0);
    final totalPipeline = ref.watch(totalPipelineValueProvider);
    final companiesAsync = ref.watch(companiesControllerProvider);
    final taskStatsAsync = ref.watch(taskCompletionStatsProvider);

    final totalCompanies =
        companiesAsync.maybeWhen(data: (c) => c.length, orElse: () => 0);
    final taskCompletionRate =
        taskStatsAsync.maybeWhen(data: (s) => s.completionRate, orElse: () => 0.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF0F766E),
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Analytics & Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Refresh analytics',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () {
                          ref.read(dealsControllerProvider.notifier).refresh();
                          ref.read(companiesControllerProvider.notifier).refresh();
                          ref.read(tasksControllerProvider.notifier).refresh();
                        },
                      ),
                    ],
                  ),
                ),

                // KPI summary strip
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _KpiMiniCard(
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 28) / 3,
                          title: 'Total Pipeline',
                          value: currencyFormatter.format(totalPipeline),
                          icon: Icons.monetization_on_outlined,
                          color: const Color(0xFF0F766E), // Deep Teal
                          onTap: () => context.go('/deals'),
                        ),
                        _KpiMiniCard(
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 28) / 3,
                          title: 'Active Accounts',
                          value: '$totalCompanies',
                          icon: Icons.business_rounded,
                          color: const Color(0xFF0284C7), // Sky
                          onTap: () => context.go('/companies'),
                        ),
                        _KpiMiniCard(
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 28) / 3,
                          title: 'Task Completion',
                          value: '${taskCompletionRate.toStringAsFixed(0)}%',
                          icon: Icons.checklist_rounded,
                          color: const Color(0xFF059669), // Emerald
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 1. Pipeline Revenue Bar Chart
                const PipelineBarChart(),
                const SizedBox(height: 20),

                // 2. Company Industry Pie Chart
                const IndustryPieChart(),
                const SizedBox(height: 20),

                // 3. Task Completion & Productivity
                const TaskCompletionCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiMiniCard extends StatelessWidget {
  const _KpiMiniCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    ],
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
