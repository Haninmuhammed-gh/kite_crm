import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/analytics_controller.dart';

class PipelineBarChart extends ConsumerStatefulWidget {
  const PipelineBarChart({
    super.key,
    this.height = 280,
    this.showCardWrapper = true,
  });

  final double height;
  final bool showCardWrapper;

  @override
  ConsumerState<PipelineBarChart> createState() => _PipelineBarChartState();
}

class _PipelineBarChartState extends ConsumerState<PipelineBarChart> {
  int? _touchedIndex;

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
    } else {
      return '\$${value.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageDataAsync = ref.watch(dealsByStageChartProvider);
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 0);
    final isMobile = MediaQuery.sizeOf(context).width < 800;

    return stageDataAsync.when(
      loading: () => _wrapCard(
        context,
        SizedBox(
          height: widget.height,
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F766E)),
          ),
        ),
      ),
      error: (e, _) => _wrapCard(
        context,
        SizedBox(
          height: widget.height,
          child: Center(
            child: Text(
              'Error loading chart: $e',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
      ),
      data: (stages) {
        final totalValue =
            stages.fold<double>(0.0, (sum, s) => sum + s.totalValue);
        final totalDeals = stages.fold<int>(0, (sum, s) => sum + s.count);

        if (totalDeals == 0) {
          return _wrapCard(
            context,
            SizedBox(
              height: widget.height,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'No Deals in Pipeline',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create deals to visualize revenue progression across stages.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            totalValue: 0,
            totalDeals: 0,
          );
        }

        double maxValue = 0;
        for (final s in stages) {
          if (s.totalValue > maxValue) maxValue = s.totalValue;
        }
        final maxY = (maxValue * 1.25).clamp(1000.0, double.infinity);

        final barGroups = List.generate(stages.length, (i) {
          final item = stages[i];
          final isTouched = _touchedIndex == i;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: item.totalValue,
                color: isTouched
                    ? item.color.withValues(alpha: 0.85)
                    : item.color,
                width: isMobile ? 22 : 26,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFFF1F5F9),
                ),
              ),
            ],
          );
        });

        final chart = SizedBox(
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 12.0, bottom: 4.0),
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = stages[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.stageLabel}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: currencyFormatter.format(item.totalValue),
                            style: const TextStyle(
                              color: Color(0xFF34D399), // Emerald 400
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text:
                                '\n${item.count} ${item.count == 1 ? 'deal' : 'deals'}',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        _touchedIndex = null;
                        return;
                      }
                      _touchedIndex =
                          response.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        if (value == meta.max) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            _formatCompact(value),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 48 : 32,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= stages.length) {
                          return const SizedBox.shrink();
                        }
                        final item = stages[idx];
                        final String label = (isMobile &&
                                (item.stageKey == 'negotiation' ||
                                    item.stageLabel.toLowerCase() == 'negotiation'))
                            ? 'Negot.'
                            : item.stageLabel;

                        return SideTitleWidget(
                          meta: meta,
                          angle: isMobile ? -45 * (math.pi / 180) : 0.0,
                          space: isMobile ? 4.0 : 8.0,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: isMobile ? 10.0 : 12.0,
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        );

        return _wrapCard(
          context,
          chart,
          totalValue: totalValue,
          totalDeals: totalDeals,
        );
      },
    );
  }

  Widget _wrapCard(
    BuildContext context,
    Widget child, {
    double? totalValue,
    int? totalDeals,
  }) {
    if (!widget.showCardWrapper) return child;

    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 0);

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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF0F766E),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pipeline Revenue by Stage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Deal distribution and monetary value across sales milestones',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalValue != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(totalValue),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        Text(
                          '$totalDeals ${totalDeals == 1 ? 'deal' : 'deals'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 28),
            child,
          ],
        ),
      ),
    );
  }
}
