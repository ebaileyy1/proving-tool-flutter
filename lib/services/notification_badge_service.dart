import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/utils/log.dart';

/// Tracks the current user's unread notification count so the header can
/// show a badge on every screen, not just the one screen that happens to
/// have loaded it. Previously this was local state inside the Dashboard
/// screen alone.
class NotificationBadgeService {
  NotificationBadgeService(this._supabase);

  final SupabaseClient _supabase;

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<void> refresh() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);
      unreadCount.value = (response as List).length;
    } catch (e) {
      logError('Error loading unread count', e);
    }
  }
}
