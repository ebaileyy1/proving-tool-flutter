import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:proving_tool/utils/log.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  static Future<void> send({
    required String userId,
    required String title,
    required String body,
    int? topicId,
  }) async {
    try {
      // Don't notify yourself
      if (userId == _supabase.auth.currentUser!.id) return;

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'topic_id': topicId,
        'is_read': false,
      });
    } catch (e) {
      logError('Error sending notification', e);
    }
  }
}