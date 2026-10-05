import 'package:flutter/material.dart';
import 'package:proving_tool/screens/trials/view_trial/trial_tab_scroll.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/file_types.dart';
import 'package:proving_tool/widgets/section_card.dart';
import 'package:proving_tool/widgets/section_header.dart';

class TrialFileActions {
  final void Function(String category) onUpload;
  final void Function(Map<String, dynamic> file) onDownload;
  final void Function(List<Map<String, dynamic>> files) onDownloadAll;

  const TrialFileActions({
    required this.onUpload,
    required this.onDownload,
    required this.onDownloadAll,
  });
}

class FilesTab extends StatelessWidget {
  final List<Map<String, dynamic>> drawings;
  final List<Map<String, dynamic>> evidenceFiles;
  final bool isPostTrial;
  final bool isPendingLocal;
  final bool isOwnerOrAdmin;
  final bool isUploadingDrawing;
  final bool isUploadingEvidence;
  final bool isDownloadingAll;
  final TrialFileActions actions;

  const FilesTab({
    super.key,
    required this.drawings,
    required this.evidenceFiles,
    required this.isPostTrial,
    required this.isPendingLocal,
    required this.isOwnerOrAdmin,
    required this.isUploadingDrawing,
    required this.isUploadingEvidence,
    required this.isDownloadingAll,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return TrialTabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilesCard(
            title: 'Drawings',
            files: drawings,
            category: 'drawing',
            isUploading: isUploadingDrawing,
            isPendingLocal: isPendingLocal,
            isOwnerOrAdmin: isOwnerOrAdmin,
            isDownloadingAll: isDownloadingAll,
            actions: actions,
          ),
          if (isPostTrial) ...[
            const SizedBox(height: 16),
            FilesCard(
              title: 'Evidence Files',
              files: evidenceFiles,
              category: 'evidence',
              isUploading: isUploadingEvidence,
              isPendingLocal: isPendingLocal,
              isOwnerOrAdmin: isOwnerOrAdmin,
              isDownloadingAll: isDownloadingAll,
              actions: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class FilesCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> files;
  final String category;
  final bool isUploading;
  final bool isPendingLocal;
  final bool isOwnerOrAdmin;
  final bool isDownloadingAll;
  final TrialFileActions actions;

  const FilesCard({
    super.key,
    required this.title,
    required this.files,
    required this.category,
    required this.isUploading,
    required this.isPendingLocal,
    required this.isOwnerOrAdmin,
    required this.isDownloadingAll,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionHeader(title),
            Row(
              children: [
                if (files.isNotEmpty && !isPendingLocal)
                  TextButton.icon(
                    onPressed: isDownloadingAll ? null : () => actions.onDownloadAll(files),
                    icon: isDownloadingAll
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_for_offline),
                    label: Text(isDownloadingAll ? 'Downloading...' : 'Download all'),
                  ),
                if (isOwnerOrAdmin) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : () => actions.onUpload(category),
                    icon: isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(isUploading ? 'Uploading...' : 'Upload'),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        files.isEmpty
            ? Text(
                'No ${category == 'drawing' ? 'drawings' : 'evidence files'} uploaded yet.',
                style: const TextStyle(color: AppColors.otherText),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final extension = file['original_name']?.toString().split('.').last;
                  return ListTile(
                    leading: Text(
                      fileEmojiForExtension(extension),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(file['original_name']?.toString() ?? ''),
                    subtitle: Text(
                      isPendingLocal
                          ? "Queued - will upload when you're back online"
                          : file['uploaded_at']?.toString().split('T')[0] ?? '',
                    ),
                    trailing: isPendingLocal
                        ? const Tooltip(
                            message: 'Not uploaded yet',
                            child: Icon(Icons.hourglass_top, size: 18, color: AppColors.otherText),
                          )
                        : IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => actions.onDownload(file),
                          ),
                  );
                },
              ),
      ],
    );
  }
}
