import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/contacts_controller.dart';
import '../widgets/contact_card.dart';
import '../widgets/contact_form_sheet.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final leadsAsync = ref.watch(qualifiedLeadsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

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
                      Icons.star_rounded,
                      color: Color(0xFF0F766E),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Qualified Leads',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh leads',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        ref.read(contactsControllerProvider.notifier).refresh();
                      },
                    ),
                  ],
                ),
              ),

              // Top Metrics Strip
              leadsAsync.maybeWhen(
                data: (leads) {
                  final uniqueCompanies = <String>{};
                  int withPhone = 0;
                  int withEmail = 0;

                  for (final lead in leads) {
                    if (lead.companyId != null && lead.companyId!.isNotEmpty) {
                      uniqueCompanies.add(lead.companyId!);
                    } else if (lead.companyName != null &&
                        lead.companyName!.isNotEmpty) {
                      uniqueCompanies.add(lead.companyName!);
                    }
                    if (lead.phone != null && lead.phone!.trim().isNotEmpty) {
                      withPhone++;
                    }
                    if (lead.email != null && lead.email!.trim().isNotEmpty) {
                      withEmail++;
                    }
                  }

                  return Container(
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
                            label: 'Total Leads',
                            value: '${leads.length}',
                            color: const Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 20),
                          _MetricItem(
                            label: 'Accounts',
                            value: '${uniqueCompanies.length}',
                            color: const Color(0xFF0F766E),
                          ),
                          const SizedBox(width: 20),
                          _MetricItem(
                            label: 'Direct Phone',
                            value: '$withPhone',
                            color: const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 20),
                          _MetricItem(
                            label: 'With Email',
                            value: '$withEmail',
                            color: const Color(0xFF059669),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref
                        .read(contactsControllerProvider.notifier)
                        .filterByQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search qualified leads by name, email, company...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(contactsControllerProvider.notifier)
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

              // Qualified Leads List
              Expanded(
                child: leadsAsync.when(
                  data: (leads) {
                    if (leads.isEmpty) {
                      return _EmptyLeadsState(
                        isSearching: searchQuery.isNotEmpty,
                        primaryColor: primaryColor,
                        onClearSearch: () {
                          _searchController.clear();
                          ref
                              .read(contactsControllerProvider.notifier)
                              .filterByQuery('');
                        },
                        onAddLead: () => ContactFormSheet.show(context),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(contactsControllerProvider.notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: leads.length,
                        itemBuilder: (context, index) {
                          final lead = leads[index];
                          return ContactCard(contact: lead);
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
                            'Failed to load qualified leads',
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
                                .read(contactsControllerProvider.notifier)
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
        onPressed: () => ContactFormSheet.show(context),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'New Lead',
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

class _EmptyLeadsState extends StatelessWidget {
  const _EmptyLeadsState({
    required this.isSearching,
    required this.primaryColor,
    required this.onClearSearch,
    required this.onAddLead,
  });

  final bool isSearching;
  final Color primaryColor;
  final VoidCallback onClearSearch;
  final VoidCallback onAddLead;

  @override
  Widget build(BuildContext context) {
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
                color: isSearching
                    ? Colors.grey.shade100
                    : primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.star_outline_rounded,
                size: 36,
                color: isSearching ? Colors.grey.shade400 : primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No matching leads' : 'No qualified leads yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try changing your search term or clearing the query.'
                  : 'Contacts with status marked as "Qualified" in your sales pipeline will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isSearching)
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear Search'),
              )
            else
              ElevatedButton.icon(
                onPressed: onAddLead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Contact'),
              ),
          ],
        ),
      ),
    );
  }
}
