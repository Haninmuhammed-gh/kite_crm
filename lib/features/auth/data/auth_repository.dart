import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._supabase);

  final SupabaseClient? _supabase;

  User? get currentUser {
    try {
      return _supabase?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession {
    try {
      return _supabase?.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get onAuthStateChange {
    try {
      return _supabase?.auth.onAuthStateChange ?? const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase!.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

  Future<void> signOut() async {
    await _supabase?.auth.signOut();
  }

  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) async {
    final client = _supabase;
    if (client == null) return;
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo ?? 'http://localhost:3000/#/reset-password',
    );
  }

  Future<UserResponse?> updatePassword(String newPassword) async {
    final client = _supabase;
    if (client == null) return null;
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateProfileName(String userId, String newName) async {
    final client = _supabase;
    if (client == null) return;
    await client.from('profiles').update({
      'full_name': newName.trim(),
    }).eq('id', userId);
  }

  Future<UserProfile?> fetchCurrentUserProfile() async {
    final client = _supabase;
    if (client == null) return null;
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;
      final response = await client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserProfile>> fetchTeamProfiles() async {
    final client = _supabase;
    if (client == null) return [];
    try {
      final response = await client
          .from('profiles')
          .select('*')
          .order('full_name', ascending: true);
      return (response as List)
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UserProfile>> fetchAllProfiles() async {
    final client = _supabase;
    if (client == null) return [];
    try {
      final response = await client
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);
      return (response as List)
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateUserRoleAndStatus({
    required String userId,
    String? role,
    String? status,
  }) async {
    final client = _supabase;
    if (client == null) return;
    final updates = <String, dynamic>{};
    if (role != null) updates['role'] = role;
    if (status != null) updates['status'] = status;
    if (updates.isEmpty) return;
    await client.from('profiles').update(updates).eq('id', userId);
  }
}
