import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:proving_tool/screens/pdf/trial_pdf_style.dart';
import 'package:proving_tool/screens/pdf/trial_pdf_widgets.dart';
import 'package:proving_tool/utils/log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// trial-files is a private bucket, so file links in the PDF are signed URLs.
// 7 days is long enough to review and share after export without leaving a permanent link.
const _fileLinkValidity = Duration(days: 7);

/// One trial's inputs for [TrialPdf.buildBatchDocument].
class TrialPdfBundle {
  const TrialPdfBundle({required this.trial, required this.observations, required this.files});

  final Map<String, dynamic> trial;
  final List<Map<String, dynamic>> observations;
  final List<Map<String, dynamic>> files;
}

/// Builds the landscape trial report PDF: a cover page, then one page per
/// section. Empty sections are skipped.
class TrialPdf {
  static Future<void> generate({
    required Map<String, dynamic> trial,
    required List<Map<String, dynamic>> observations,
    required List<Map<String, dynamic>> files,
    required SupabaseClient supabase,
  }) async {
    final pdf = await buildDocument(
      trial: trial,
      observations: observations,
      files: files,
      supabase: supabase,
    );
    final trialName = _trialName(trial);

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${trialName}_report.pdf',
    );
  }

  /// Like [generate], but several trials in one file.
  static Future<void> generateBatch({
    required List<TrialPdfBundle> trials,
    required SupabaseClient supabase,
  }) async {
    final pdf = await buildBatchDocument(trials: trials, supabase: supabase);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'trials_export.pdf');
  }

  /// Builds the document without printing or sharing it, so tests can call it.
  static Future<pw.Document> buildDocument({
    required Map<String, dynamic> trial,
    required List<Map<String, dynamic>> observations,
    required List<Map<String, dynamic>> files,
    required SupabaseClient supabase,
  }) async {
    final pdf = await _newDocument();
    await _addTrialSection(
      pdf,
      trial: trial,
      observations: observations,
      files: files,
      supabase: supabase,
    );
    return pdf;
  }

  /// One document for several trials, each with its own cover and section pages.
  static Future<pw.Document> buildBatchDocument({
    required List<TrialPdfBundle> trials,
    required SupabaseClient supabase,
  }) async {
    final pdf = await _newDocument();
    for (final bundle in trials) {
      await _addTrialSection(
        pdf,
        trial: bundle.trial,
        observations: bundle.observations,
        files: bundle.files,
        supabase: supabase,
      );
    }
    return pdf;
  }

  static String _trialName(Map<String, dynamic> trial) =>
      trial['fullname']?.toString().trim().isNotEmpty == true
      ? trial['fullname'].toString().trim()
      : 'Untitled Trial';

  static Future<pw.Document> _newDocument() async {
    // Montserrat is bundled because the default PDF font drops em-dashes,
    // arrows and some smart quotes.
    final baseFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Montserrat-Regular.ttf'));
    final boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Montserrat-Bold.ttf'));
    return pw.Document(
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
    );
  }

  // Adds one trial's cover and content pages to [pdf].
  static Future<void> _addTrialSection(
    pw.Document pdf, {
    required Map<String, dynamic> trial,
    required List<Map<String, dynamic>> observations,
    required List<Map<String, dynamic>> files,
    required SupabaseClient supabase,
  }) async {
    final status = trial['status_of_trial']?.toString() ?? '';
    final isPostTrial = status == 'Completed' || status == 'Failed';
    final outcomeColor = status == 'Completed' ? successGreen : failRed;
    final trialName = _trialName(trial);
    final drawings = files.where((f) => f['file_category'] == 'drawing').toList();
    final evidenceFiles = files.where((f) => f['file_category'] != 'drawing').toList();

    // Image previews for the file grids and cover photo. The bucket is private,
    // so download through the Supabase client; every file also gets a signed URL here.
    final Map<String, pw.MemoryImage?> imagePreviews = {};
    final Map<String, String?> fileLinks = {};
    for (final file in files) {
      final storagePath = file['storage_path']?.toString();
      if (storagePath == null || storagePath.isEmpty) continue;
      final ext = file['original_name']?.toString().split('.').last.toLowerCase();

      if (['jpg', 'jpeg', 'png'].contains(ext)) {
        try {
          final bytes = await supabase.storage.from('trial-files').download(storagePath);
          imagePreviews[storagePath] = pw.MemoryImage(bytes);
        } catch (e) {
          logError('Error downloading image for PDF export', e);
          imagePreviews[storagePath] = null;
        }
      }

      try {
        fileLinks[storagePath] = await supabase.storage
            .from('trial-files')
            .createSignedUrl(storagePath, _fileLinkValidity.inSeconds);
      } catch (e) {
        logError('Error creating signed URL for PDF export', e);
        fileLinks[storagePath] = null;
      }
    }
    pw.MemoryImage? heroImage;
    for (final file in [...evidenceFiles, ...drawings]) {
      final preview = imagePreviews[file['storage_path']?.toString() ?? ''];
      if (preview != null) {
        heroImage = preview;
        break;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) => coverPage(
          trialName: trialName,
          status: status,
          type: trial['type_of_trial']?.toString(),
          terminal: trial['terminal_of_trial']?.toString(),
          subArea: trial['sub_area_of_trial']?.toString(),
          startIso: trial['date_of_start']?.toString(),
          endIso: trial['date_of_completion']?.toString(),
          heroImage: heroImage,
        ),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          buildBackground: (context) => pw.Container(
            width: pageFormat.width,
            height: pageFormat.height,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [navy, midNavy],
              ),
            ),
          ),
        ),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(48, 22, 48, 0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PROVE IT',
                style: pdfText(10, bold: true, color: PdfColors.white, letterSpacing: 2),
              ),
              pw.Text(trialName, style: pdfText(9, color: mutedLight)),
            ],
          ),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(48, 0, 48, 22),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: pdfText(8, color: mutedLighter),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pdfText(8, color: mutedLighter),
              ),
            ],
          ),
        ),
        build: (context) => [
          sectionPage('TRIAL OVERVIEW', [
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                statusPill(status),
                for (final key in ['type_of_trial', 'terminal_of_trial', 'sub_area_of_trial'])
                  if (trial[key]?.toString().isNotEmpty == true) pdfTag(trial[key].toString()),
              ],
            ),
            pw.SizedBox(height: 20),
            pdfStatStrip(
              startIso: trial['date_of_start']?.toString(),
              endIso: trial['date_of_completion']?.toString(),
              fileCount: files.length,
              observationCount: observations.length,
            ),
          ]),

          pw.NewPage(),
          sectionPage('PRE-TRIAL DETAILS', [
            whiteCard(
              detailRows(trial, {
                'description_of_trial': 'Description',
                'expected_outcome': 'Expected Outcome',
                'run_plan': 'Run Plan',
              }, 'No pre-trial details recorded.'),
            ),
          ]),

          pw.NewPage(),
          sectionPage('ATTENDEES', [
            pdfAttendeesTable(parseAttendeeRows(trial['attendees']?.toString() ?? '')),
          ]),

          if (drawings.isNotEmpty) ...[
            pw.NewPage(),
            sectionPage('DRAWINGS (${drawings.length})', [
              fileGrid(drawings, fileLinks, imagePreviews),
            ]),
          ],

          if (isPostTrial) ...[
            pw.NewPage(),
            sectionPage('POST-TRIAL DETAILS', [
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: whiteDecoration(8, pw.Border.all(color: outcomeColor, width: 1.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Outcome - $status',
                      style: pdfText(14, bold: true, color: outcomeColor),
                    ),
                    pw.Divider(color: outcomeColor),
                    pw.SizedBox(height: 6),
                    ...detailRows(trial, {
                      'how_trial_went': 'How It Went',
                      'actual_outcome': 'Actual Outcome',
                      'evidence_summary': 'Evidence Summary',
                    }, 'No post-trial details recorded.'),
                  ],
                ),
              ),
            ]),
          ],

          if (isPostTrial && evidenceFiles.isNotEmpty) ...[
            pw.NewPage(),
            sectionPage('EVIDENCE FILES (${evidenceFiles.length})', [
              fileGrid(evidenceFiles, fileLinks, imagePreviews),
            ]),
          ],

          if (observations.isNotEmpty) ...[
            pw.NewPage(),
            sectionPage('OBSERVATIONS (${observations.length})', [
              pw.Column(
                children: observations
                    .map(
                      (obs) => pw.Container(
                        width: double.infinity,
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        padding: const pw.EdgeInsets.all(12),
                        decoration: whiteDecoration(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(obs['content']?.toString() ?? '', style: pdfText(11)),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              children: [
                                pw.Text(
                                  obs['username']?.toString() ?? 'Unknown',
                                  style: pdfText(10, bold: true, color: accentBlue),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  obs['created_at']?.toString().split('T')[0] ?? '',
                                  style: pdfText(10, color: textGrey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
