import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/companies_controller.dart';
import '../widgets/company_card.dart';
import '../widgets/company_form_sheet.dart';

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final companiesAsync = ref.watch(filteredCompaniesProvider);
    final allCompaniesAsync = ref.watch(companiesControllerProvider);
    final stats = ref.watch(companyStatsProvider);
    final searchQuery = ref.watch(companySearchQueryProvider);
    final activeIndustry = ref.watch(companyIndustryFilterProvider);

    // Extract dynamic industry categories
    final availableIndustries = <String>{'all'};
    allCompaniesAsync.whenData((list) {
      for (final c in list) {
        if (c.industry != null && c.industry!.trim().isNotEmpty) {
          availableIndustries.add(c.industry!.trim());
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Page Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      color: Color(0xFF0F766E),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Companies Directory',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh companies',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () =>
                          ref.read(companiesControllerProvider.notifier).refresh(),
                    ),
                  ],
                ),
              ),
              // Top Metrics Strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
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
                        label: 'Total Companies',
                        value: '${stats.total}',
                        color: const Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'Industries',
                        value: '${stats.industries}',
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'With Website',
                        value: '${stats.withWebsite}',
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'My Accounts',
                        value: '${stats.myCompanies}',
                        color: const Color(0xFF0D9488),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref
                        .read(companiesControllerProvider.notifier)
                        .filterByQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search companies by name, industry, website...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(companiesControllerProvider.notifier)
                                  .filterByQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),

              // Industry Filter Chips
              if (availableIndustries.length > 1)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: availableIndustries.map((ind) {
                      final isSelected = activeIndustry == ind.toLowerCase() ||
                          (ind == 'all' && activeIndustry == 'all');
                      final label = ind == 'all' ? 'All Industries' : ind;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(companiesControllerProvider.notifier)
                                .filterByIndustry(ind);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: primaryColor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? primaryColor
                                : const Color(0xFF475569),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 8),

              // Companies List
              Expanded(
                child: companiesAsync.when(
                  data: (companies) {
                    if (companies.isEmpty) {
                      return _EmptyState(
                        isSearchOrFilter: searchQuery.isNotEmpty ||
                            activeIndustry != 'all',
                        onReset: () {
                          _searchController.clear();
                          ref
                              .read(companiesControllerProvider.notifier)
                              .filterByQuery('');
                          ref
                              .read(companiesControllerProvider.notifier)
                              .filterByIndustry('all');
                        },
                        onAddCompany: () => CompanyFormSheet.show(context),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(companiesControllerProvider.notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: companies.length,
                        itemBuilder: (context, index) {
                          final company = companies[index];
                          return CompanyCard(company: company);
                        },
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load companies',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref
                                .read(companiesControllerProvider.notifier)
                                .refresh(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CompanyFormSheet.show(context),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.domain_add_rounded),
        label: const Text(
          'New Company',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
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
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearchOrFilter,
    required this.onReset,
    required this.onAddCompany,
  });

  final bool isSearchOrFilter;
  final VoidCallback onReset;
  final VoidCallback onAddCompany;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isSearchOrFilter
                    ? Colors.grey.shade100
                    : primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearchOrFilter
                    ? Icons.search_off_rounded
                    : Icons.business_rounded,
                size: 36,
                color: isSearchOrFilter ? Colors.grey.shade400 : primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchOrFilter
                  ? 'No matching companies'
                  : 'No companies registered yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchOrFilter
                  ? 'Try changing your search term or industry filter.'
                  : 'Start tracking corporate accounts, client organizations, and corporate partners in Kite CRM.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isSearchOrFilter)
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: onAddCompany,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add First Company'),
              ),
          ],
        ),
      ),
    );
  }
}
