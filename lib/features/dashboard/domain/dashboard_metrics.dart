import '../../deals/domain/deal.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.activeLeads,
    required this.pipelineValue,
    required this.wonDeals,
    required this.conversionRate,
    required this.totalDeals,
    required this.recentDeals,
    this.isLoading = false,
    this.errorMessage,
  });

  final int activeLeads;
  final double pipelineValue;
  final int wonDeals;
  final double conversionRate;
  final int totalDeals;
  final List<Deal> recentDeals;
  final bool isLoading;
  final String? errorMessage;

  factory DashboardMetrics.initial() {
    return const DashboardMetrics(
      activeLeads: 0,
      pipelineValue: 0.0,
      wonDeals: 0,
      conversionRate: 0.0,
      totalDeals: 0,
      recentDeals: [],
      isLoading: true,
    );
  }

  DashboardMetrics copyWith({
    int? activeLeads,
    double? pipelineValue,
    int? wonDeals,
    double? conversionRate,
    int? totalDeals,
    List<Deal>? recentDeals,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardMetrics(
      activeLeads: activeLeads ?? this.activeLeads,
      pipelineValue: pipelineValue ?? this.pipelineValue,
      wonDeals: wonDeals ?? this.wonDeals,
      conversionRate: conversionRate ?? this.conversionRate,
      totalDeals: totalDeals ?? this.totalDeals,
      recentDeals: recentDeals ?? this.recentDeals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardMetrics &&
          runtimeType == other.runtimeType &&
          activeLeads == other.activeLeads &&
          pipelineValue == other.pipelineValue &&
          wonDeals == other.wonDeals &&
          conversionRate == other.conversionRate &&
          totalDeals == other.totalDeals &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        activeLeads,
        pipelineValue,
        wonDeals,
        conversionRate,
        totalDeals,
        isLoading,
        errorMessage,
      );

  @override
  String toString() =>
      'DashboardMetrics(leads: $activeLeads, pipeline: $pipelineValue, won: $wonDeals, rate: ${conversionRate.toStringAsFixed(1)}%)';
}
