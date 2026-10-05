import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const navy = PdfColor.fromInt(0xFF111C5B);
const midNavy = PdfColor.fromInt(0xFF243F74);
const lightNavy = PdfColor.fromInt(0xFF3A6790);
const accentBlue = PdfColor.fromInt(0xFF5090AD);
const lightGrey = PdfColor.fromInt(0xFFF4F6F9);
const borderGrey = PdfColor.fromInt(0xFFDCE3EA);
const textGrey = PdfColor.fromInt(0xFF7F8C8D);
const successGreen = PdfColor.fromInt(0xFF16A34A);
const failRed = PdfColor.fromInt(0xFFDC2626);
const warningOrange = PdfColor.fromInt(0xFFD97706);
// The pdf package ignores alpha on fills, gradients and borders, so these are
// solid stand-ins for translucent white. Only pw.Opacity gives real transparency.
const mutedLight = PdfColor.fromInt(0xFFB9C3E8);
const mutedLighter = PdfColor.fromInt(0xFF8791C0);
final pageFormat = PdfPageFormat.a4.landscape;
const pagePadding = pw.EdgeInsets.fromLTRB(48, 0, 48, 0);

pw.TextStyle pdfText(double size, {PdfColor? color, bool bold = false, double? letterSpacing}) =>
    pw.TextStyle(
      fontSize: size,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : null,
      letterSpacing: letterSpacing,
    );

pw.BoxDecoration whiteDecoration([double radius = 8, pw.Border? border]) => pw.BoxDecoration(
  color: PdfColors.white,
  borderRadius: pw.BorderRadius.circular(radius),
  border: border,
);
