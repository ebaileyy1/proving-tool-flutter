import 'package:flutter/material.dart';
import 'package:proving_tool/models/attendee.dart';
import 'package:proving_tool/services/app_services.dart';
import 'package:proving_tool/utils/enabling_checklist.dart';

const kTrialTypes = [
  'Desktop',
  'Dimensional',
  'First of Type',
  'Unit Trial',
  'Basic Trial',
  'Advanced Trial',
  'Live Rehearsal',
];
const kTrialTerminals = ['T1', 'T2', 'T3', 'T4', 'T5'];
const kTrialStatuses = ['Pending', 'In Progress', 'Completed', 'Failed'];

/// Trials starting on each day, for the badges in the date picker.
Map<DateTime, int> tripCountsByDay(BuildContext context) {
  final trials = AppServices.of(context).trialRepository.trials.value;
  final counts = <DateTime, int>{};
  for (final item in trials) {
    final date = DateTime.tryParse(item.data['date_of_start']?.toString() ?? '');
    if (date == null) continue;
    final key = DateTime(date.year, date.month, date.day);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

// enabling_notes is jsonb; the column is missing on a trial that never synced.
Map<String, String> _parseEnablingReasons(dynamic raw) {
  if (raw is! Map) return {};
  return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
}

/// Form state shared by Add and Edit; builds the field map TrialRepository expects.
class TrialFormController {
  TrialFormController({
    String fullname = '',
    String description = '',
    String expectedOutcome = '',
    String runPlan = '',
    String howTrialWent = '',
    String actualOutcome = '',
    String evidenceSummary = '',
    String subArea = '',
    List<Attendee>? attendees,
    this.type = 'Desktop',
    this.terminal = 'T1',
    this.status = 'Pending',
    DateTime? startDate,
    this.endDate,
    this.provingScripts = false,
    this.permitsRequired = false,
    this.permitAtp = false,
    this.permitLas = false,
    this.permitElr = false,
    this.permitWan = false,
    this.permitStreetworks = false,
    this.safetyRequired = false,
    this.safetyAra = false,
    this.safetyRiskAssessment = false,
    this.safetyRams = false,
    this.safetySiteInspection = false,
    this.accessRequired = false,
    this.accessEarlyAccess = false,
    this.accessBoundariesRemoved = false,
    this.accessSiteInduction = false,
    Map<String, String>? enablingReasons,
  }) : enablingReasons = enablingReasons ?? {},
       fullname = TextEditingController(text: fullname),
       description = TextEditingController(text: description),
       expectedOutcome = TextEditingController(text: expectedOutcome),
       runPlan = TextEditingController(text: runPlan),
       howTrialWent = TextEditingController(text: howTrialWent),
       actualOutcome = TextEditingController(text: actualOutcome),
       evidenceSummary = TextEditingController(text: evidenceSummary),
       subArea = TextEditingController(text: subArea),
       attendees = attendees ?? [Attendee()],
       startDate = startDate ?? DateTime.now();

  /// Pre-fills from a trial's field map (Edit, and Add's Duplicate flow).
  factory TrialFormController.fromExisting(
    Map<String, dynamic> trial, {
    bool resetForDuplicate = false,
  }) {
    final type = trial['type_of_trial']?.toString();
    final terminal = trial['terminal_of_trial']?.toString();
    final status = trial['status_of_trial']?.toString();
    return TrialFormController(
      fullname: trial['fullname']?.toString() ?? '',
      description: trial['description_of_trial']?.toString() ?? '',
      expectedOutcome: trial['expected_outcome']?.toString() ?? '',
      runPlan: trial['run_plan']?.toString() ?? '',
      howTrialWent: resetForDuplicate ? '' : trial['how_trial_went']?.toString() ?? '',
      actualOutcome: resetForDuplicate ? '' : trial['actual_outcome']?.toString() ?? '',
      evidenceSummary: resetForDuplicate ? '' : trial['evidence_summary']?.toString() ?? '',
      attendees: parseAttendeesText(trial['attendees']?.toString() ?? ''),
      subArea: trial['sub_area_of_trial']?.toString() ?? '',
      type: kTrialTypes.contains(type) ? type! : kTrialTypes.first,
      terminal: kTrialTerminals.contains(terminal) ? terminal! : kTrialTerminals.first,
      status: resetForDuplicate
          ? kTrialStatuses.first
          : (kTrialStatuses.contains(status) ? status! : kTrialStatuses.first),
      startDate: resetForDuplicate
          ? null
          : DateTime.tryParse(trial['date_of_start']?.toString() ?? ''),
      endDate: resetForDuplicate
          ? null
          : DateTime.tryParse(trial['date_of_completion']?.toString() ?? ''),
      // A duplicate starts with the enabling checklist cleared.
      provingScripts: !resetForDuplicate && trial['enabling_proving_scripts'] == true,
      permitsRequired: !resetForDuplicate && trial['enabling_permits_required'] == true,
      permitAtp: !resetForDuplicate && trial['enabling_permit_atp'] == true,
      permitLas: !resetForDuplicate && trial['enabling_permit_las'] == true,
      permitElr: !resetForDuplicate && trial['enabling_permit_elr'] == true,
      permitWan: !resetForDuplicate && trial['enabling_permit_wan'] == true,
      permitStreetworks: !resetForDuplicate && trial['enabling_permit_streetworks'] == true,
      safetyRequired: !resetForDuplicate && trial['enabling_safety_required'] == true,
      safetyAra: !resetForDuplicate && trial['enabling_safety_ara'] == true,
      safetyRiskAssessment: !resetForDuplicate && trial['enabling_safety_risk_assessment'] == true,
      safetyRams: !resetForDuplicate && trial['enabling_safety_rams'] == true,
      safetySiteInspection: !resetForDuplicate && trial['enabling_safety_site_inspection'] == true,
      accessRequired: !resetForDuplicate && trial['enabling_access_required'] == true,
      accessEarlyAccess: !resetForDuplicate && trial['enabling_access_early_access'] == true,
      accessBoundariesRemoved:
          !resetForDuplicate && trial['enabling_access_boundaries_removed'] == true,
      accessSiteInduction: !resetForDuplicate && trial['enabling_access_site_induction'] == true,
      enablingReasons: resetForDuplicate ? null : _parseEnablingReasons(trial['enabling_notes']),
    );
  }

  final TextEditingController fullname;
  final TextEditingController description;
  final TextEditingController expectedOutcome;
  final TextEditingController runPlan;
  final TextEditingController howTrialWent;
  final TextEditingController actualOutcome;
  final TextEditingController evidenceSummary;
  final TextEditingController subArea;
  final List<Attendee> attendees;
  String type;
  String terminal;
  String status;
  DateTime startDate;
  DateTime? endDate;

  // Each *_required flag is a category toggle; its sub-items only count while it's on.
  bool provingScripts;
  bool permitsRequired;
  bool permitAtp;
  bool permitLas;
  bool permitElr;
  bool permitWan;
  bool permitStreetworks;
  bool safetyRequired;
  bool safetyAra;
  bool safetyRiskAssessment;
  bool safetyRams;
  bool safetySiteInspection;
  bool accessRequired;
  bool accessEarlyAccess;
  bool accessBoundariesRemoved;
  bool accessSiteInduction;

  /// "Why not" reasons for unticked enabling items, keyed by field name.
  /// A recorded reason counts as handled.
  final Map<String, String> enablingReasons;

  bool get isPostTrial => status == 'Completed' || status == 'Failed';

  Map<String, bool> get enablingFlags => {
    kEnablingProvingScripts: provingScripts,
    'enabling_permit_atp': permitAtp,
    'enabling_permit_las': permitLas,
    'enabling_permit_elr': permitElr,
    'enabling_permit_wan': permitWan,
    'enabling_permit_streetworks': permitStreetworks,
    'enabling_safety_ara': safetyAra,
    'enabling_safety_risk_assessment': safetyRiskAssessment,
    'enabling_safety_rams': safetyRams,
    'enabling_safety_site_inspection': safetySiteInspection,
    'enabling_access_early_access': accessEarlyAccess,
    'enabling_access_boundaries_removed': accessBoundariesRemoved,
    'enabling_access_site_induction': accessSiteInduction,
  };

  /// What's still missing before the trial can move to In Progress/Completed.
  /// Only Proving Scripts gates that; the other enabling items are tracking only.
  List<EnablingItem> get missingEnablingItems {
    if (isEnablingItemSatisfied(
      checked: provingScripts,
      field: kEnablingProvingScripts,
      reasons: enablingReasons,
    )) {
      return const [];
    }
    return const [EnablingItem(kEnablingProvingScripts, 'Proving Scripts')];
  }

  /// True once Proving Scripts is checked or has a reason.
  bool get isEnablingComplete => missingEnablingItems.isEmpty;

  /// Sets or clears one enabling field by name, for the missing-items dialog.
  void setEnablingChecked(String field, bool value) {
    switch (field) {
      case kEnablingProvingScripts:
        provingScripts = value;
      case 'enabling_permit_atp':
        permitAtp = value;
      case 'enabling_permit_las':
        permitLas = value;
      case 'enabling_permit_elr':
        permitElr = value;
      case 'enabling_permit_wan':
        permitWan = value;
      case 'enabling_permit_streetworks':
        permitStreetworks = value;
      case 'enabling_safety_ara':
        safetyAra = value;
      case 'enabling_safety_risk_assessment':
        safetyRiskAssessment = value;
      case 'enabling_safety_rams':
        safetyRams = value;
      case 'enabling_safety_site_inspection':
        safetySiteInspection = value;
      case 'enabling_access_early_access':
        accessEarlyAccess = value;
      case 'enabling_access_boundaries_removed':
        accessBoundariesRemoved = value;
      case 'enabling_access_site_induction':
        accessSiteInduction = value;
    }
  }

  String get attendeesText => attendees.where((a) => !a.isEmpty).map((a) => a.toText()).join('\n');

  /// Field map for createTrial/updateTrial. The caller adds posted_by on create.
  Map<String, dynamic> buildFieldsMap() {
    return {
      'fullname': fullname.text.trim(),
      'description_of_trial': description.text.trim(),
      'expected_outcome': expectedOutcome.text.trim(),
      'run_plan': runPlan.text.trim(),
      'attendees': attendeesText,
      'how_trial_went': isPostTrial ? howTrialWent.text.trim() : null,
      'actual_outcome': isPostTrial ? actualOutcome.text.trim() : null,
      'evidence_summary': isPostTrial ? evidenceSummary.text.trim() : null,
      'date_of_start': startDate.toIso8601String(),
      'type_of_trial': type,
      'terminal_of_trial': terminal,
      'sub_area_of_trial': subArea.text.trim(),
      'status_of_trial': status,
      'date_of_completion': endDate?.toIso8601String(),
      'enabling_proving_scripts': provingScripts,
      'enabling_permits_required': permitsRequired,
      'enabling_permit_atp': permitAtp,
      'enabling_permit_las': permitLas,
      'enabling_permit_elr': permitElr,
      'enabling_permit_wan': permitWan,
      'enabling_permit_streetworks': permitStreetworks,
      'enabling_safety_required': safetyRequired,
      'enabling_safety_ara': safetyAra,
      'enabling_safety_risk_assessment': safetyRiskAssessment,
      'enabling_safety_rams': safetyRams,
      'enabling_safety_site_inspection': safetySiteInspection,
      'enabling_access_required': accessRequired,
      'enabling_access_early_access': accessEarlyAccess,
      'enabling_access_boundaries_removed': accessBoundariesRemoved,
      'enabling_access_site_induction': accessSiteInduction,
      'enabling_notes': enablingReasons,
    };
  }

  void dispose() {
    fullname.dispose();
    subArea.dispose();
    description.dispose();
    expectedOutcome.dispose();
    runPlan.dispose();
    howTrialWent.dispose();
    actualOutcome.dispose();
    evidenceSummary.dispose();
    for (final a in attendees) {
      a.dispose();
    }
  }
}
