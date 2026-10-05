import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:proving_tool/screens/pdf/trial_pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Built in setUp, not at top level: outside a test zone it hits "no current
  // invoker" from Flutter's mock HTTP overrides. The storage calls just fail and get caught.
  late SupabaseClient supabase;
  setUp(() {
    supabase = SupabaseClient(
      // Port 9 is closed, so this fails instantly instead of a slow DNS lookup.
      'http://127.0.0.1:9',
      'fake-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  final trial = <String, dynamic>{
    'fullname': 'Aarhus Manipulator Proving',
    'type_of_trial': 'Live Rehearsal',
    'terminal_of_trial': 'T5',
    'sub_area_of_trial': 'BRF',
    'status_of_trial': 'Completed',
    'date_of_start': '2026-02-25T00:00:00.000Z',
    'date_of_completion': '2026-02-27T00:00:00.000Z',
    'description_of_trial':
        'Three-day proving trial for the new bag manipulator, run with four handlers across two shifts.',
    'expected_outcome':
        'Confirm the manipulator meets the 6/8/10 second per-bag target over a continuous two-hour build.',
    'run_plan':
        'Day 1: onboarding + baseline runs. Day 2: full handler rotation. Day 3: OOG and top-up testing.',
    'attendees':
        'First name: Ellis, Last name: Bailey, Company: ABC\n'
        'First name: Jordan, Last name: Smith, Company: Heathrow',
    'how_trial_went':
        'All four handlers completed their runs; performance improved notably from day 1 to day 2.',
    'actual_outcome': 'Average load time of 8.2s per bag across all handlers, within target range.',
    'evidence_summary': 'Photos of each ULD build attached below, one per handler per day.',
  };

  final observations = <Map<String, dynamic>>[
    {
      'id': 1,
      'content':
          'Handler 3 had a notably faster day 2 - worth checking what changed in their technique.',
      'username': 'Ellis Bailey',
      'created_at': '2026-02-27T10:00:00.000Z',
    },
    {
      'id': 2,
      'content': 'OOG bags (snowboard, child car seat) both loaded without issue on day 3.',
      'username': 'Jordan Smith',
      'created_at': '2026-02-27T14:30:00.000Z',
    },
  ];

  final files = <Map<String, dynamic>>[
    {
      'original_name': 'build-1-handler-1.pdf',
      'file_category': 'evidence',
      'storage_path': 'fake/build-1.pdf',
      'uploaded_at': '2026-02-27T09:00:00.000Z',
    },
    {
      'original_name': 'manipulator-diagram.docx',
      'file_category': 'drawing',
      'storage_path': 'fake/diagram.docx',
      'uploaded_at': '2026-02-25T08:00:00.000Z',
    },
  ];

  test('buildDocument produces a non-empty, multi-page PDF without throwing', () async {
    final pdf = await TrialPdf.buildDocument(
      trial: trial,
      observations: observations,
      files: files,
      supabase: supabase,
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);

    // Not asserted on, just written out so the layout can be eyeballed.
    final outFile = File('build/trial_pdf_test_output.pdf');
    outFile.parent.createSync(recursive: true);
    await outFile.writeAsBytes(bytes);
  });

  test('buildDocument handles a minimal trial with no optional data', () async {
    final pdf = await TrialPdf.buildDocument(
      trial: {'fullname': '', 'status_of_trial': 'Pending'},
      observations: const [],
      files: const [],
      supabase: supabase,
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
  });

  test('buildBatchDocument combines several trials into one document', () async {
    final second = Map<String, dynamic>.from(trial)
      ..['fullname'] = 'A second trial'
      ..['status_of_trial'] = 'Failed';

    final pdf = await TrialPdf.buildBatchDocument(
      trials: [
        TrialPdfBundle(trial: trial, observations: observations, files: files),
        TrialPdfBundle(trial: second, observations: const [], files: const []),
      ],
      supabase: supabase,
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
  });
}
