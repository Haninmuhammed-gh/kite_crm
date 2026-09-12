import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/deal_repository.dart';
import '../../domain/deal.dart';

final dealsControllerProvider =
    NotifierProvider<DealsController, AsyncValue<List<Deal>>>(
  DealsController.new,
);

final totalPipelineValueProvider = Provider<double>((ref) {
  final dealsAsync = ref.watch(dealsControllerProvider);
  return dealsAsync.maybeWhen(
    data: (deals) => deals.fold<double>(0.0, (sum, d) => sum + d.value),
    orElse: () => 0.0,
  );
});

final dealsCountByStageProvider =
    Provider.family<int, String>((ref, stageKey) {
  final dealsAsync = ref.watch(dealsControllerProvider);
  return dealsAsync.maybeWhen(
    data: (deals) =>
        deals.where((d) => d.stage.toLowerCase() == stageKey.toLowerCase()).length,
    orElse: () => 0,
  );
});

final dealsValueByStageProvider =
    Provider.family<double, String>((ref, stageKey) {
  final dealsAsync = ref.watch(dealsControllerProvider);
  return dealsAsync.maybeWhen(
    data: (deals) => deals
        .where((d) => d.stage.toLowerCase() == stageKey.toLowerCase())
        .fold<double>(0.0, (sum, d) => sum + d.value),
    orElse: () => 0.0,
  );
});

final dealsByCompanyProvider =
    Provider.family<AsyncValue<List<Deal>>, String>((ref, companyId) {
  final dealsAsync = ref.watch(dealsControllerProvider);
  return dealsAsync.whenData((deals) {
    return deals.where((d) => d.companyId == companyId).toList();
  });
});

final dealsByContactProvider =
    Provider.family<AsyncValue<List<Deal>>, String>((ref, contactId) {
  final dealsAsync = ref.watch(dealsControllerProvider);
  return dealsAsync.whenData((deals) {
    return deals.where((d) => d.contactId == contactId).toList();
  });
});

class DealsController extends Notifier<AsyncValue<List<Deal>>> {
  @override
  AsyncValue<List<Deal>> build() {
    _fetchDeals();
    return const AsyncValue.loading();
  }

  Future<void> _fetchDeals() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(dealRepositoryProvider).fetchDeals();
    });
  }

  Future<void> refresh() async {
    await _fetchDeals();
  }

  Future<bool> addDeal({
    required String title,
    required double value,
    String? contactId,
    String? companyId,
    String stage = 'lead',
    DateTime? expectedCloseDate,
    String? assignedTo,
  }) async {
    try {
      await ref.read(dealRepositoryProvider).addDeal(
            title: title,
            value: value,
            contactId: contactId,
            companyId: companyId,
            stage: stage,
            expectedCloseDate: expectedCloseDate,
            assignedTo: assignedTo,
          );

      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateDeal({
    required String dealId,
    required String title,
    required double value,
    required String stage,
    String? contactId,
    String? companyId,
    DateTime? expectedCloseDate,
    String? assignedTo,
  }) async {
    try {
      await ref.read(dealRepositoryProvider).updateDeal(
            dealId: dealId,
            title: title,
            value: value,
            stage: stage,
            contactId: contactId,
            companyId: companyId,
            expectedCloseDate: expectedCloseDate,
            assignedTo: assignedTo,
          );

      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> updateStage({
    required String dealId,
    required String newStage,
  }) async {
    final previousState = state;

    // Optimistically update stage in local list
    state = state.whenData((deals) {
      return deals.map((deal) {
        if (deal.id == dealId) {
          return deal.copyWith(stage: newStage);
        }
        return deal;
      }).toList();
    });

    try {
      await ref.read(dealRepositoryProvider).updateDealStage(
            dealId: dealId,
            stage: newStage,
          );
      ref.invalidateSelf();
    } catch (e, st) {
      // Revert state if update fails
      state = previousState;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteDeal(String dealId) async {
    final previousState = state;

    // Optimistically remove
    state = state.whenData((deals) {
      return deals.where((d) => d.id != dealId).toList();
    });

    try {
      await ref.read(dealRepositoryProvider).deleteDeal(dealId: dealId);
      ref.invalidateSelf();
    } catch (e, st) {
      state = previousState;
      state = AsyncValue.error(e, st);
    }
  }
}
