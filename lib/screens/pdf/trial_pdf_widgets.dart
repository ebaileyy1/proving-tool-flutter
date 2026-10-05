import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:proving_tool/models/attendee.dart';
import 'package:proving_tool/screens/pdf/trial_pdf_style.dart';
import 'package:proving_tool/utils/dates.dart';

PdfColor _statusColor(String s) => switch (s) {
  'Completed' => successGreen,
  'Failed' => failRed,
  'In Progress' => lightNavy,
  'Pending' => warningOrange,
  _ => textGrey,
};

pw.Widget coverPage({
  required String trialName,
  required String status,
  required String? type,
  required String? terminal,
  required String? subArea,
  required String? startIso,
  required String? endIso,
  pw.MemoryImage? heroImage,
}) {
  return pw.Stack(
    children: [
      pw.Positioned.fill(
        child: heroImage != null
            ? pw.Container(
                decoration: pw.BoxDecoration(
                  image: pw.DecorationImage(image: heroImage, fit: pw.BoxFit.cover),
                ),
              )
            : pw.Container(
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                    colors: [navy, midNavy, lightNavy],
                  ),
                ),
              ),
      ),
      // Flat scrim via pw.Opacity; a gradient fade would need alpha colours.
      if (heroImage != null)
        pw.Positioned.fill(
          child: pw.Opacity(
            opacity: 0.6,
            child: pw.Container(width: pageFormat.width, height: pageFormat.height, color: navy),
          ),
        ),
      pw.Positioned(
        left: 56,
        top: 44,
        child: pw.Text(
          'PROVE IT',
          style: pdfText(13, bold: true, color: PdfColors.white, letterSpacing: 3),
        ),
      ),
      pw.Positioned(
        left: 56,
        right: 56,
        bottom: 52,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(trialName, style: pdfText(32, bold: true, color: PdfColors.white)),
            pw.SizedBox(height: 14),
            pw.Row(
              children: [
                statusPill(status),
                for (final tag in [type, terminal, subArea])
                  if (tag != null && tag.isNotEmpty) ...[pw.SizedBox(width: 8), pdfTag(tag)],
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(_formatDateRange(startIso, endIso), style: pdfText(12, color: mutedLight)),
          ],
        ),
      ),
    ],
  );
}

pw.Widget sectionPage(String title, List<pw.Widget> children) {
  return pw.Padding(
    padding: pagePadding.copyWith(top: 18, bottom: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pdfText(22, bold: true, color: PdfColors.white)),
        pw.SizedBox(height: 6),
        pw.Container(width: 56, height: 3, color: accentBlue),
        pw.SizedBox(height: 20),
        ...children,
      ],
    ),
  );
}

pw.Widget whiteCard(List<pw.Widget> children) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    decoration: whiteDecoration(),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
  );
}

pw.Widget _pill(String label, PdfColor background, PdfColor foreground) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: pw.BoxDecoration(color: background, borderRadius: pw.BorderRadius.circular(10)),
    child: pw.Text(label, style: pdfText(10, bold: true, color: foreground)),
  );
}

pw.Widget statusPill(String status) =>
    _pill(status.isEmpty ? 'Unknown' : status, PdfColors.white, _statusColor(status));

// Solid fill, not translucent white (see [mutedLight]).
pw.Widget pdfTag(String label) => _pill(label, lightNavy, PdfColors.white);

pw.Widget pdfStatStrip({
  required String? startIso,
  required String? endIso,
  required int fileCount,
  required int observationCount,
}) {
  final start = DateTime.tryParse(startIso ?? '');
  final end = DateTime.tryParse(endIso ?? '');
  final duration = (start != null && end != null && !end.isBefore(start))
      ? end.difference(start).inDays + 1
      : null;

  final stats = <(String, String)>[
    ('Start', _formatPdfDate(startIso)),
    ('End', _formatPdfDate(endIso)),
    ('Duration', duration == null ? '-' : '$duration day${duration == 1 ? '' : 's'}'),
    ('Files', fileCount.toString()),
    ('Observations', observationCount.toString()),
  ];

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 18),
    decoration: whiteDecoration(),
    child: pw.Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) pw.Container(width: 1, height: 34, color: borderGrey),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text(
                  stats[i].$2,
                  style: pdfText(15, bold: true, color: navy),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  stats[i].$1,
                  style: pdfText(9, color: textGrey),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

String _formatPdfDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  final date = DateTime.tryParse(iso);
  if (date == null) return '-';
  return '${date.day} ${monthNames[date.month - 1].substring(0, 3)} ${date.year}';
}

