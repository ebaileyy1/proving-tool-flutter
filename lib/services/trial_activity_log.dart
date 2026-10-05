import 'package:proving_tool/utils/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes audit rows to `log_of_activity` once a trial write reaches the
/// server. Failures are swallowed so an audit write never fails a save.
class TrialActivityLog {
  TrialActivityLog._();

  static Future<void> record({
    required SupabaseClient supabase,
    required int topicId,
    required String actionCompleted,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      await supabase.from('log_of_activity').insert({
        'topic_id': topicId,
        'user_id': userId,
        'action_completed': actionCompleted,
        'logged_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      logError('Error recording trial activity', e);
    }
  }

  static Future<void> logCreated({
    required SupabaseClient supabase,
    required int topicId,
    required Map<String, dynamic> fields,
  }) {
    return record(
      supabase: supabase,
      topicId: topicId,
      actionCompleted: 'Created trial - Status: ${fields['status_of_trial'] ?? 'Pending'}',
    );
  }

  /// Logs the new status, not a diff. Pass [action] for a more specific line.
  static Future<void> logUpdated({
    required SupabaseClient supabase,
    required int topicId,
    required Map<String, dynamic> fields,
    String? action,
  }) {
    final status = fields['status_of_trial'];
    return record(
      supabase: supabase,
      topicId: topicId,
      actionCompleted:
          action ?? (status != null ? 'Updated trial - Status: $status' : 'Updated trial'),
    );
  }
}
