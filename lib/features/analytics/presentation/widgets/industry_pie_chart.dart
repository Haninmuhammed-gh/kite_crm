import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/analytics_controller.dart';

class IndustryPieChart extends ConsumerStatefulWidget {
  const IndustryPieChart({
    super.key,
    this.height = 260,
    this.showCardWrapper = true,
  });

  final double height;
  final bool showCardWrapper;

  @override
  ConsumerState<IndustryPieChart> createState() => _IndustryPieChartState();
}

class _IndustryPieChartState extends ConsumerState<IndustryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final industryDataAsync = ref.watch(companiesByIndustryProvider);

    return industryDataAsync.when(
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
              'Error loading industry chart: $e',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
      ),
      data: (industries) {
        if (industries.isEmpty) {
          return _wrapCard(
            context,
            SizedBox(
              height: widget.height,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pie_chart_outline_rounded,
                        size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      'No Companies Tracked',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add companies to view market sector breakdown.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            totalCompanies: 0,
          );
        }

        final totalCompanies =
            industries.fold<int>(0, (sum, item) => sum + item.count);

        final sections = List.generate(industries.length, (i) {
          final isTouched = i == _touchedIndex;
          final item = industries[i];
          final radius = isTouched ? 65.0 : 54.0;
          return PieChartSectionData(
            color: item.color,
            value: item.count.toDouble(),
            title: isTouched
                ? '${item.percentage.toStringAsFixed(1)}%'
                : (item.percentage >= 10
                    ? '${item.percentage.toStringAsFixed(0)}%'
                    : ''),
            radius: radius,
            titleStyle: TextStyle(
              fontSize: isTouched ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
          );
        });

        final chartContent = LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final chartWidget = SizedBox(
              height: widget.height,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 42,
                  sections: sections,
                ),
              ),
            );

            final legendWidget = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: industries.map((item) {
                final idx = industries.indexOf(item);
                final isSelected = idx == _touchedIndex;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _touchedIndex = isSelected ? -1 : idx;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? item.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.industry,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.count} (${item.percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );

            if (isNarrow) {
              return Column(
                children: [
                  chartWidget,
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: industries.map((item) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.industry} (${item.count})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: chartWidget),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: legendWidget),
              ],
            );
          },
        );

        return _wrapCard(
          context,
          chartContent,
          totalCompanies: totalCompanies,
        );
      },
    );
  }

  Widget _wrapCard(
    BuildContext context,
    Widget child, {
    int? totalCompanies,
  }) {
    if (!widget.showCardWrapper) return child;

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
                    Icons.pie_chart_rounded,
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
                        'Company Distribution by Industry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Market sectors and account concentration across accounts',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalCompanies != null)
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
                    child: Text(
                      '$totalCompanies ${totalCompanies == 1 ? 'account' : 'accounts'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
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
