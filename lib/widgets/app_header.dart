import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/admin/admin_screen.dart';
import 'package:proving_tool/screens/notifications/notifications_screen.dart';
import 'package:proving_tool/screens/profile/profile_screen.dart';
import 'package:proving_tool/screens/sync/pending_uploads_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// Page header for logged-in screens: a global row (notifications, sync,
/// account menu) above a navy title band. Use it as the Scaffold's `appBar`.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, required this.title, this.statusChip, this.actions = const []});

  final String title;
  final Widget? statusChip;
  final List<Widget> actions;

  static const _globalRowHeight = 34.0;
  static const _titleRowHeight = 62.0;
  static const _accentBarHeight = 3.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_globalRowHeight + _titleRowHeight + _accentBarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Material(
      color: AppColors.navy,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.accent, width: _accentBarHeight),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: _globalRowHeight, child: _GlobalRow()),
              SizedBox(
                height: _titleRowHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
                  child: Row(
                    children: [
                      if (canPop)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 20,
                        )
                      else
                        const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (statusChip != null) ...[const SizedBox(width: 10), statusChip!],
                          ],
                        ),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          actions[i],
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action button for [AppHeader]'s title row. [icon] is a widget so callers
/// can swap in a spinner.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: IconTheme(
              data: const IconThemeData(color: Colors.white, size: 19),
              child: icon,
            ),
          ),
        ),
      ),
    );
    final result = onPressed == null ? Opacity(opacity: 0.4, child: button) : button;
    return tooltip == null ? result : Tooltip(message: tooltip!, child: result);
  }
}

class _GlobalRow extends StatelessWidget {
  const _GlobalRow();

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final supabase = Supabase.instance.client;
    final email = supabase.auth.currentUser?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    Future<void> open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'PROVE IT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<int>(
            valueListenable: services.notificationBadge.unreadCount,
            builder: (context, unread, _) => _SmallIconButton(
              icon: Icons.notifications,
              badgeColor: unread > 0 ? AppColors.error : null,
              onPressed: () async {
                await open(const NotificationsScreen());
                services.notificationBadge.refresh();
              },
            ),
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder<SyncSummary>(
            valueListenable: services.trialRepository.syncSummary,
            builder: (context, summary, _) => _SmallIconButton(
              icon: Icons.cloud_sync,
              badgeColor: summary.totalQueued > 0
                  ? (summary.hasErrors ? AppColors.error : AppColors.warning)
                  : null,
              onPressed: () => open(const PendingUploadsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<_AccountAction>(
            tooltip: 'Account',
            offset: const Offset(0, 34),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (action) async {
              if (action == _AccountAction.profile) {
                open(const ProfileScreen());
              } else if (action == _AccountAction.admin) {
                open(const AdminScreen());
              } else if (action == _AccountAction.logout) {
                await supabase.auth.signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccountAction.profile,
                child: _MenuRow(icon: Icons.person, label: 'Profile'),
              ),
              PopupMenuItem(
                value: _AccountAction.admin,
                child: _MenuRow(icon: Icons.admin_panel_settings, label: 'Admin panel'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _AccountAction.logout,
                child: _MenuRow(icon: Icons.logout, label: 'Log out', color: AppColors.error),
              ),
            ],
            child: CircleAvatar(
              radius: 11,
              backgroundColor: Colors.white24,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccountAction { profile, admin, logout }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.navy),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color ?? AppColors.navy)),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onPressed, this.badgeColor});

  final IconData icon;
  final VoidCallback onPressed;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              if (badgeColor != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.navy, width: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
