import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:proving_tool/widgets/offline_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  late final ConnectivityService _connectivity;
  bool _initialized = false;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _connectivity = AppServices.of(context).connectivity;
      _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
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
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);
      setState(() => _notifications = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      logError('Error loading notifications', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_read', false);
      _loadNotifications();
    } catch (e) {
      logError('Error marking all read', e);
    }
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notification['id']);
      _loadNotifications();
    } catch (e) {
      logError('Error marking read', e);
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notification['id']);
      setState(() => _notifications.removeWhere((n) => n['id'] == notification['id']));
    } catch (e) {
      logError('Error deleting notification', e);
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase
            .from('notifications')
            .delete()
            .eq('user_id', _supabase.auth.currentUser!.id);
        setState(() => _notifications.clear());
      } catch (e) {
        logError('Error clearing notifications', e);
      }
    }
  }

  IconData _getIcon(String title) {
    if (title.contains('reply') || title.contains('Reply')) return Icons.reply;
    if (title.contains('observation') || title.contains('Observation')) return Icons.comment;
    if (title.contains('edited') || title.contains('Edit')) return Icons.edit;
    if (title.contains('deleted') || title.contains('Delete')) return Icons.delete;
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isOffline
              ? OfflineState(onRetry: _loadNotifications)
              : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: AppColors.otherText),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You\'ll be notified when someone replies\nto your observations or updates your trials.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.otherText),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['is_read'] == true;

                    return Dismissible(
                      key: Key(notification['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteNotification(notification),
                      child: Card(
                        color: isRead ? null : const Color(0xFFEFF6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isRead ? AppColors.border : AppColors.lightNavy,
                            width: isRead ? 1 : 1.5,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isRead
                                  ? AppColors.subBackground
                                  : AppColors.lightNavy.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIcon(notification['title']?.toString() ?? ''),
                              size: 20,
                              color: isRead ? AppColors.otherText : AppColors.lightNavy,
                            ),
                          ),
                          title: Text(
                            notification['title']?.toString() ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                notification['body']?.toString() ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['created_at']?.toString().split('T')[0] ?? '',
                                style: const TextStyle(fontSize: 11, color: AppColors.otherText),
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.lightNavy,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () => _markRead(notification),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}