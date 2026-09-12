import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/company.dart';
import '../domain/contact.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(Supabase.instance.client);
});

class ContactRepository {
  ContactRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Contact>> fetchContacts() async {
    try {
      final response = await _supabase
          .from('contacts')
          .select('*, companies(id, name, industry, website, phone)')
          .order('first_name', ascending: true);
      return (response as List)
          .map((item) => Contact.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback in case join relation name is companies(*) or plain select
      try {
        final fallback = await _supabase
            .from('contacts')
            .select('*, companies(*)');
        return (fallback as List)
            .map((item) => Contact.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final basic = await _supabase.from('contacts').select('*');
        return (basic as List)
            .map((item) => Contact.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
  }

  Future<Contact?> fetchContactById(String contactId) async {
    try {
      final response = await _supabase
          .from('contacts')
          .select('*, companies(id, name, industry, website, phone)')
          .eq('id', contactId)
          .maybeSingle();
      if (response == null) return null;
      return Contact.fromJson(response);
    } catch (_) {
      try {
        final fallback = await _supabase
            .from('contacts')
            .select('*, companies(*)')
            .eq('id', contactId)
            .maybeSingle();
        if (fallback == null) return null;
        return Contact.fromJson(fallback);
      } catch (_) {
        final basic = await _supabase
            .from('contacts')
            .select('*')
            .eq('id', contactId)
            .maybeSingle();
        if (basic == null) return null;
        return Contact.fromJson(basic);
      }
    }
  }

  Future<Contact> addContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? companyId,
    String status = 'new',
    String? assignedTo,
    String? notes,
  }) async {
    final currentUserId = assignedTo ?? _supabase.auth.currentUser?.id;
    final insertData = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      if (currentUserId != null && currentUserId.isNotEmpty)
        'assigned_to': currentUserId,
      'status': status,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      final response = await _supabase
          .from('contacts')
          .insert(insertData)
          .select('*, companies(id, name, industry, website, phone)')
          .single();
      return Contact.fromJson(response);
    } catch (_) {
      final fallback = await _supabase
          .from('contacts')
          .insert(insertData)
          .select('*')
          .single();
      return Contact.fromJson(fallback);
    }
  }

  Future<void> updateContactStatus({
    required String contactId,
    required String status,
  }) async {
    await _supabase
        .from('contacts')
        .update({'status': status})
        .eq('id', contactId);
  }

  Future<Contact> updateContact({
    required String contactId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? companyId,
    String status = 'new',
    String? assignedTo,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': (email != null && email.trim().isNotEmpty) ? email.trim() : null,
      'phone': (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
      'company_id': (companyId != null && companyId.isNotEmpty) ? companyId : null,
      if (assignedTo != null && assignedTo.isNotEmpty) 'assigned_to': assignedTo,
      'status': status,
      'notes': (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
    };

    try {
      final response = await _supabase
          .from('contacts')
          .update(updateData)
          .eq('id', contactId)
          .select('*, companies(id, name, industry, website, phone)')
          .single();
      return Contact.fromJson(response);
    } catch (_) {
      final fallback = await _supabase
          .from('contacts')
          .update(updateData)
          .eq('id', contactId)
          .select('*')
          .single();
      return Contact.fromJson(fallback);
    }
  }

  Future<void> deleteContact({
    required String contactId,
  }) async {
    await _supabase.from('contacts').delete().eq('id', contactId);
  }

  Future<List<Company>> fetchCompanies() async {
    try {
      final response = await _supabase
          .from('companies')
          .select('*')
          .order('name', ascending: true);
      return (response as List)
          .map((item) => Company.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await _supabase.from('companies').select('*');
      return (response as List)
          .map((item) => Company.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  Future<List<Contact>> fetchContactsByCompany(String companyId) async {
    try {
      final response = await _supabase
          .from('contacts')
          .select('*, companies(id, name, industry, website, phone)')
          .eq('company_id', companyId)
          .order('first_name', ascending: true);
      return (response as List)
          .map((item) => Contact.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final fallback = await _supabase
            .from('contacts')
            .select('*, companies(*)')
            .eq('company_id', companyId);
        return (fallback as List)
            .map((item) => Contact.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        final basic = await _supabase
            .from('contacts')
            .select('*')
            .eq('company_id', companyId);
        return (basic as List)
            .map((item) => Contact.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
  }
}