String _formatDateRange(String? startIso, String? endIso) {
  final start = DateTime.tryParse(startIso ?? '');
  final end = DateTime.tryParse(endIso ?? '');
  if (start == null) return '';
  if (end == null || isSameDay(start, end)) return _formatPdfDate(startIso);
  return '${_formatPdfDate(startIso)} - ${_formatPdfDate(endIso)}';
}

// Reuses the form's parser, then reads the text and drops the controllers.
List<({String name, String company})> parseAttendeeRows(String raw) {
  if (raw.isEmpty) return [];
  final rows = <({String name, String company})>[];
  for (final attendee in parseAttendeesText(raw)) {
    final name = [
      attendee.firstName.text,
      attendee.lastName.text,
    ].where((s) => s.isNotEmpty).join(' ');
    final company = attendee.company.text;
    attendee.dispose();
    if (name.isNotEmpty || company.isNotEmpty) {
      rows.add((name: name, company: company));
    }
  }
  return rows;
}

pw.Widget pdfAttendeesTable(List<({String name, String company})> rows) {
  if (rows.isEmpty) {
    return whiteCard([pw.Text('No attendees recorded.', style: pw.TextStyle(color: textGrey))]);
  }
  pw.Widget cell(String text, {bool header = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    child: pw.Text(text, style: header ? pdfText(11, bold: true, color: navy) : pdfText(11)),
  );
  return pw.Container(
    decoration: whiteDecoration(),
    child: pw.ClipRRect(
      horizontalRadius: 8,
      verticalRadius: 8,
      child: pw.Table(
        columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: lightGrey),
            children: [cell('Name', header: true), cell('Company', header: true)],
          ),
          for (final row in rows)
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: borderGrey, width: 0.75)),
              ),
              children: [
                cell(row.name.isEmpty ? '-' : row.name),
                cell(row.company.isEmpty ? '-' : row.company),
              ],
            ),
        ],
      ),
    ),
  );
}

pw.Widget fileGrid(
  List<Map<String, dynamic>> files,
  Map<String, String?> fileLinks,
  Map<String, pw.MemoryImage?> imagePreviews,
) {
  return pw.Wrap(
    spacing: 14,
    runSpacing: 14,
    children: files
        .map((file) => pw.SizedBox(width: 232, child: _fileWidget(file, fileLinks, imagePreviews)))
        .toList(),
  );
}

pw.Widget _fileWidget(
  Map<String, dynamic> file,
  Map<String, String?> fileLinks,
  Map<String, pw.MemoryImage?> imagePreviews,
) {
  final ext = file['original_name']?.toString().split('.').last.toLowerCase() ?? '';
  final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
  final isPdf = ext == 'pdf';
  final isVideo = ['mp4', 'mov'].contains(ext);
  final storagePath = file['storage_path']?.toString() ?? '';
  final fileUrl = fileLinks[storagePath];
  final preview = imagePreviews[storagePath];
  pw.Widget note(String text) => pw.Text(text, style: pdfText(9, color: textGrey));

  return pw.Container(
    decoration: whiteDecoration(),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                  style: pdfText(8, bold: true, color: PdfColors.white),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Text(
                  file['original_name']?.toString() ?? '-',
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                  style: pdfText(9.5, bold: true),
                ),
              ),
            ],
          ),
        ),

        if (isImage && preview != null)
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Center(
              child: pw.ConstrainedBox(
                constraints: const pw.BoxConstraints(maxHeight: 130),
                child: pw.Image(preview),
              ),
            ),
          ),

        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (isImage && preview == null) note('Preview unavailable'),
              if (isPdf) note('PDF document'),
              if (isVideo) note('Video file'),
              if (['doc', 'docx'].contains(ext)) note('Word document'),
              if (['ppt', 'pptx'].contains(ext)) note('Presentation'),
              pw.SizedBox(height: 3),
              if (fileUrl != null)
                pw.UrlLink(
                  destination: fileUrl,
                  child: pw.Text(
                    'Open file ->',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: accentBlue,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                )
              else
                note('Link unavailable'),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget detailRow(String label, dynamic value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pdfText(10, bold: true, color: textGrey)),
        pw.SizedBox(height: 2),
        pw.Text(value?.toString() ?? '-', style: pdfText(11.5)),
      ],
    ),
  );
}

/// A [detailRow] per non-empty field, or [emptyText] when all are blank.
List<pw.Widget> detailRows(
  Map<String, dynamic> trial,
  Map<String, String> labelsByKey,
  String emptyText,
) {
  final rows = [
    for (final entry in labelsByKey.entries)
      if (trial[entry.key]?.toString().isNotEmpty == true) detailRow(entry.value, trial[entry.key]),
  ];
  return rows.isEmpty ? [pw.Text(emptyText, style: pw.TextStyle(color: textGrey))] : rows;
}
