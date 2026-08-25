import 'package:flutter/widgets.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/services/notification_badge_service.dart';
import 'package:proving_tool/services/sync_service.dart';
import 'package:proving_tool/services/trial_repository.dart';

/// Gives every screen access to the app's singleton services
/// ([TrialRepository], [SyncService], [ConnectivityService],
/// [NotificationBadgeService]) without threading them through
/// constructors or adding a state-management package. Installed once
/// near the root in `main.dart`.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.trialRepository,
    required this.syncService,
    required this.connectivity,
    required this.notificationBadge,
    required super.child,
  });

  final TrialRepository trialRepository;
  final SyncService syncService;
  final ConnectivityService connectivity;
  final NotificationBadgeService notificationBadge;

  static AppServices of(BuildContext context) {
    final services =
        context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(services != null, 'No AppServices found above this context');
    return services!;
  }

  @override
  bool updateShouldNotify(AppServices oldWidget) => false;
}
