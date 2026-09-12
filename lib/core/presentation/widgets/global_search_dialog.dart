import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/companies/domain/company.dart';
import '../../../features/companies/presentation/controllers/companies_controller.dart';
import '../../../features/contacts/domain/contact.dart';
import '../../../features/contacts/presentation/controllers/contacts_controller.dart';

class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const GlobalSearchDialog(),
    );
  }

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsControllerProvider);
    final companiesAsync = ref.watch(companiesControllerProvider);

    final contacts = contactsAsync.value ?? <Contact>[];
    final companies = companiesAsync.value ?? <Company>[];

    final q = _query.trim().toLowerCase();

    final matchingContacts = q.isEmpty
        ? <Contact>[]
        : contacts.where((c) {
            final name = c.fullName.toLowerCase();
            final email = (c.email ?? '').toLowerCase();
            final comp = (c.companyName ?? '').toLowerCase();
            return name.contains(q) || email.contains(q) || comp.contains(q);
          }).toList();

    final matchingCompanies = q.isEmpty
        ? <Company>[]
        : companies.where((c) {
            final name = c.name.toLowerCase();
            final industry = (c.industry ?? '').toLowerCase();
            return name.contains(q) || industry.contains(q);
          }).toList();

    final hasQuery = q.isNotEmpty;
    final totalResults = matchingContacts.length + matchingCompanies.length;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 12.0, 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF0F766E),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _query = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search contacts, companies by name, email...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                        });
                      },
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'ESC',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results / Empty / Prompt Content
            Expanded(
              child: !hasQuery
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.travel_explore_rounded,
                                color: Color(0xFF0F766E),
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Search Kite CRM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Type a name, email, or company to instantly jump to details',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : totalResults == 0
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 44,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No results found for "$_query"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Check spelling or try a different term',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          children: [
                            if (matchingContacts.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Contacts',
                                count: matchingContacts.length,
                              ),
                              ...matchingContacts.map(
                                (c) => ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0F766E)
                                        .withValues(alpha: 0.12),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF0F766E),
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    c.fullName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (c.email != null && c.email!.isNotEmpty)
                                        c.email!,
                                      if (c.companyName != null &&
                                          c.companyName!.isNotEmpty)
                                        c.companyName!,
                                    ].join(' • '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  trailing: const _CategoryBadge(
                                    label: 'Contact',
                                    color: Color(0xFF0F766E),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.go('/contacts/${c.id}');
                                  },
                                ),
                              ),
                            ],
                            if (matchingCompanies.isNotEmpty) ...[
                              if (matchingContacts.isNotEmpty)
                                const Divider(height: 16),
                              _SectionHeader(
                                title: 'Companies',
                                count: matchingCompanies.length,
                              ),
                              ...matchingCompanies.map(
                                (comp) => ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF0284C7)
                                        .withValues(alpha: 0.12),
                                    child: const Icon(
                                      Icons.business,
                                      color: Color(0xFF0284C7),
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    comp.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: comp.industry != null &&
                                          comp.industry!.isNotEmpty
                                      ? Text(
                                          comp.industry!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        )
                                      : null,
                                  trailing: const _CategoryBadge(
                                    label: 'Company',
                                    color: Color(0xFF0284C7),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.go('/companies/${comp.id}');
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
