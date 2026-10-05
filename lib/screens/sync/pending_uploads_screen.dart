import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/local_db.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/empty_state.dart';
import 'package:proving_tool/widgets/status_badge.dart';

/// Everything still queued for sync, with retry/discard for stuck items.
class PendingUploadsScreen extends StatelessWidget {
  const PendingUploadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    final repo = services.trialRepository;
    final db = repo.db;

    return Scaffold(
      appBar: AppHeader(
        title: 'Pending Uploads',
        actions: [
          HeaderIconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Retry now',
            onPressed: () => services.syncService.syncNow(manual: true),
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<SyncSummary>(
            valueListenable: repo.syncSummary,
            builder: (context, summary, _) {
              if (summary.lastSyncedAt == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Last synced ${_relativeTime(summary.lastSyncedAt!)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.otherText),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<PendingTrial>>(
              stream: db.select(db.pendingTrials).watch(),
              builder: (context, trialsSnapshot) {
                final trials = trialsSnapshot.data ?? const <PendingTrial>[];
                return StreamBuilder<List<PendingFile>>(
                  stream: db.select(db.pendingFiles).watch(),
                  builder: (context, filesSnapshot) {
                    final files = filesSnapshot.data ?? const <PendingFile>[];

                    if (trials.isEmpty && files.isEmpty) {
                      return const EmptyState(
                        icon: Icons.cloud_done,
                        title: 'Nothing queued',
                        message: 'Everything you\'ve created or edited has synced.',
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (trials.isNotEmpty) ...[
                          const _SectionLabel('Trials'),
                          const SizedBox(height: 8),
                          for (final trial in trials) _PendingTrialTile(trial: trial, repo: repo),
                          const SizedBox(height: 20),
                        ],
                        if (files.isNotEmpty) ...[
                          const _SectionLabel('Files'),
                          const SizedBox(height: 8),
                          for (final file in files) _PendingFileTile(file: file, repo: repo),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} d ago';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.otherText,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      SyncStatus.syncing => (AppColors.lightNavy, 'Syncing'),
      SyncStatus.error => (AppColors.error, 'Failed'),
      _ => (AppColors.warning, 'Queued'),
    };
    return ColorPill(label: label, color: color, dense: true);
  }
}

class _PendingTrialTile extends StatelessWidget {
  const _PendingTrialTile({required this.trial, required this.repo});

  final PendingTrial trial;
  final TrialRepository repo;

  @override
  Widget build(BuildContext context) {
    final fields = Map<String, dynamic>.from(jsonDecode(trial.payloadJson) as Map);
    final name = fields['fullname']?.toString().trim();
    final isCreate = trial.operation == 'create';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name?.isNotEmpty == true ? name! : 'Untitled trial'),
        subtitle: Text(
          trial.hasSyncError && trial.errorMessage != null
              ? trial.errorMessage!
              : isCreate
              ? 'New trial - not yet on the server'
              : 'Edit queued for an existing trial',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: _StatusBadge(status: trial.syncStatus),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: AppColors.error),
          tooltip: isCreate ? 'Discard trial' : 'Discard changes',
          onPressed: () => repo.deleteLocalPendingTrial(trial.localId),
        ),
      ),
    );
  }
}

extension on PendingTrial {
  bool get hasSyncError => syncStatus == SyncStatus.error;
}

class _PendingFileTile extends StatelessWidget {
  const _PendingFileTile({required this.file, required this.repo});

  final PendingFile file;
  final TrialRepository repo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          fileEmojiForExtension(extensionOf(file.originalName)),
          style: const TextStyle(fontSize: 20),
        ),
        title: Text(file.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          file.uploadStatus == SyncStatus.error && file.errorMessage != null
              ? file.errorMessage!
              : '${file.category == 'drawing' ? 'Drawing' : 'Evidence'} · ${(file.fileSizeBytes / 1024).toStringAsFixed(0)} KB',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(status: file.uploadStatus),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              tooltip: 'Discard file',
              onPressed: () => repo.discardPendingFile(file.id),
            ),
          ],
        ),
      ),
    );
  }
}
