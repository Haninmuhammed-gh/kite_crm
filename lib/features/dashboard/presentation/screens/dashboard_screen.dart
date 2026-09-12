import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../analytics/presentation/widgets/pipeline_bar_chart.dart';
import '../controllers/dashboard_metrics_controller.dart';
import '../widgets/recent_deals_list.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user;
    try {
      user = Supabase.instance.client.auth.currentUser;
    } catch (_) {
      user = null;
    }

    final profile = ref.watch(currentUserProfileProvider).value;
    final userEmail = profile?.email ?? user?.email ?? 'No email found';
    final userName = (profile?.fullName != null && profile!.fullName!.trim().isNotEmpty)
        ? profile.fullName!.trim()
        : user?.userMetadata?['full_name'] as String?;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final metrics = ref.watch(dashboardMetricsControllerProvider);
    final currencyFormatter = NumberFormat.simpleCurrency(decimalDigits: 0);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // In-page header
                Row(
                  children: [
                    Icon(
                      Icons.flight_takeoff_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Kite CRM',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Welcome Hero Card
                Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        const Color(0xFF115E59),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Kite CRM Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        userName != null && userName.isNotEmpty
                            ? 'Welcome to Kite CRM, $userName!'
                            : 'Welcome to Kite CRM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Logged in as $userEmail',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pipeline Revenue by Stage Bar Chart
                const PipelineBarChart(),
                const SizedBox(height: 24),

                // Metrics / Live CRM Stats Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StatCard(
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 16) / 2,
                          title: 'Active Leads',
                          value: '${metrics.activeLeads}',
                          icon: Icons.people_outline_rounded,
                          accentColor: Colors.blue.shade600,
                          isLoading: metrics.isLoading,
                          onTap: () => context.push('/contacts'),
                        ),
                        _StatCard(
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 16) / 2,
                          title: 'Pipeline Value',
                          value: currencyFormatter.format(metrics.pipelineValue),
                          icon: Icons.attach_money_rounded,
                          accentColor: const Color(0xFF10B981),
                          isLoading: metrics.isLoading,
                          onTap: () => context.push('/deals'),
                        ),
                        _StatCard(
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 16) / 2,
                          title: 'Won Deals',
                          value: '${metrics.wonDeals}',
                          icon: Icons.verified_outlined,
                          accentColor: Colors.amber.shade700,
                          isLoading: metrics.isLoading,
                          onTap: () => context.push('/deals'),
                        ),
                        _StatCard(
                          width: isNarrow
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 16) / 2,
                          title: 'Conversion Rate',
                          value: '${metrics.conversionRate.toStringAsFixed(1)}%',
                          icon: Icons.trending_up_rounded,
                          accentColor: Colors.purple.shade600,
                          isLoading: metrics.isLoading,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent Deals Pipeline Activity Feed
                RecentDealsList(
                  deals: metrics.recentDeals,
                  isLoading: metrics.isLoading,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.isLoading = false,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final cardWidget = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );

    return SizedBox(
      width: width,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: cardWidget,
            )
          : cardWidget,
    );
  }
}
