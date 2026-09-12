import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'admin', 'member', 'suspended'

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E);
    const slateDark = Color(0xFF0F172A);
    const slateMuted = Color(0xFF64748B);

    final usersAsync = ref.watch(usersDirectoryControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: usersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryTeal),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: 12),
                Text(
                  'Failed to load user directory',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(usersDirectoryControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(backgroundColor: primaryTeal),
                ),
              ],
            ),
          ),
          data: (allUsers) {
            final totalUsers = allUsers.length;
            final admins = allUsers.where((u) => u.isAdmin).length;
            final members = allUsers.where((u) => u.isMember).length;
            final suspended = allUsers.where((u) => u.isSuspended).length;

            final q = _searchQuery.trim().toLowerCase();
            final filteredUsers = allUsers.where((u) {
              // Role / Status filter
              if (_selectedFilter == 'admin' && !u.isAdmin) return false;
              if (_selectedFilter == 'member' && !u.isMember) return false;
              if (_selectedFilter == 'suspended' && !u.isSuspended) return false;

              // Text query filter
              if (q.isEmpty) return true;
              final name = u.displayName.toLowerCase();
              final email = (u.email ?? '').toLowerCase();
              return name.contains(q) || email.contains(q);
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: primaryTeal,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Panel & User Management',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: slateDark,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Manage team access permissions, role promotions, and account statuses',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: slateMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => ref
                                .read(usersDirectoryControllerProvider.notifier)
                                .refresh(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Refresh'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryTeal,
                              side: BorderSide(
                                  color: primaryTeal.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // System Metrics Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          final isMedium = constraints.maxWidth > 480;
                          final cardWidth = isWide
                              ? (constraints.maxWidth - 36) / 4
                              : isMedium
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth;

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildMetricCard(
                                title: 'Total Registered Users',
                                value: '$totalUsers',
                                icon: Icons.people_alt_rounded,
                                color: primaryTeal,
                                width: cardWidth,
                              ),
                              _buildMetricCard(
                                title: 'Administrators',
                                value: '$admins',
                                icon: Icons.admin_panel_settings_rounded,
                                color: const Color(0xFF0284C7),
                                width: cardWidth,
                              ),
                              _buildMetricCard(
                                title: 'Team Members',
                                value: '$members',
                                icon: Icons.badge_rounded,
                                color: const Color(0xFF475569),
                                width: cardWidth,
                              ),
                              _buildMetricCard(
                                title: 'Suspended Accounts',
                                value: '$suspended',
                                icon: Icons.block_rounded,
                                color: const Color(0xFFDC2626),
                                width: cardWidth,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // User Management Directory Card
                      Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Controls bar (Search + Filter Chips)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.supervised_user_circle_rounded,
                                        color: primaryTeal,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'User Directory',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: slateDark,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${filteredUsers.length}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: slateMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: TextField(
                                            onChanged: (val) {
                                              setState(() {
                                                _searchQuery = val;
                                              });
                                            },
                                            style: const TextStyle(fontSize: 14),
                                            decoration: InputDecoration(
                                              prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                size: 18,
                                                color: slateMuted,
                                              ),
                                              hintText:
                                                  'Search by name or email...',
                                              hintStyle: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade400,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _buildFilterChip('all', 'All Users ($totalUsers)'),
                                      _buildFilterChip('admin', 'Admins ($admins)'),
                                      _buildFilterChip('member', 'Members ($members)'),
                                      _buildFilterChip('suspended', 'Suspended ($suspended)'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // User List / Table
                            if (filteredUsers.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 48.0, horizontal: 24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_search_rounded,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No users found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: slateDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No user accounts match the current filter or search term.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredUsers.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  return _buildUserTile(user);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    const primaryTeal = Color(0xFF0F766E);
    final isSelected = _selectedFilter == filterKey;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterKey;
          });
        }
      },
      selectedColor: primaryTeal.withValues(alpha: 0.12),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? primaryTeal : const Color(0xFF475569),
      ),
      side: BorderSide(
        color: isSelected ? primaryTeal.withValues(alpha: 0.4) : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildUserTile(UserProfile user) {
    const primaryTeal = Color(0xFF0F766E);
    const slateDark = Color(0xFF0F172A);
    const slateMuted = Color(0xFF64748B);

    final isSuspended = user.isSuspended;
    final isAdmin = user.isAdmin;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isAdmin
            ? primaryTeal.withValues(alpha: 0.15)
            : const Color(0xFF0284C7).withValues(alpha: 0.15),
        child: Text(
          user.initials,
          style: TextStyle(
            color: isAdmin ? primaryTeal : const Color(0xFF0284C7),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                color: slateDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildRoleBadge(isAdmin),
          const SizedBox(width: 6),
          _buildStatusBadge(isSuspended),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          [
            if (user.email != null && user.email!.isNotEmpty) user.email!,
            if (user.createdAt != null)
              'Joined ${DateFormat('MMM d, yyyy').format(user.createdAt!)}',
          ].join(' • '),
          style: const TextStyle(
            fontSize: 12.5,
            color: slateMuted,
          ),
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: slateMuted, size: 20),
        tooltip: 'User Actions',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (action) => _handleUserAction(user, action),
        itemBuilder: (context) {
          final isMember =
              user.role.trim().toLowerCase() == 'member' || !user.isAdmin;
          final isAdmin = user.isAdmin;
          final isSuspended = user.isSuspended;

          return [
            if (isMember)
              const PopupMenuItem(
                value: 'promote',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        color: Color(0xFF0F766E), size: 18),
                    SizedBox(width: 10),
                    Text('Promote to Admin',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            if (isAdmin)
              const PopupMenuItem(
                value: 'demote',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded,
                        color: Color(0xFF475569), size: 18),
                    SizedBox(width: 10),
                    Text('Demote to Member',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            if (!isSuspended)
              const PopupMenuItem(
                value: 'suspend',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 10),
                    Text('Suspend Account',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDC2626),
                        )),
                  ],
                ),
              )
            else
              const PopupMenuItem(
                value: 'activate',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 10),
                    Text('Activate Account',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF16A34A),
                        )),
                  ],
                ),
              ),
          ];
        },
      ),
    );
  }

  Widget _buildRoleBadge(bool isAdmin) {
    const primaryTeal = Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? primaryTeal.withValues(alpha: 0.1)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAdmin
              ? primaryTeal.withValues(alpha: 0.25)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.shield_rounded : Icons.person_rounded,
            size: 11,
            color: isAdmin ? primaryTeal : const Color(0xFF475569),
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'Admin' : 'Member',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAdmin ? primaryTeal : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isSuspended) {
    final color = isSuspended ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final text = isSuspended ? 'Suspended' : 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _handleUserAction(UserProfile user, String action) async {
    final notifier = ref.read(usersDirectoryControllerProvider.notifier);

    if (action == 'promote') {
      try {
        await notifier.updateUserRole(user.id, 'admin');
        if (!mounted) return;
        _showSuccessSnackBar('Promoted ${user.displayName} to Administrator');
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('Failed to promote user: $e');
      }
    } else if (action == 'demote') {
      final confirmed = await _confirmAction(
        title: 'Demote Administrator?',
        message:
            'Are you sure you want to demote ${user.displayName} to Team Member? They will lose access to administrative settings.',
        actionLabel: 'Demote',
        isDestructive: true,
      );
      if (confirmed == true) {
        try {
          await notifier.updateUserRole(user.id, 'member');
          if (!mounted) return;
          _showSuccessSnackBar('Demoted ${user.displayName} to Member');
        } catch (e) {
          if (!mounted) return;
          _showErrorSnackBar('Failed to demote user: $e');
        }
      }
    } else if (action == 'suspend') {
      final confirmed = await _confirmAction(
        title: 'Suspend Account?',
        message:
            'Are you sure you want to suspend ${user.displayName}? They will be blocked from accessing CRM activities until re-activated.',
        actionLabel: 'Suspend',
        isDestructive: true,
      );
      if (confirmed == true) {
        try {
          await notifier.updateUserStatus(user.id, 'suspended');
          if (!mounted) return;
          _showSuccessSnackBar('Suspended account for ${user.displayName}');
        } catch (e) {
          if (!mounted) return;
          _showErrorSnackBar('Failed to suspend user: $e');
        }
      }
    } else if (action == 'activate') {
      try {
        await notifier.updateUserStatus(user.id, 'active');
        if (!mounted) return;
        _showSuccessSnackBar('Activated account for ${user.displayName}');
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('Failed to activate user: $e');
      }
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF0F766E),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
