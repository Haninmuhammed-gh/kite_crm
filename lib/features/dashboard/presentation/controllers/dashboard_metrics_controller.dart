import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../../deals/presentation/controllers/deals_controller.dart';
import '../../domain/dashboard_metrics.dart';

final dashboardMetricsControllerProvider = Provider<DashboardMetrics>((ref) {
  final contactsAsync = ref.watch(contactsControllerProvider);
  final dealsAsync = ref.watch(dealsControllerProvider);

  final isLoading = contactsAsync.isLoading || dealsAsync.isLoading;
  final hasError = contactsAsync.hasError || dealsAsync.hasError;
  final error = contactsAsync.error ?? dealsAsync.error;

  final contacts = contactsAsync.value ?? [];
  final deals = dealsAsync.value ?? [];

  // Total Active Leads: contacts with 'new' or 'contacted' status
  final activeLeads = contacts.where((contact) {
    final status = contact.status.toLowerCase();
    return status == 'new' || status == 'contacted';
  }).length;

  // Total Pipeline Value: sum of all deals not lost
  final nonLostDeals = deals.where((deal) {
    return deal.stage.toLowerCase() != 'lost';
  }).toList();
  final pipelineValue =
      nonLostDeals.fold<double>(0.0, (sum, deal) => sum + deal.value);

  // Won Deals: count of 'won' deals
  final wonDeals = deals.where((deal) {
    return deal.stage.toLowerCase() == 'won';
  }).length;

  // Conversion Rate: Won Deals / Total Deals * 100
  final totalDeals = deals.length;
  final conversionRate =
      totalDeals > 0 ? (wonDeals / totalDeals) * 100.0 : 0.0;

  // 5 most recent deals
  final recentDeals = deals.take(5).toList();

  return DashboardMetrics(
    activeLeads: activeLeads,
    pipelineValue: pipelineValue,
    wonDeals: wonDeals,
    conversionRate: conversionRate,
    totalDeals: totalDeals,
    recentDeals: recentDeals,
    isLoading: isLoading && contacts.isEmpty && deals.isEmpty,
    errorMessage: hasError ? error.toString() : null,
  );
});
