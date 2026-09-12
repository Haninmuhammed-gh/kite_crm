import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../companies/presentation/controllers/companies_controller.dart';
import '../../../deals/presentation/controllers/deals_controller.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';

class StageRevenueData {
  const StageRevenueData({
    required this.stageKey,
    required this.stageLabel,
    required this.totalValue,
    required this.count,
    required this.color,
  });

  final String stageKey;
  final String stageLabel;
  final double totalValue;
  final int count;
  final Color color;

  StageRevenueData copyWith({
    String? stageKey,
    String? stageLabel,
    double? totalValue,
    int? count,
    Color? color,
  }) {
    return StageRevenueData(
      stageKey: stageKey ?? this.stageKey,
      stageLabel: stageLabel ?? this.stageLabel,
      totalValue: totalValue ?? this.totalValue,
      count: count ?? this.count,
      color: color ?? this.color,
    );
  }
}

class IndustryCountData {
  const IndustryCountData({
    required this.industry,
    required this.count,
    required this.percentage,
    required this.color,
  });

  final String industry;
  final int count;
  final double percentage;
  final Color color;
}

class TaskCompletionStats {
  const TaskCompletionStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.completionRate,
    required this.overdueCount,
  });

  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final double completionRate;
  final int overdueCount;

  static const empty = TaskCompletionStats(
    total: 0,
    pending: 0,
    inProgress: 0,
    completed: 0,
    completionRate: 0.0,
    overdueCount: 0,
  );
}

const _stageConfigs = [
  (key: 'lead', label: 'Lead', color: Color(0xFF6366F1)), // Indigo
  (key: 'demo', label: 'Demo', color: Color(0xFF2563EB)), // Blue
  (key: 'negotiation', label: 'Negotiation', color: Color(0xFFD97706)), // Amber
  (key: 'won', label: 'Won', color: Color(0xFF059669)), // Emerald
  (key: 'lost', label: 'Lost', color: Color(0xFFDC2626)), // Red
];

const _industryPalette = [
  Color(0xFF0F766E), // Deep Teal
  Color(0xFF0284C7), // Sky
  Color(0xFF6366F1), // Indigo
  Color(0xFFD97706), // Amber
  Color(0xFF10B981), // Emerald
  Color(0xFF8B5CF6), // Purple
  Color(0xFFF43F5E), // Rose
  Color(0xFF64748B), // Slate
];

/// Sums deal values grouped by deal stage
final dealsByStageChartProvider =
    Provider<AsyncValue<List<StageRevenueData>>>((ref) {
  final dealsAsync = ref.watch(dealsControllerProvider);

  return dealsAsync.whenData((deals) {
    final Map<String, (double value, int count)> stageMap = {};
    for (final cfg in _stageConfigs) {
      stageMap[cfg.key] = (0.0, 0);
    }

    for (final deal in deals) {
      final key = deal.stage.toLowerCase();
      final current = stageMap[key] ?? (0.0, 0);
      stageMap[key] = (current.$1 + deal.value, current.$2 + 1);
    }

    final List<StageRevenueData> result = [];
    for (final cfg in _stageConfigs) {
      final data = stageMap[cfg.key] ?? (0.0, 0);
      result.add(
        StageRevenueData(
          stageKey: cfg.key,
          stageLabel: cfg.label,
          totalValue: data.$1,
          count: data.$2,
          color: cfg.color,
        ),
      );
    }

    // Include any custom stages not in default configs
    stageMap.forEach((key, data) {
      if (!_stageConfigs.any((c) => c.key == key)) {
        final label =
            key.isEmpty ? 'Other' : '${key[0].toUpperCase()}${key.substring(1)}';
        result.add(
          StageRevenueData(
            stageKey: key,
            stageLabel: label,
            totalValue: data.$1,
            count: data.$2,
            color: const Color(0xFF64748B),
          ),
        );
      }
    });

    return result;
  });
});

/// Counts companies grouped by industry
final companiesByIndustryProvider =
    Provider<AsyncValue<List<IndustryCountData>>>((ref) {
  final companiesAsync = ref.watch(companiesControllerProvider);

  return companiesAsync.whenData((companies) {
    if (companies.isEmpty) return [];

    final Map<String, int> counts = {};
    for (final company in companies) {
      final industry = (company.industry != null &&
              company.industry!.trim().isNotEmpty)
          ? company.industry!.trim()
          : 'Unspecified';
      counts[industry] = (counts[industry] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = companies.length;
    final List<IndustryCountData> result = [];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = _industryPalette[i % _industryPalette.length];
      final pct = (entry.value / total) * 100;
      result.add(
        IndustryCountData(
          industry: entry.key,
          count: entry.value,
          percentage: pct,
          color: color,
        ),
      );
    }

    return result;
  });
});

/// Calculates task status breakdown and percentages
final taskCompletionStatsProvider =
    Provider<AsyncValue<TaskCompletionStats>>((ref) {
  final tasksAsync = ref.watch(tasksControllerProvider);

  return tasksAsync.whenData((tasks) {
    if (tasks.isEmpty) return TaskCompletionStats.empty;

    int pending = 0;
    int inProgress = 0;
    int completed = 0;
    int overdue = 0;

    for (final task in tasks) {
      final s = task.status.toLowerCase();
      if (s == 'completed') {
        completed++;
      } else if (s == 'in_progress') {
        inProgress++;
      } else {
        pending++;
      }

      if (task.isOverdue) {
        overdue++;
      }
    }

    final total = tasks.length;
    final rate = total == 0 ? 0.0 : (completed / total) * 100;

    return TaskCompletionStats(
      total: total,
      pending: pending,
      inProgress: inProgress,
      completed: completed,
      completionRate: rate,
      overdueCount: overdue,
    );
  });
});
