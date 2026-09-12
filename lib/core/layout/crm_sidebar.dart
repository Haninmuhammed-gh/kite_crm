import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class CrmSidebar extends ConsumerStatefulWidget {
  const CrmSidebar({
    super.key,
    this.currentLocation,
    this.initialCollapsed = false,
    this.onCollapseChanged,
    this.isDrawer = false,
  });

  final String? currentLocation;
  final bool initialCollapsed;
  final ValueChanged<bool>? onCollapseChanged;
  final bool isDrawer;

  @override
  ConsumerState<CrmSidebar> createState() => _CrmSidebarState();
}

class _CrmSidebarState extends ConsumerState<CrmSidebar> {
  late bool _isCollapsed;

  static const _navItems = [
    _NavItemData(
      label: 'Dashboard',
      route: '/dashboard',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    _NavItemData(
      label: 'Contacts',
      route: '/contacts',
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt_rounded,
    ),
    _NavItemData(
      label: 'Leads',
      route: '/leads',
      icon: Icons.star_outline_rounded,
      selectedIcon: Icons.star_rounded,
    ),
    _NavItemData(
      label: 'Companies',
      route: '/companies',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business_rounded,
    ),
    _NavItemData(
      label: 'Pipeline',
      route: '/deals',
      icon: Icons.view_kanban_outlined,
      selectedIcon: Icons.view_kanban_rounded,
    ),
    _NavItemData(
      label: 'Tasks',
      route: '/tasks',
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist_rounded,
    ),
    _NavItemData(
      label: 'Analytics',
      route: '/analytics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    _NavItemData(
      label: 'Profile',
      route: '/profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
    _NavItemData(
      label: 'About',
      route: '/about',
      icon: Icons.info_outline_rounded,
      selectedIcon: Icons.info_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initialCollapsed;
  }

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    widget.onCollapseChanged?.call(_isCollapsed);
  }

  String _resolveCurrentPath(BuildContext context) {
    if (widget.currentLocation != null && widget.currentLocation!.isNotEmpty) {
      return widget.currentLocation!;
    }
    try {
      return GoRouterState.of(context).matchedLocation;
    } catch (_) {
      return '';
    }
  }

  bool _isRouteActive(String currentPath, String itemRoute) {
    if (itemRoute == '/dashboard') {
      return currentPath == '/dashboard' || currentPath == '/';
    }
    return currentPath.startsWith(itemRoute);
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Kite CRM?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E);
    const slateDark = Color(0xFF0F172A);
    const slateMuted = Color(0xFF64748B);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    final currentPath = _resolveCurrentPath(context);
    final isCollapsed = !widget.isDrawer && (isSmallScreen || _isCollapsed);
    final width = widget.isDrawer ? 280.0 : (isCollapsed ? 72.0 : 240.0);
    final isAdmin = ref.watch(isAdminProvider);

    final navItems = [
      ..._navItems.take(8), // Dashboard through Profile
      if (isAdmin)
        const _NavItemData(
          label: 'Admin Panel',
          route: '/admin',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings_rounded,
        ),
      ..._navItems.skip(8), // About
    ];

    final sidebarContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Header: Toggle button & optional brand info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: isCollapsed
                  ? Center(
                      child: Visibility(
                        visible: !isSmallScreen && !widget.isDrawer,
                        child: IconButton(
                          tooltip: 'Expand sidebar',
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: slateMuted,
                            size: 22,
                          ),
                          onPressed: _toggleCollapsed,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: widget.isDrawer ? 256 : 216,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.flight_takeoff_rounded,
                              color: primaryTeal,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Kite CRM',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: slateDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (widget.isDrawer)
                              IconButton(
                                tooltip: 'Close menu',
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: slateMuted,
                                  size: 22,
                                ),
                                onPressed: () => Navigator.of(context).maybePop(),
                              )
                            else
                              Visibility(
                                visible: !isSmallScreen,
                                child: IconButton(
                                  tooltip: 'Collapse sidebar',
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: slateMuted,
                                    size: 22,
                                  ),
                                  onPressed: _toggleCollapsed,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                children: navItems.map((item) {
                  final isActive = _isRouteActive(currentPath, item.route);
                  final icon = isActive ? item.selectedIcon : item.icon;

                  if (isCollapsed) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Tooltip(
                        message: item.label,
                        preferBelow: false,
                        waitDuration: const Duration(milliseconds: 300),
                        child: InkWell(
                          onTap: () {
                            if (widget.isDrawer) {
                              Navigator.of(context).maybePop();
                            }
                            context.go(item.route);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? primaryTeal.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              icon,
                              size: 22,
                              color: isActive ? primaryTeal : slateMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Material(
                      color: isActive
                          ? primaryTeal.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          if (widget.isDrawer) {
                            Navigator.of(context).maybePop();
                          }
                          context.go(item.route);
                        },
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: const Color(0xFFF8FAFC),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: 192,
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 20,
                                    color: isActive ? primaryTeal : slateMuted,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isActive ? primaryTeal : slateDark,
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: primaryTeal,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom Section: Sign Out
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 12.0,
              ),
              child: isCollapsed
                  ? Tooltip(
                      message: 'Sign Out',
                      preferBelow: false,
                      child: InkWell(
                        onTap: _handleSignOut,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _handleSignOut,
                        borderRadius: BorderRadius.circular(12),
                        hoverColor: const Color(0xFFFEF2F2),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: 192,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    size: 20,
                                    color: Color(0xFFDC2626),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Sign Out',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    if (widget.isDrawer) {
      return Drawer(
        backgroundColor: Colors.white,
        elevation: 0,
        width: 280.0,
        child: sidebarContent,
      );
    }

    return sidebarContent;
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
}
