import 'package:flutter/material.dart';
import 'package:proving_tool/screens/analytics/analytics_screen.dart';
import 'package:proving_tool/screens/calendar/calendar_screen.dart';
import 'package:proving_tool/widgets/app_header.dart';

AppHeader buildDashboardAppBar(
  BuildContext context, {
  required bool isExportingPdfs,
  required VoidCallback onRefresh,
  required VoidCallback onExportCsv,
  required VoidCallback onExportPdfs,
}) {
  return AppHeader(
    title: 'Dashboard',
    actions: [
      HeaderIconButton(
        icon: const Icon(Icons.calendar_month),
        tooltip: 'Calendar',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
        },
      ),
      HeaderIconButton(
        icon: const Icon(Icons.insights),
        tooltip: 'Analytics',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
        },
      ),
      HeaderIconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: onRefresh),
      HeaderIconButton(
        icon: const Icon(Icons.file_download),
        tooltip: 'Export filtered trials as CSV',
        onPressed: onExportCsv,
      ),
      HeaderIconButton(
        icon: isExportingPdfs
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.picture_as_pdf),
        tooltip: 'Export filtered trials as one combined PDF',
        onPressed: isExportingPdfs ? null : onExportPdfs,
      ),
    ],
  );
}
