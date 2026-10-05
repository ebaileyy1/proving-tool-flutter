import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/utils/log.dart';

/// Unread notification count, shared so the header badge works on every screen.
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
