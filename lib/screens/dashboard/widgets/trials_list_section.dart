import 'package:flutter/material.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/widgets/pending_sync_chip.dart';
import 'package:proving_tool/widgets/status_badge.dart';

class TrialsListSection extends StatelessWidget {
  final List<TrialListItem> items;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<TrialListItem> onOpen;

  const TrialsListSection({
    super.key,
    required this.items,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search trials by name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.clear), onPressed: onSearchCleared),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        items.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'No trials match the selected filters'
                          : 'No trials match "$searchQuery"',
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final trial = item.data;
                  final status = trial['status_of_trial']?.toString() ?? 'Pending';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        trial['fullname']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${trial['type_of_trial'] ?? ''} · ${trial['terminal_of_trial'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge(status: status, dense: true),
                          if (item.isPending) ...[
                            const SizedBox(width: 8),
                            PendingSyncChip(hasError: item.hasSyncError),
                          ],
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => onOpen(item),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
