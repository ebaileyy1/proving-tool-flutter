import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';

/// One checklist item: storage field name and its label.
class EnablingItem {
  const EnablingItem(this.field, this.label);
  final String field;
  final String label;
}

const kEnablingProvingScripts = 'enabling_proving_scripts';
const kEnablingPermitsRequired = 'enabling_permits_required';
const kEnablingSafetyRequired = 'enabling_safety_required';
const kEnablingAccessRequired = 'enabling_access_required';

const kEnablingPermitItems = [
  EnablingItem('enabling_permit_atp', 'ATP'),
  EnablingItem('enabling_permit_las', 'LAS'),
  EnablingItem('enabling_permit_elr', 'ELR'),
  EnablingItem('enabling_permit_wan', 'WAN'),
  EnablingItem('enabling_permit_streetworks', 'Streetworks'),
];
const kEnablingSafetyItems = [
  EnablingItem('enabling_safety_ara', 'ARA'),
  EnablingItem('enabling_safety_risk_assessment', 'Task Based Risk Assessment'),
  EnablingItem('enabling_safety_rams', 'RAMS'),
  EnablingItem('enabling_safety_site_inspection', 'Site Safety Inspection'),
];
const kEnablingAccessItems = [
  EnablingItem('enabling_access_early_access', 'Early Access Required'),
  EnablingItem('enabling_access_boundaries_removed', 'Boundaries to be Removed'),
  EnablingItem('enabling_access_site_induction', 'Site Induction Required'),
];

/// Items in play: Proving Scripts always, the rest only when their category toggle is on.
List<EnablingItem> applicableEnablingItems({
  required bool permitsRequired,
  required bool safetyRequired,
  required bool accessRequired,
}) {
  return [
    const EnablingItem(kEnablingProvingScripts, 'Proving Scripts'),
    if (permitsRequired) ...kEnablingPermitItems,
    if (safetyRequired) ...kEnablingSafetyItems,
    if (accessRequired) ...kEnablingAccessItems,
  ];
}

/// An item counts as handled if it's ticked or has a reason recorded.
bool isEnablingItemSatisfied({
  required bool checked,
  required String field,
  required Map<String, String> reasons,
}) => checked || (reasons[field]?.trim().isNotEmpty ?? false);

/// Category label for a field, used in the activity log when only one Enabling
/// field changes.
String enablingActivityLabel(String field) {
  if (field == kEnablingProvingScripts) return 'updated Proving Scripts';
  if (field == kEnablingPermitsRequired || field.startsWith('enabling_permit_')) {
    return 'updated Permits';
  }
  if (field == kEnablingSafetyRequired || field.startsWith('enabling_safety_')) {
    return 'updated Safety';
  }
  if (field == kEnablingAccessRequired || field.startsWith('enabling_access_')) {
    return 'updated Site Access';
  }
  return 'updated the Enabling checklist';
}

/// Dialog for one item's "why not" reason. Returns the trimmed text, or null if cancelled.
Future<String?> editEnablingReason({
  required BuildContext context,
  required String label,
  required String initialValue,
}) async {
  final controller = TextEditingController(text: initialValue);
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reason: $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Why hasn't this been completed?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save Reason'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

/// Lists the outstanding Enabling items when a move to In Progress/Completed is
/// blocked, so the user can tick or explain them there. Edits go through the
/// callbacks; returns true once everything applicable is satisfied.
Future<bool> promptForMissingEnabling({
  required BuildContext context,
  required List<EnablingItem> missingItems,
  required bool Function(String field) isChecked,
  required void Function(String field, bool value) setChecked,
  required Map<String, String> reasons,
  required void Function(String field, String value) setReason,
}) async {
  bool isSatisfied(EnablingItem item) =>
      isEnablingItemSatisfied(checked: isChecked(item.field), field: item.field, reasons: reasons);

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final stillMissing = missingItems.where((item) => !isSatisfied(item)).toList();
        return AlertDialog(
          title: const Text('Enabling checklist incomplete'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tick off what's done, or give a reason for anything that isn't applicable this time.",
                  style: TextStyle(fontSize: 13, color: AppColors.otherText),
                ),
                const SizedBox(height: 12),
                ...missingItems.map((item) {
                  final checked = isChecked(item.field);
                  final reason = reasons[item.field] ?? '';
                  final satisfied = isSatisfied(item);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: checked,
                          onChanged: (v) {
                            setChecked(item.field, v ?? false);
                            setState(() {});
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.label, style: const TextStyle(fontSize: 13.5)),
                              if (!checked)
                                InkWell(
                                  onTap: () async {
                                    final result = await editEnablingReason(
                                      context: context,
                                      label: item.label,
                                      initialValue: reason,
                                    );
                                    if (result != null) {
                                      setReason(item.field, result);
                                      setState(() {});
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      reason.isEmpty ? 'Add reason' : 'Reason: $reason',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: reason.isEmpty
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                        color: satisfied ? AppColors.success : AppColors.accent,
                                        decoration: reason.isEmpty
                                            ? TextDecoration.underline
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (satisfied)
                          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                      ],
                    ),
                  );
                }),
                if (stillMissing.isEmpty)
                  const Text(
                    'Everything is either ticked or has a reason now.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        );
      },
    ),
  );

  return missingItems.every(isSatisfied);
}
