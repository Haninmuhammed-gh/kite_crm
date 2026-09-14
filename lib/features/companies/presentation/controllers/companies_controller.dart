import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../../deals/presentation/controllers/deals_controller.dart';
import '../../data/company_repository.dart';
import '../../domain/company.dart';

final companiesControllerProvider =
    NotifierProvider<CompaniesController, AsyncValue<List<Company>>>(
  CompaniesController.new,
);

class CompanySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final companySearchQueryProvider =
    NotifierProvider<CompanySearchQueryNotifier, String>(
  CompanySearchQueryNotifier.new,
);

class CompanyIndustryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) => state = filter;
}

final companyIndustryFilterProvider =
    NotifierProvider<CompanyIndustryFilterNotifier, String>(
  CompanyIndustryFilterNotifier.new,
);

final filteredCompaniesProvider = Provider<AsyncValue<List<Company>>>((ref) {
  final companiesAsync = ref.watch(companiesControllerProvider);
  final query = ref.watch(companySearchQueryProvider).trim().toLowerCase();
  final industryFilter =
      ref.watch(companyIndustryFilterProvider).trim().toLowerCase();

  return companiesAsync.whenData((companies) {
    return companies.where((company) {
      final matchesSearch = query.isEmpty ||
          company.name.toLowerCase().contains(query) ||
          (company.industry ?? '').toLowerCase().contains(query) ||
          (company.website ?? '').toLowerCase().contains(query) ||
          (company.phone ?? '').toLowerCase().contains(query);

      final matchesIndustry = industryFilter == 'all' ||
          (company.industry ?? '').toLowerCase() == industryFilter;

      return matchesSearch && matchesIndustry;
    }).toList();
  });
});

final companyByIdProvider = Provider.family<Company?, String>((ref, id) {
  final companiesAsync = ref.watch(companiesControllerProvider);
  return companiesAsync.value?.where((c) => c.id == id).firstOrNull;
});

class CompanyStats {
  const CompanyStats({
    required this.total,
    required this.industries,
    required this.withWebsite,
    required this.myCompanies,
  });

  final int total;
  final int industries;
  final int withWebsite;
  final int myCompanies;
}

final companyStatsProvider = Provider<CompanyStats>((ref) {
  final companiesAsync = ref.watch(companiesControllerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  return companiesAsync.maybeWhen(
    data: (companies) {
      final uniqueIndustries = <String>{};
      int withWebsite = 0;
      int myCompanies = 0;

      for (final c in companies) {
        if (c.industry != null && c.industry!.trim().isNotEmpty) {
          uniqueIndustries.add(c.industry!.trim().toLowerCase());
        }
        if (c.website != null && c.website!.trim().isNotEmpty) {
          withWebsite++;
        }
        if (c.assignedTo != null && c.assignedTo == currentUserId) {
          myCompanies++;
        }
      }

      return CompanyStats(
        total: companies.length,
        industries: uniqueIndustries.length,
        withWebsite: withWebsite,
        myCompanies: myCompanies,
      );
    },
    orElse: () => const CompanyStats(
      total: 0,
      industries: 0,
      withWebsite: 0,
      myCompanies: 0,
    ),
  );
});

class CompaniesController extends Notifier<AsyncValue<List<Company>>> {
  @override
  AsyncValue<List<Company>> build() {
    ref.watch(currentUserIdProvider);
    _fetchCompanies();
    return const AsyncValue.loading();
  }

  Future<void> _fetchCompanies() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(companyRepositoryProvider).fetchCompanies();
    });
  }

  Future<void> refresh() async {
    await _fetchCompanies();
  }

  void filterByQuery(String query) {
    ref.read(companySearchQueryProvider.notifier).setQuery(query);
  }

  void filterByIndustry(String industry) {
    ref.read(companyIndustryFilterProvider.notifier).setFilter(industry);
  }

  Future<bool> addCompany({
    required String name,
    String? industry,
    String? website,
    String? phone,
    String? assignedTo,
  }) async {
    try {
      await ref.read(companyRepositoryProvider).addCompany(
            name: name,
            industry: industry,
            website: website,
            phone: phone,
            assignedTo: assignedTo,
          );

      ref.invalidateSelf();
      ref.invalidate(companiesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCompany({
    required String companyId,
    required String name,
    String? industry,
    String? website,
    String? phone,
    String? assignedTo,
  }) async {
    try {
      await ref.read(companyRepositoryProvider).updateCompany(
            companyId: companyId,
            name: name,
            industry: industry,
            website: website,
            phone: phone,
            assignedTo: assignedTo,
          );

      ref.invalidateSelf();
      ref.invalidate(companiesProvider);
      ref.invalidate(contactsControllerProvider);
      ref.invalidate(dealsControllerProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteCompany(String companyId) async {
    final previousState = state;

    state = state.whenData((list) => list.where((c) => c.id != companyId).toList());

    try {
      await ref.read(companyRepositoryProvider).deleteCompany(companyId: companyId);
      ref.invalidateSelf();
      ref.invalidate(companiesProvider);
      ref.invalidate(contactsControllerProvider);
      ref.invalidate(dealsControllerProvider);
    } catch (e, st) {
      state = previousState;
      state = AsyncValue.error(e, st);
    }
  }
}
