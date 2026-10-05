import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/services/connectivity_service.dart';
import 'package:proving_tool/services/local_db.dart';
import 'package:proving_tool/services/notification_badge_service.dart';
import 'package:proving_tool/services/sync_service.dart';
import 'package:proving_tool/services/trial_repository.dart';
import 'package:proving_tool/widgets/trial_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Real AppServices over an in-memory db and a SupabaseClient that's never called.
Widget _wrapped(Widget child) {
  final db = LocalDb.forTesting();
  final supabase = SupabaseClient(
    'https://example.invalid',
    'fake-anon-key',
    // autoRefreshToken off, otherwise its timer trips the pending-timers check
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final connectivity = ConnectivityService.instance;
  final repo = TrialRepository(supabase: supabase, db: db, connectivity: connectivity);
  final sync = SyncService(
    supabase: supabase,
    db: db,
    connectivity: connectivity,
    trialRepository: repo,
  );
  final notifications = NotificationBadgeService(supabase);

  return MaterialApp(
    home: AppServices(
      trialRepository: repo,
      syncService: sync,
      connectivity: connectivity,
      notificationBadge: notifications,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  // each test builds its own LocalDb.forTesting(); silence drift's multiple-database warning
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('TrialFormFields renders without throwing (Add-style, blank controller)', (
    tester,
  ) async {
    final controller = TrialFormController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrapped(TrialFormFields(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Trial Name'), findsOneWidget);
    expect(find.text('Sub-Area'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TrialFormFields renders without throwing (Edit-style, pre-filled controller)', (
    tester,
  ) async {
    final controller = TrialFormController.fromExisting({
      'fullname': 'A trial',
      'type_of_trial': 'Desktop',
      'terminal_of_trial': 'T3',
      'sub_area_of_trial': 'BRF',
      'status_of_trial': 'Completed',
      'date_of_start': '2026-02-25T00:00:00.000Z',
    });
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrapped(TrialFormFields(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('A trial'), findsOneWidget);
    expect(find.text('BRF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Typing in the Sub-Area field does not throw', (tester) async {
    final controller = TrialFormController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrapped(TrialFormFields(controller: controller)));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Sub-Area'), 'BRF');
    await tester.pumpAndSettle();

    expect(controller.subArea.text, 'BRF');
    expect(tester.takeException(), isNull);
  });
}
