import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/company.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(Supabase.instance.client);
});

class CompanyRepository {
  CompanyRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Company>> fetchCompanies() async {
    final response = await _supabase
        .from('companies')
        .select('*')
        .order('name', ascending: true);

    return (response as List)
        .map((item) => Company.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Company?> fetchCompanyById(String companyId) async {
    final response = await _supabase
        .from('companies')
        .select('*')
        .eq('id', companyId)
        .maybeSingle();

    if (response == null) return null;
    return Company.fromJson(response);
  }

  Future<Company> addCompany({
    required String name,
    String? industry,
    String? website,
    String? phone,
    String? assignedTo,
  }) async {
    final currentUserId = assignedTo ?? _supabase.auth.currentUser?.id;
    final insertData = <String, dynamic>{
      'name': name.trim(),
      if (industry != null && industry.trim().isNotEmpty)
        'industry': industry.trim(),
      if (website != null && website.trim().isNotEmpty)
        'website': website.trim(),
      if (phone != null && phone.trim().isNotEmpty)
        'phone': phone.trim(),
      if (currentUserId != null && currentUserId.isNotEmpty)
        'assigned_to': currentUserId,
    };

    final response = await _supabase
        .from('companies')
        .insert(insertData)
        .select('*')
        .single();

    return Company.fromJson(response);
  }

  Future<Company> updateCompany({
    required String companyId,
    required String name,
    String? industry,
    String? website,
    String? phone,
    String? assignedTo,
  }) async {
    final updateData = <String, dynamic>{
      'name': name.trim(),
      'industry': (industry != null && industry.trim().isNotEmpty)
          ? industry.trim()
          : null,
      'website': (website != null && website.trim().isNotEmpty)
          ? website.trim()
          : null,
      'phone': (phone != null && phone.trim().isNotEmpty)
          ? phone.trim()
          : null,
      if (assignedTo != null && assignedTo.isNotEmpty)
        'assigned_to': assignedTo,
    };

    final response = await _supabase
        .from('companies')
        .update(updateData)
        .eq('id', companyId)
        .select('*')
        .single();

    return Company.fromJson(response);
  }

  Future<void> deleteCompany({
    required String companyId,
  }) async {
    await _supabase.from('companies').delete().eq('id', companyId);
  }
}
