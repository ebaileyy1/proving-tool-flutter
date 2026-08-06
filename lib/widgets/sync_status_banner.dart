import 'dart:async';

import 'package:flutter/material.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/sync/pending_uploads_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/theme/app_colors.dart';

enum _BannerState { offline, syncing, justSynced }

/// Slim, animated bar shown above the app whenever there's something to
/// tell the user about connectivity/sync: offline, actively syncing, or a
/// brief "all changes synced" confirmation. Collapses to nothing the rest
/// of the time. Wraps the authenticated part of the app once in `main.dart`
/// so no individual screen needs to know about it.
class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  Timer? _dismissTimer;
  bool _showJustSynced = false;
  DateTime? _lastSeenSyncedAt;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        services.connectivity.isOnline,
        services.trialRepository.syncSummary,
      ]),
      builder: (context, _) {
        final state = _resolveState(
          isOnline: services.connectivity.isOnline.value,
          summary: services.trialRepository.syncSummary.value,
        );

        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: state == null
                    ? const SizedBox(key: ValueKey('hidden'), width: double.infinity)
                    : _Bar(
                        key: ValueKey(state),
                        state: state,
                        summary: services.trialRepository.syncSummary.value,
                      ),
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }

  _BannerState? _resolveState({
    required bool isOnline,
    required SyncSummary summary,
  }) {
    if (!isOnline) {
      _showJustSynced = false;
      _dismissTimer?.cancel();
      return _BannerState.offline;
    }

    if (summary.hasWork) {
      _showJustSynced = false;
      _dismissTimer?.cancel();
      return _BannerState.syncing;
    }

    if (summary.lastSyncedAt != null &&
        summary.lastSyncedAt != _lastSeenSyncedAt) {
      _lastSeenSyncedAt = summary.lastSyncedAt;
      _showJustSynced = true;
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showJustSynced = false);
      });
    }

    return _showJustSynced ? _BannerState.justSynced : null;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({super.key, required this.state, required this.summary});

  final _BannerState state;
  final SyncSummary summary;

  @override
  Widget build(BuildContext context) {
    final config = switch (state) {
      _BannerState.offline => _BarConfig(
        background: AppColors.otherText,
        icon: Icons.cloud_off,
        label:
            "Offline — changes will be saved and sent when you're back online",
      ),
      _BannerState.syncing => _BarConfig(
        background: AppColors.navy,
        icon: Icons.sync,
        label: summary.totalQueued <= 1
            ? 'Syncing 1 item…'
            : 'Syncing ${summary.totalQueued} items…',
        showProgress: true,
      ),
      _BannerState.justSynced => const _BarConfig(
        background: AppColors.success,
        icon: Icons.cloud_done,
        label: 'All changes synced',
      ),
    };

    return SafeArea(
      bottom: false,
      child: Material(
        color: config.background,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PendingUploadsScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(config.icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (config.showProgress)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarConfig {
  const _BarConfig({
    required this.background,
    required this.icon,
    required this.label,
    this.showProgress = false,
  });

  final Color background;
  final IconData icon;
  final String label;
  final bool showProgress;
}
