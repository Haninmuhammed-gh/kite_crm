import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/auth_repository.dart';
import '../controllers/auth_controller.dart';

class UserAvatarButton extends ConsumerWidget {
  const UserAvatarButton({
    super.key,
    this.radius = 16.0,
  });

  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile = profileAsync.value;
    final user = ref.watch(authRepositoryProvider).currentUser;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final String initials;
    if (profile != null) {
      initials = profile.initials;
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      initials = user.email![0].toUpperCase();
    } else {
      initials = 'U';
    }

    final tooltipText = profile?.displayName ?? user?.email ?? 'My Profile';

    return Tooltip(
      message: 'My Profile ($tooltipText)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius + 6),
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: primaryColor.withValues(alpha: 0.12),
              child: Text(
                initials,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.75,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
