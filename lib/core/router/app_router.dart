import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/auth/domain/user_profile.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/suspended_screen.dart';
import '../../features/companies/domain/company.dart';
import '../../features/companies/presentation/screens/companies_screen.dart';
import '../../features/companies/presentation/screens/company_details_screen.dart';
import '../../features/contacts/domain/contact.dart';
import '../../features/contacts/presentation/screens/contact_details_screen.dart';
import '../../features/contacts/presentation/screens/contacts_list_screen.dart';
import '../../features/contacts/presentation/screens/leads_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/deals/presentation/screens/deals_board_screen.dart';
import '../../features/tasks/domain/task.dart';
import '../../features/tasks/presentation/screens/task_details_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../layout/main_layout.dart';
import 'router_refresh_stream.dart';

final routerProvider = Provider<GoRouter>((ref) {
  GoRouterRefreshStream? refreshNotifier;
  try {
    refreshNotifier = GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    );
    ref.onDispose(refreshNotifier.dispose);
  } catch (_) {
    refreshNotifier = null;
  }

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refreshNotifier,
    redirect: (context, state) async {
      Session? session;
      try {
        session = Supabase.instance.client.auth.currentSession;
      } catch (_) {
        session = null;
      }

      final isAuthenticated = session != null;
      final isGuestOnlyAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';
      final isAllowedUnauthenticated =
          isGuestOnlyAuthRoute || state.matchedLocation == '/reset-password';

      if (!isAuthenticated && !isAllowedUnauthenticated) {
        return '/login';
      }
      if (isAuthenticated && isGuestOnlyAuthRoute) {
        return '/dashboard';
      }

      if (isAuthenticated) {
        UserProfile? profile;
        try {
          profile = await ref.read(currentUserProfileProvider.future);
        } catch (_) {
          profile = null;
        }

        // Global Route Guard for Suspended Accounts
        if (profile != null && profile.isSuspended) {
          if (state.matchedLocation != '/suspended') {
            return '/suspended';
          }
          return null; // allow staying on /suspended
        }

        // Prevent active accounts from remaining on /suspended
        if (state.matchedLocation == '/suspended') {
          return '/dashboard';
        }

        // RBAC Protection: Non-admins cannot access /admin
        if (state.matchedLocation.startsWith('/admin')) {
          if (profile == null || !profile.isAdmin) {
            return '/dashboard';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, _) => '/dashboard',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/suspended',
        builder: (context, state) => const SuspendedScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(
            currentLocation: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminPanelScreen(),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsListScreen(),
          ),
          GoRoute(
            path: '/contacts/:id',
            builder: (context, state) {
              final contactId = state.pathParameters['id'] ?? '';
              final contact = state.extra as Contact?;
              return ContactDetailsScreen(
                contactId: contactId,
                initialContact: contact,
              );
            },
          ),
          GoRoute(
            path: '/leads',
            builder: (context, state) => const LeadsScreen(),
          ),
          GoRoute(
            path: '/companies',
            builder: (context, state) => const CompaniesScreen(),
          ),
          GoRoute(
            path: '/companies/:id',
            builder: (context, state) {
              final companyId = state.pathParameters['id'] ?? '';
              final company = state.extra as Company?;
              return CompanyDetailsScreen(
                companyId: companyId,
                initialCompany: company,
              );
            },
          ),
          GoRoute(
            path: '/deals',
            builder: (context, state) => const DealsBoardScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) {
              final status = state.uri.queryParameters['status'];
              return TasksScreen(initialStatus: status);
            },
          ),
          GoRoute(
            path: '/tasks/:id',
            builder: (context, state) {
              final taskId = state.pathParameters['id'] ?? '';
              final task = state.extra as Task?;
              return TaskDetailsScreen(
                taskId: taskId,
                initialTask: task,
              );
            },
          ),
        ],
      ),
    ],
  );
});
