import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../companies/presentation/controllers/companies_controller.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_metrics_controller.dart';
import '../../../deals/presentation/controllers/deals_controller.dart';
import '../../../tasks/presentation/controllers/tasks_controller.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_profile.dart';

/// Explicitly invalidates all primary data-fetching providers, search queries,
/// filter states, and memory caches across the app to prevent cross-account state leakage.
void invalidateAllUserData(Ref ref) {
  ref.invalidate(currentUserProfileProvider);
  ref.invalidate(teamProfilesProvider);
  ref.invalidate(usersDirectoryControllerProvider);
  ref.invalidate(contactsControllerProvider);
  ref.invalidate(searchQueryProvider);
  ref.invalidate(companiesControllerProvider);
  ref.invalidate(companySearchQueryProvider);
  ref.invalidate(companyIndustryFilterProvider);
  ref.invalidate(companiesProvider);
  ref.invalidate(dealsControllerProvider);
  ref.invalidate(tasksControllerProvider);
  ref.invalidate(taskSearchQueryProvider);
  ref.invalidate(taskStatusFilterProvider);
  ref.invalidate(dashboardMetricsControllerProvider);
}

/// Helper for container-level invalidation (useful in tests and global hooks).
void invalidateAllUserDataWithContainer(ProviderContainer container) {
  container.invalidate(currentUserProfileProvider);
  container.invalidate(teamProfilesProvider);
  container.invalidate(usersDirectoryControllerProvider);
  container.invalidate(contactsControllerProvider);
  container.invalidate(searchQueryProvider);
  container.invalidate(companiesControllerProvider);
  container.invalidate(companySearchQueryProvider);
  container.invalidate(companyIndustryFilterProvider);
  container.invalidate(companiesProvider);
  container.invalidate(dealsControllerProvider);
  container.invalidate(tasksControllerProvider);
  container.invalidate(taskSearchQueryProvider);
  container.invalidate(taskStatusFilterProvider);
  container.invalidate(dashboardMetricsControllerProvider);
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

/// Automatically refetches profile and cleans up state whenever auth state changes (login/logout/refresh)
final authStateStreamProvider = StreamProvider<void>((ref) {
  final stream = ref.watch(authRepositoryProvider).onAuthStateChange;
  final sub = stream.listen((authState) {
    if (authState.event == AuthChangeEvent.signedOut) {
      invalidateAllUserData(ref);
    }
  });
  ref.onDispose(sub.cancel);
  return stream.map((_) {});
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
  ref.watch(currentUserIdProvider);
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
      invalidateAllUserData(ref);
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
      invalidateAllUserData(ref);
    });
    return res;
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      invalidateAllUserData(ref);
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
    ref.watch(currentUserIdProvider);
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
