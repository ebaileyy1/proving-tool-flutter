import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/utils/ui_helpers.dart';
import 'package:proving_tool/widgets/app_header.dart';
import 'package:proving_tool/widgets/confirm_dialog.dart';
import 'package:proving_tool/widgets/empty_state.dart';
import 'package:proving_tool/widgets/offline_state.dart';
import 'package:proving_tool/widgets/stat_card.dart';
import 'package:proving_tool/widgets/status_badge.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _supabase = Supabase.instance.client;
  late final ConnectivityService _connectivity;
  bool _initialized = false;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _connectivity = AppServices.of(context).connectivity;
      _checkAdminAndLoad();
    }
  }

  Future<void> _checkAdminAndLoad() async {
    if (!_connectivity.isOnline.value) {
      setState(() {
        _isOffline = true;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isOffline = false;
      _isLoading = true;
    });
    try {
      final userId = _supabase.auth.currentUser!.id;
      final profile = await _supabase.from('profiles').select('is_admin').eq('id', userId);

      if (profile.isEmpty || profile[0]['is_admin'] != true) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
        return;
      }

      setState(() => _isAdmin = true);
      await _loadUsers();
    } catch (e) {
      logError('Error checking admin', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: true);
      setState(() => _users = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      logError('Error loading users', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdmin(Map<String, dynamic> user) async {
    final currentValue = user['is_admin'] == true;
    final confirm = await confirmDialog(
      context,
      title: currentValue ? 'Remove Admin' : 'Make Admin',
      message: currentValue
          ? 'Remove admin privileges from ${user['username']}?'
          : 'Give admin privileges to ${user['username']}?',
      confirmLabel: currentValue ? 'Remove' : 'Make Admin',
      destructive: false,
    );

    if (confirm) {
      try {
        await _supabase.from('profiles').update({'is_admin': !currentValue}).eq('id', user['id']);
        _loadUsers();
      } catch (e) {
        logError('Error updating admin', e);
        if (mounted) showMessage(context, 'Error updating user: $e');
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final currentUserId = _supabase.auth.currentUser!.id;
    if (user['id'] == currentUserId) {
      showMessage(context, 'You cannot delete your own account');
      return;
    }

    final confirm = await confirmDialog(
      context,
      title: 'Delete User',
      message:
          'Are you sure you want to delete ${user['username']}? '
          'They will no longer be able to log in.',
      confirmLabel: 'Delete',
    );

    if (confirm) {
      try {
        await _supabase.from('profiles').delete().eq('id', user['id']);

        setState(() => _users.removeWhere((u) => u['id'] == user['id']));

        if (mounted) {
          showMessage(context, '${user['username']} has been removed');
        }
      } catch (e) {
        logError('Error deleting user', e);
        if (mounted) showMessage(context, 'Error deleting user: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isOffline
          ? OfflineState(onRetry: _checkAdminAndLoad)
          : !_isAdmin
          ? const EmptyState(
              icon: Icons.lock,
              title: 'Access Denied',
              message: 'You do not have admin privileges.',
            )
          : _adminContent(),
    );
  }

  AppHeader _appBar() {
    return AppHeader(
      title: 'Admin Panel',
      actions: [
        HeaderIconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _checkAdminAndLoad,
        ),
      ],
    );
  }

  Widget _adminContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryCardsRow(),

              const SizedBox(height: 24),

              const Text('Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _usersTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCardsRow() {
    final adminCount = _users.where((u) => u['is_admin'] == true).length;
    final userCount = _users.where((u) => u['is_admin'] != true).length;
    return Row(
      children: [
        StatCard(label: 'Total Users', value: _users.length.toString(), color: AppColors.lightNavy),
        const SizedBox(width: 12),
        StatCard(label: 'Admins', value: adminCount.toString(), color: AppColors.warning),
        const SizedBox(width: 12),
        StatCard(label: 'Regular Users', value: userCount.toString(), color: AppColors.accent),
      ],
    );
  }

  Widget _usersTable() {
    return Card(
      child: _users.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No users found')),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.subBackground),
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 52,
                    columns: [
                      for (final label in const ['Username', 'Role', 'Joined', 'Actions'])
                        DataColumn(
                          label: Expanded(
                            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                    rows: _users.map(_userRow).toList(),
                  ),
                );
              },
            ),
    );
  }

  DataRow _userRow(Map<String, dynamic> user) {
    final currentUserId = _supabase.auth.currentUser!.id;
    final isCurrentUser = user['id'] == currentUserId;
    final isAdmin = user['is_admin'] == true;
    return DataRow(
      color: WidgetStateProperty.all(
        isCurrentUser ? AppColors.accent.withValues(alpha: 0.06) : null,
      ),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user['username']?.toString() ?? '-'),
              if (isCurrentUser) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('You', style: TextStyle(fontSize: 10, color: AppColors.accent)),
                ),
              ],
            ],
          ),
        ),
        DataCell(
          ColorPill(
            label: isAdmin ? 'Admin' : 'User',
            color: isAdmin ? AppColors.warning : AppColors.accent,
            dense: true,
          ),
        ),
        DataCell(
          Text(
            user['created_at']?.toString().split('T')[0] ?? '-',
            style: const TextStyle(color: AppColors.otherText),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isAdmin ? Icons.star : Icons.star_border,
                  color: isAdmin ? AppColors.warning : AppColors.otherText,
                  size: 20,
                ),
                tooltip: isAdmin ? 'Remove admin' : 'Make admin',
                onPressed: isCurrentUser ? null : () => _toggleAdmin(user),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                tooltip: 'Delete user',
                onPressed: isCurrentUser ? null : () => _deleteUser(user),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
