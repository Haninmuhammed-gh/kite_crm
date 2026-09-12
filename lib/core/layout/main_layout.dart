import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/widgets/user_avatar_button.dart';
import '../presentation/widgets/global_search_dialog.dart';
import 'crm_sidebar.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({
    super.key,
    required this.child,
    this.currentLocation,
  });

  final Widget child;
  final String? currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryTeal = Color(0xFF0F766E);
    const slateDark = Color(0xFF0F172A);

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
          GlobalSearchDialog.show(context),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
          GlobalSearchDialog.show(context),
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;

            if (isDesktop) {
              // 1. Desktop/Tablet (maxWidth >= 800): Keep existing permanent sidebar behavior
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                appBar: AppBar(
                  toolbarHeight: 56,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  title: const Row(
                    children: [
                      Icon(
                        Icons.flight_takeoff_rounded,
                        color: primaryTeal,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Kite CRM',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: slateDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    _GlobalSearchButton(
                      onPressed: () => GlobalSearchDialog.show(context),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: UserAvatarButton(),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1.0),
                    child: Container(color: Colors.grey.shade200, height: 1.0),
                  ),
                ),
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CrmSidebar(currentLocation: currentLocation),
                    Expanded(child: child),
                  ],
                ),
              );
            }

            // 2. Mobile (maxWidth < 800): Content in body, AppBar with hamburger menu, drawer
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                toolbarHeight: 56,
                backgroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                centerTitle: false,
                titleSpacing: 0,
                leading: const DrawerButton(color: slateDark),
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flight_takeoff_rounded,
                      color: primaryTeal,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Kite CRM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: slateDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                actions: [
                  _GlobalSearchButton(
                    compact: true,
                    onPressed: () => GlobalSearchDialog.show(context),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: UserAvatarButton(),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.0),
                  child: Container(color: Colors.grey.shade200, height: 1.0),
                ),
              ),
              drawer: CrmSidebar(
                currentLocation: currentLocation,
                isDrawer: true,
              ),
              body: child,
            );
          },
        ),
      ),
    );
  }
}

class _GlobalSearchButton extends StatelessWidget {
  const _GlobalSearchButton({
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Search (Ctrl+K)',
        icon: Icon(
          Icons.search_rounded,
          size: 20,
          color: Colors.grey.shade700,
        ),
        onPressed: onPressed,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Search...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Ctrl+K',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
