import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_profile.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

/// Automatically refetches profile whenever auth state changes (login/logout/refresh)
final authStateStreamProvider = StreamProvider<void>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange.map((_) {});
});

/// Fetches the current user's profile from `profiles` table
final currentUserProfileProvider =
    FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateStreamProvider);
  return await ref.watch(authRepositoryProvider).fetchCurrentUserProfile();
});

/// Exposes the current user's role explicitly ('admin' or 'member')
final currentUserRoleProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.role ?? 'member',
    orElse: () => 'member',
  );
});

/// Boolean helper to check if the current user is an admin
final isAdminProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.isAdmin ?? false,
    orElse: () => false,
  );
});

/// Exposes the current authenticated user's ID
final currentUserIdProvider = Provider<String?>((ref) {
  final profileId = ref.watch(currentUserProfileProvider).asData?.value?.id;
  if (profileId != null) return profileId;
  return ref.watch(authRepositoryProvider).currentUser?.id;
});

/// Fetches all profiles in the organization (for admin assignment)
final teamProfilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  return await ref.watch(authRepositoryProvider).fetchTeamProfiles();
});

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithPassword(
            email: email,
            password: password,
          );
      ref.invalidate(currentUserProfileProvider);
    });
  }

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    AuthResponse? res;
    state = await AsyncValue.guard(() async {
      res = await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            fullName: fullName,
          );
      ref.invalidate(currentUserProfileProvider);
    });
    return res;
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(currentUserProfileProvider);
    });
  }

  Future<void> updateUserName(String newName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authRepositoryProvider).currentUser;
      final profileId = ref.read(currentUserIdProvider) ?? user?.id;
      if (profileId == null) {
        throw Exception('User is not authenticated');
      }
      await ref.read(authRepositoryProvider).updateProfileName(profileId, newName);
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(teamProfilesProvider);
      await ref.read(currentUserProfileProvider.future);
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).resetPasswordForEmail(
            email.trim(),
            redirectTo: kReleaseMode
                ? 'https://kite-crm.vercel.app/#/reset-password'
                : 'http://localhost:3000/#/reset-password',
          );
    });
  }

  Future<void> updatePassword(String newPassword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
    });
  }
}

final usersDirectoryControllerProvider =
    AsyncNotifierProvider<UsersDirectoryController, List<UserProfile>>(
  UsersDirectoryController.new,
);

class UsersDirectoryController extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() async {
    return await ref.watch(authRepositoryProvider).fetchAllProfiles();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updateUserRoleAndStatus(
            userId: userId,
            role: newRole,
          );
      ref.invalidate(teamProfilesProvider);
      ref.invalidate(currentUserProfileProvider);
      ref.invalidateSelf();
      return await ref.read(authRepositoryProvider).fetchAllProfiles();
    });
  }

  Future<void> updateUserStatus(String userId, String newStatus) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updateUserRoleAndStatus(
            userId: userId,
            status: newStatus,
          );
      ref.invalidate(teamProfilesProvider);
      ref.invalidate(currentUserProfileProvider);
      ref.invalidateSelf();
      return await ref.read(authRepositoryProvider).fetchAllProfiles();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await ref.read(authRepositoryProvider).fetchAllProfiles();
    });
  }
}
