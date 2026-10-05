import 'package:flutter/material.dart';
import 'package:proving_tool/theme/app_colors.dart';
import 'package:proving_tool/utils/enabling_checklist.dart';

class EnablingStatusBanner extends StatelessWidget {
  const EnablingStatusBanner({super.key, required this.complete, required this.incompleteText});

  final bool complete;
  final String incompleteText;

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(complete ? Icons.check_circle : Icons.pending, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              complete
                  ? 'Proving Scripts is checked off - this trial can be started.'
                  : incompleteText,
              style: TextStyle(
                fontSize: 12.5,
                color: complete ? AppColors.success : AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _reasonStyle(String reason, Color emptyColor) => TextStyle(
  fontSize: 11.5,
  fontStyle: reason.isEmpty ? FontStyle.normal : FontStyle.italic,
  color: reason.isEmpty ? emptyColor : AppColors.success,
  decoration: reason.isEmpty ? TextDecoration.underline : null,
);

/// The Proving Scripts row plus the Permits/Safety/Site Access cards. The
/// category toggles are read through [isChecked]/[onToggle] by their
/// `enabling_*_required` field. A null [onToggle] makes every checkbox
/// read-only; a null [onEditReason] hides the reason links.
class EnablingChecklist extends StatelessWidget {
  const EnablingChecklist({
    super.key,
    required this.provingScriptsLabel,
    required this.isChecked,
    required this.reason,
    required this.onToggle,
    required this.onEditReason,
    this.titleColor,
  });

  final String provingScriptsLabel;
  final bool Function(String field) isChecked;
  final String Function(String field) reason;
  final void Function(String field, bool value)? onToggle;
  final void Function(String field, String value)? onEditReason;
  final Color? titleColor;

  ValueChanged<bool?>? _changed(String field) {
    final toggle = onToggle;
    return toggle == null ? null : (v) => toggle(field, v ?? false);
  }

  Future<void> _editReason(BuildContext context, String field, String label) async {
    final result = await editEnablingReason(
      context: context,
      label: label,
      initialValue: reason(field),
    );
    if (result != null) onEditReason!(field, result);
  }

  // [showReason] adds an "Add reason" link once unticked; only Proving Scripts uses it.
  Widget _itemRow(
    BuildContext context,
    EnablingItem item, {
    bool dense = true,
    bool showReason = false,
  }) {
    final checked = isChecked(item.field);
    final text = reason(item.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: checked,
          onChanged: _changed(item.field),
          dense: dense,
          contentPadding: dense ? const EdgeInsets.only(left: 32) : EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            item.label,
            style: TextStyle(
              fontSize: dense ? 13 : 14,
              fontWeight: dense ? FontWeight.normal : FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        if (showReason && !checked && onEditReason != null)
          Padding(
            padding: EdgeInsets.only(left: dense ? 56 : 32, bottom: 6),
            child: InkWell(
              onTap: () => _editReason(context, item.field, item.label),
              child: Text(
                text.isEmpty ? 'Add reason' : 'Reason: $text',
                style: _reasonStyle(text, AppColors.accent),
              ),
            ),
          ),
      ],
    );
  }

  // One reason for the whole category when nothing in it is ticked.
  Widget _categoryReasonRow(BuildContext context, String categoryField, String categoryTitle) {
    final text = reason(categoryField);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 4, 8, 8),
      child: InkWell(
        onTap: () => _editReason(context, categoryField, 'No $categoryTitle ticked'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.help_outline, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text.isEmpty
                    ? "Nothing ticked in $categoryTitle yet - why?"
                    : 'Why nothing is ticked: $text',
                style: _reasonStyle(text, AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(
    BuildContext context, {
    required String requiredField,
    required String title,
    required String subtitle,
    required List<EnablingItem> items,
  }) {
    final applies = isChecked(requiredField);
    final anyChecked = items.any((item) => isChecked(item.field));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: applies ? AppColors.subBackground : Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: applies,
            onChanged: _changed(requiredField),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.navy,
              ),
            ),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          ),
          if (applies) ...[
            const Divider(height: 1, color: AppColors.border),
            for (final item in items) _itemRow(context, item),
            if (!anyChecked && onEditReason != null)
              _categoryReasonRow(context, requiredField, title),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _itemRow(
          context,
          EnablingItem(kEnablingProvingScripts, provingScriptsLabel),
          dense: false,
          showReason: true,
        ),
        const SizedBox(height: 4),
        _categoryCard(
          context,
          requiredField: kEnablingPermitsRequired,
          title: 'Permits',
          subtitle: 'Does this trial need permits?',
          items: kEnablingPermitItems,
        ),
        _categoryCard(
          context,
          requiredField: kEnablingSafetyRequired,
          title: 'Safety',
          subtitle: 'Does this trial need safety sign-off?',
          items: kEnablingSafetyItems,
        ),
        _categoryCard(
          context,
          requiredField: kEnablingAccessRequired,
          title: 'Site Access Requirements',
          subtitle: 'Does this trial have site access requirements?',
          items: kEnablingAccessItems,
        ),
      ],
    );
  }
}
