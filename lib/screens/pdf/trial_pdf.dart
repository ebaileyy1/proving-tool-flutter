import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:proving_tool/models/attendee.dart';

class TrialPdf {
  static Future<void> generate({
    required Map<String, dynamic> trial,
    required List<Map<String, dynamic>> observations,
    required List<Map<String, dynamic>> files,
    required String supabaseUrl,
  }) async {
    final pdf = pw.Document();

    const navy = PdfColor.fromInt(0xFF111C5B);
    const lightGrey = PdfColor.fromInt(0xFFF4F6F9);
    const borderGrey = PdfColor.fromInt(0xFFDCE3EA);
    const textGrey = PdfColor.fromInt(0xFF7F8C8D);
    const accentBlue = PdfColor.fromInt(0xFF5090AD);
    const successGreen = PdfColor.fromInt(0xFF16A34A);
    const failRed = PdfColor.fromInt(0xFFDC2626);

    final status = trial['status_of_trial']?.toString() ?? '';
    final isPostTrial = status == 'Completed' || status == 'Failed';
    final drawings = files.where((f) => f['file_category'] == 'drawing').toList();
    final evidenceFiles = files.where((f) => f['file_category'] != 'drawing').toList();

    // Load image previews
    final Map<String, pw.MemoryImage?> imagePreviews = {};
    for (final file in files) {
      final ext = file['original_name']?.toString().split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(ext)) {
        try {
          final url = '$supabaseUrl/storage/v1/object/public/trial-files/${file['storage_path']}';
          final imageBytes = await networkImage(url);
          imagePreviews[file['storage_path']] = imageBytes as pw.MemoryImage?;
        } catch (e) {
          imagePreviews[file['storage_path']] = null;
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: borderGrey)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PROVE IT',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: navy),
              ),
              pw.Text('Trial Report', style: pw.TextStyle(fontSize: 12, color: textGrey)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: borderGrey)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 9, color: textGrey),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: textGrey),
              ),
            ],
          ),
        ),
        build: (context) => [

          // Title banner
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: navy,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  trial['fullname']?.toString() ?? 'Untitled Trial',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Status: $status',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey300),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Trial Information
          _pdfSectionHeader('Trial Information', navy, borderGrey),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGrey,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderGrey),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _detailRow('Type', trial['type_of_trial'], navy, textGrey)),
                    pw.Expanded(child: _detailRow('Terminal', trial['terminal_of_trial'], navy, textGrey)),
                    pw.Expanded(child: _detailRow('Status', trial['status_of_trial'], navy, textGrey)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(child: _detailRow('Start Date', trial['date_of_start']?.toString().split('T')[0], navy, textGrey)),
                    pw.Expanded(child: _detailRow('End Date', trial['date_of_completion']?.toString().split('T')[0], navy, textGrey)),
                    pw.Expanded(child: pw.SizedBox()),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Pre-Trial Details
          _pdfSectionHeader('Pre-Trial Details', navy, borderGrey),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGrey,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: borderGrey),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (trial['description_of_trial'] != null && trial['description_of_trial'].toString().isNotEmpty)
                  _detailRow('Description', trial['description_of_trial'], navy, textGrey),
                if (trial['expected_outcome'] != null && trial['expected_outcome'].toString().isNotEmpty)
                  _detailRow('Expected Outcome', trial['expected_outcome'], navy, textGrey),
                if (trial['run_plan'] != null && trial['run_plan'].toString().isNotEmpty)
                  _detailRow('Run Plan', trial['run_plan'], navy, textGrey),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Attendees
          _pdfSectionHeader('Attendees', navy, borderGrey),
          pw.SizedBox(height: 8),
          if (trial['attendees'] == null || trial['attendees'].toString().isEmpty)
            pw.Text('No attendees recorded.', style: pw.TextStyle(color: textGrey))
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: formatAttendeesForDisplay(trial['attendees'].toString()).split('\n').where((a) => a.isNotEmpty).map((attendee) =>
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderGrey),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(attendee, style: pw.TextStyle(fontSize: 11)),
                ),
              ).toList(),
            ),

          pw.SizedBox(height: 20),

          // Drawings
          _pdfSectionHeader('Drawings (${drawings.length})', navy, borderGrey),
          pw.SizedBox(height: 8),
          if (drawings.isEmpty)
            pw.Text('No drawings uploaded.', style: pw.TextStyle(color: textGrey))
          else
            pw.Column(
              children: drawings.map((file) => _fileWidget(file, supabaseUrl, imagePreviews, lightGrey, borderGrey, textGrey, accentBlue)).toList(),
            ),

          // Post-Trial Details (only if Completed or Failed)
          if (isPostTrial) ...[
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: status == 'Completed' ? successGreen : failRed,
                  width: 1.5,
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Post-Trial Details — $status',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: status == 'Completed' ? successGreen : failRed,
                    ),
                  ),
                  pw.Divider(color: status == 'Completed' ? successGreen : failRed),
                  pw.SizedBox(height: 8),
                  if (trial['how_trial_went'] != null && trial['how_trial_went'].toString().isNotEmpty)
                    _detailRow('How It Went', trial['how_trial_went'], navy, textGrey),
                  if (trial['actual_outcome'] != null && trial['actual_outcome'].toString().isNotEmpty)
                    _detailRow('Actual Outcome', trial['actual_outcome'], navy, textGrey),
                  if (trial['evidence_summary'] != null && trial['evidence_summary'].toString().isNotEmpty)
                    _detailRow('Evidence Summary', trial['evidence_summary'], navy, textGrey),
                  if ((trial['how_trial_went'] == null || trial['how_trial_went'].toString().isEmpty) &&
                      (trial['actual_outcome'] == null || trial['actual_outcome'].toString().isEmpty) &&
                      (trial['evidence_summary'] == null || trial['evidence_summary'].toString().isEmpty))
                    pw.Text('No post-trial details recorded.', style: pw.TextStyle(color: textGrey)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Evidence Files
            _pdfSectionHeader('Evidence Files (${evidenceFiles.length})', navy, borderGrey),
            pw.SizedBox(height: 8),
            if (evidenceFiles.isEmpty)
              pw.Text('No evidence files uploaded.', style: pw.TextStyle(color: textGrey))
            else
              pw.Column(
                children: evidenceFiles.map((file) => _fileWidget(file, supabaseUrl, imagePreviews, lightGrey, borderGrey, textGrey, accentBlue)).toList(),
              ),
          ],

          pw.SizedBox(height: 20),

          // Observations
          _pdfSectionHeader('Observations (${observations.length})', navy, borderGrey),
          pw.SizedBox(height: 8),
          if (observations.isEmpty)
            pw.Text('No observations recorded.', style: pw.TextStyle(color: textGrey))
          else
            pw.Column(
              children: observations.map((obs) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      obs['content']?.toString() ?? '',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Text(
                          obs['username']?.toString() ?? 'Unknown',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: accentBlue,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          obs['created_at']?.toString().split('T')[0] ?? '',
                          style: pw.TextStyle(fontSize: 10, color: textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${trial['fullname']?.toString() ?? 'trial'}_report.pdf',
    );
  }

  static pw.Widget _pdfSectionHeader(String title, PdfColor navy, PdfColor borderGrey) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: navy),
        ),
        pw.Divider(color: borderGrey),
      ],
    );
  }

  static pw.Widget _fileWidget(
    Map<String, dynamic> file,
    String supabaseUrl,
    Map<String, pw.MemoryImage?> imagePreviews,
    PdfColor lightGrey,
    PdfColor borderGrey,
    PdfColor textGrey,
    PdfColor accentBlue,
  ) {
    final ext = file['original_name']?.toString().split('.').last.toLowerCase() ?? '';
    final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
    final isPdf = ext == 'pdf';
    final isVideo = ['mp4', 'mov'].contains(ext);
    final isDoc = ['doc', 'docx'].contains(ext);
    final isPpt = ['ppt', 'pptx'].contains(ext);
    final storagePath = file['storage_path']?.toString() ?? '';
    final fileUrl = '$supabaseUrl/storage/v1/object/public/trial-files/$storagePath';
    final preview = imagePreviews[storagePath];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGrey),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // File header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: lightGrey,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: isImage
                        ? const PdfColor.fromInt(0xFF26A69A)
                        : isPdf
                            ? const PdfColor.fromInt(0xFFEF5350)
                            : isVideo
                                ? const PdfColor.fromInt(0xFF5C6BC0)
                                : const PdfColor.fromInt(0xFF4A6FA5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    ext.toUpperCase(),
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    file['original_name']?.toString() ?? '-',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Text(
                  'Uploaded: ${file['uploaded_at']?.toString().split('T')[0] ?? '-'}',
                  style: pw.TextStyle(fontSize: 9, color: textGrey),
                ),
              ],
            ),
          ),

          // Image preview
          if (isImage && preview != null)
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Center(
                child: pw.ConstrainedBox(
                  constraints: const pw.BoxConstraints(maxHeight: 200),
                  child: pw.Image(preview),
                ),
              ),
            ),

          // Link
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (isImage && preview == null)
                  pw.Text('Image preview unavailable', style: pw.TextStyle(fontSize: 10, color: textGrey)),
                if (isPdf)
                  pw.Text('PDF document — open link to view full content', style: pw.TextStyle(fontSize: 10, color: textGrey)),
                if (isVideo)
                  pw.Text('Video file — open link to play', style: pw.TextStyle(fontSize: 10, color: textGrey)),
                if (isDoc)
                  pw.Text('Word document — open link to view full content', style: pw.TextStyle(fontSize: 10, color: textGrey)),
                if (isPpt)
                  pw.Text('Presentation — open link to view full content', style: pw.TextStyle(fontSize: 10, color: textGrey)),
                pw.SizedBox(height: 4),
                pw.UrlLink(
                  destination: fileUrl,
                  child: pw.Text(
                    'Open file →',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: accentBlue,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(
    String label,
    dynamic value,
    PdfColor navy,
    PdfColor textGrey,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textGrey),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value?.toString() ?? '-',
              style: pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}