import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/deal.dart';

final dealRepositoryProvider = Provider<DealRepository>((ref) {
  return DealRepository(Supabase.instance.client);
});

class DealRepository {
  DealRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Deal>> fetchDeals() async {
    try {
      final response = await _supabase.from('deals').select(
            '*, contacts(id, first_name, last_name, email, phone, status, company_id, companies(*)), companies(id, name, industry, website, phone)',
          );
      return (response as List)
          .map((item) => Deal.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final response = await _supabase.from('deals').select(
              '*, contacts(*), companies(*)',
            );
        return (response as List)
            .map((item) => Deal.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final basic = await _supabase.from('deals').select('*');
        return (basic as List)
            .map((item) => Deal.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
  }

  Future<Deal> addDeal({
    required String title,
    required double value,
    String? contactId,
    String? companyId,
    String stage = 'lead',
    DateTime? expectedCloseDate,
    String? assignedTo,
  }) async {
    final currentUserId = assignedTo ?? _supabase.auth.currentUser?.id;
    final insertData = <String, dynamic>{
      'title': title,
      'value': value,
      'stage': stage,
      if (contactId != null && contactId.isNotEmpty) 'contact_id': contactId,
      if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      if (currentUserId != null && currentUserId.isNotEmpty)
        'assigned_to': currentUserId,
      if (expectedCloseDate != null)
        'expected_close_date':
            expectedCloseDate.toIso8601String().split('T').first,
    };

    try {
      final response = await _supabase
          .from('deals')
          .insert(insertData)
          .select('*, contacts(id, first_name, last_name, email), companies(id, name, industry, website, phone)')
          .single();
      return Deal.fromJson(response);
    } catch (_) {
      final fallback = await _supabase
          .from('deals')
          .insert(insertData)
          .select('*')
          .single();
      return Deal.fromJson(fallback);
    }
  }

  Future<void> updateDealStage({
    required String dealId,
    required String stage,
  }) async {
    await _supabase
        .from('deals')
        .update({'stage': stage})
        .eq('id', dealId);
  }

  Future<Deal> updateDeal({
    required String dealId,
    required String title,
    required double value,
    required String stage,
    String? contactId,
    String? companyId,
    DateTime? expectedCloseDate,
    String? assignedTo,
  }) async {
    final updateData = <String, dynamic>{
      'title': title.trim(),
      'value': value,
      'stage': stage,
      'contact_id': (contactId != null && contactId.isNotEmpty) ? contactId : null,
      'company_id': (companyId != null && companyId.isNotEmpty) ? companyId : null,
      'expected_close_date':
          expectedCloseDate?.toIso8601String().split('T').first,
      if (assignedTo != null && assignedTo.isNotEmpty)
        'assigned_to': assignedTo,
    };

    try {
      final response = await _supabase
          .from('deals')
          .update(updateData)
          .eq('id', dealId)
          .select('*, contacts(id, first_name, last_name, email), companies(id, name, industry, website, phone)')
          .single();
      return Deal.fromJson(response);
    } catch (_) {
      final fallback = await _supabase
          .from('deals')
          .update(updateData)
          .eq('id', dealId)
          .select('*')
          .single();
      return Deal.fromJson(fallback);
    }
  }

  Future<void> deleteDeal({
    required String dealId,
  }) async {
    await _supabase.from('deals').delete().eq('id', dealId);
  }
}
