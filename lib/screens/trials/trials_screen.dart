import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/models/trial.dart';
import 'package:proving_tool/screens/trials/add_trial_screen.dart';
import 'package:proving_tool/screens/trials/view_trial_screen.dart';
import 'package:proving_tool/screens/dashboard/dashboard_screen.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/widgets/pending_sync_chip.dart';

class TrialsScreen extends StatefulWidget {
  const TrialsScreen({super.key});

  @override
  State<TrialsScreen> createState() => _TrialsScreenState();
}

class _TrialsScreenState extends State<TrialsScreen> {
  late final TrialRepository _repo;
  bool _initialized = false;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _repo = AppServices.of(context).trialRepository;
      _repo.refresh().whenComplete(() {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TrialListItem> _filter(List<TrialListItem> items) {
    if (_searchQuery.isEmpty) return items;
    final query = _searchQuery.toLowerCase();
    return items
        .where((item) => (item.data['fullname']?.toString() ?? '')
            .toLowerCase()
            .contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search trials by name',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<List<TrialListItem>>(
                    valueListenable: _repo.trials,
                    builder: (context, allItems, _) {
                      final items = _filter(allItems);
                      return RefreshIndicator(
                        onRefresh: _repo.refresh,
                        child: items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 120),
                                    child: Center(
                                      child: Text(
                                        allItems.isEmpty
                                            ? 'No trials yet. Add one!'
                                            : 'No trials match "$_searchQuery"',
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final trial = item.data;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      title: Text(
                                        trial['fullname'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        trial['status_of_trial'] ?? 'No status',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (item.isPending) ...[
                                            PendingSyncChip(hasError: item.hasSyncError),
                                            const SizedBox(width: 8),
                                          ],
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                      onTap: () async {
                                        final result = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ViewTrialScreen(item: item),
                                          ),
                                        );
                                        if (result == true) _repo.refresh();
                                      },
                                    ),
                                  );
                                },
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTrialScreen()),
          );
          if (result == true) _repo.refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
